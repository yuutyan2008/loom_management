class HomeController < ApplicationController
  before_action :require_login, only: [:index, :update]

  def index
    @company = current_user&.company
    # 会社に紐づく全Machineを取得し、関連情報をプリロード
    @machines = @company&.machines&.machine_associations
    if @company&.orders.exists?
      @orders = @company&.orders.includes(:work_processes)
      check_overdue_work_processes_index(@orders)
      # machine_id: 2のMachineAssignmentを想定例として取得
      # 実際には複数のMachineAssignmentを取得し、配列で表示する場合
      # @machine_assignments = MachineAssignment.includes(machine: { company: {} }, work_process: :work_process_definition)
      #                                         .where(machine: { company_id: @company.id }) # 条件は実際の要件に合わせる
      #                                         .order(created_at: :desc)
      # 複数のmachine_idに対応する場合はwhere(machine_id: [リスト])など
      # @machine_assignments = all_assignments.group_by(&:machine_id).map { |_, assignments| assignments.first }
    else
      @orders = []
      @no_orders_message = "現在受注している商品はありません"
    end
  end

  def update
    @company = current_user&.company
    machine_id = params[:machine_id]
    order_id = params[:order_id] # machine.latest_work_processから取得したorder_id
    @machine = @company&.machines.find(machine_id)
    @order = @company&.orders.find(order_id)

    ActiveRecord::Base.transaction do
      if params[:commit] == "作業開始"
        # 作業開始処理
        # 指定のWorkProcessを更新
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3])
                   .update_all(work_process_status_id: 3) # 完了
        WorkProcess.where(order_id: order_id, work_process_definition_id: 4)
                   .update_all(work_process_status_id: 2) # 作業中に更新
        # MachineAssignmentを稼働中に更新
        MachineAssignment.where(machine_id: machine_id, machine_status_id: [1,2,4]) # 未稼働{1}, 準備中{2}, 故障中{4}
                         .update_all(machine_status_id: 3) # 稼働中
      elsif params[:commit] == "作業終了"
        # 作業終了処理
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3,4])
                   .update_all(work_process_status_id: 3) # 完了
        WorkProcess.where(order_id: order_id, work_process_definition_id: 5)
                   .update_all(work_process_status_id: 2) # 作業中に更新
        # MachineAssignmentの織機をnilに更新
        MachineAssignment.where(machine_id: machine_id, work_process_id: @order.work_processes)
                         .update_all(machine_id: nil)
        # 新規MachineAssignment追加
        MachineAssignment.create!(machine_id: machine_id, machine_status_id: 1, work_process_id: nil)
      end
    end
    redirect_to root_path, notice: "ステータスが正常に更新されました。"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: "ステータスの更新に失敗しました: #{e.message}"
  end

  private

  # 追加: indexアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_index(orders)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status

    # 対象となるWorkProcessを取得（Orderとの関連を事前に読み込み）
    overdue_work_processes = WorkProcess.includes(:order, :work_process_definition)
                                        .where(order_id: orders.ids)
                                        .where("factory_estimated_completion_date < ?", Date.today)
                                        .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      # Orderごとにグループ化
      grouped = overdue_work_processes.group_by(&:order)
      # 件数の取得
      total_overdue_orders = grouped.keys.size

      # メッセージリストを作成
      message = grouped.map do |order, work_processes|
        wp_links = work_processes.each_with_index.map do |wp, index|
          if index == 0
            # 最初のWorkProcessには受注IDを含める
            "受注 ID:#{order.id} 作業工程: #{wp.work_process_definition.name}"
          else
            # 以降のWorkProcessは受注IDを含めずに作業工程のみ
            "作業工程: #{wp.work_process_definition.name}"
          end
        end.join(", ")

        # 受注IDごとにリンクを生成
        view_context.link_to wp_links, order_path(order), class: "underline"
      end.join("<br>").html_safe

      # フラッシュメッセージにリンクを含めて設定
      flash.now[:alert] = <<-HTML.html_safe
        <strong>予定納期が過ぎている受注が #{total_overdue_orders} 件あります。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          <li>#{message}</li>
        </ul>
      HTML
    end
  end
end
