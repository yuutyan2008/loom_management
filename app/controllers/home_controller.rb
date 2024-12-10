class HomeController < ApplicationController
  before_action :require_login, only: [:index]

  def index
    @company = current_user.company
    if @company.orders.exists?
      @orders = @company.orders.includes(:work_processes)
      check_overdue_work_processes_index(@orders)
      @machine_assignments = MachineAssignment.includes(:work_process).where(work_processes: { work_process_definition_id: [1, 2, 3, 4, 5] })
    else
      @orders = []
      @no_orders_message = "現在受注している商品はありません"
      @machine_assignments = []
    end
  end

  def update
    ActiveRecord::Base.transaction do
      # 条件1: work_process_difinition_idが1〜3の作業工程を「作業完了」に更新
      work_processes_to_complete = WorkProcess.where(work_process_difinition_id: [1, 2, 3], work_process_status_id: [1, 2]) # ステータス1,2が未完了と仮定
      work_processes_to_complete.update_all(work_process_status_id: 3)

      # 織機の状態を「稼働中」に更新
      MachineAssignment.where(work_process: work_processes_to_complete).update_all(machine_status_id: 3)

      # 条件2: 「製織」（work_process_difinition_id:4）の作業完了後の処理
      work_process_definition_4 = WorkProcessDefinition.find_by(id: 4)
      raise ActiveRecord::RecordNotFound, "製織の作業工程が見つかりません。" unless work_process_definition_4

      completed_manufacture_processes = WorkProcess.where(work_process_difinition_id: 4, work_process_status_id: [1, 2])
      completed_manufacture_processes.update_all(work_process_status_id: 3)

      # 織機の割当てを解除
      MachineAssignment.where(work_process: completed_manufacture_processes).update_all(machine_id: nil)

      # 「整理加工」（work_process_difinition_id:5）を「作業中」に更新
      WorkProcess.where(work_process_difinition_id: 5, order_id: completed_manufacture_processes.pluck(:order_id))
                 .update_all(work_process_status_id: 2)
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
