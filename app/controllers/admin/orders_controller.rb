class Admin::OrdersController < ApplicationController
before_action :order_params, only: [:create,  :update]
before_action :set_order, only: [:edit, :show, :update, :destroy]
# before_action :work_process_params, only: [:create, :update]
before_action :admin_user

  def index
    @orders = Order.includes(work_processes: [:work_process_definition, :work_process_status, process_estimate: :machine_type])

    # 各注文に対して現在作業中の作業工程を取得
    @current_work_processes = {}
    @orders.each do |order|
      if order.work_processes.any?
        @current_work_processes[order.id] = order.work_processes.current_work_process
      else
        @current_work_processes[order.id] = nil
      end
    end

    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_index(@orders)
  end

  def new
    @order = Order.new
  end

  def create
    # orderテーブル以外を除外してorderインスタンス作成
    # マージしてOrderに保存
    # start_date = params[:work_process][:start_date]
    # @order = Order.new(order_params.merge(start_date: start_date))
    # @order = Order.new(order_params)

    @order = Order.new(order_params.except(:work_processes))

    # work_processesのパラメータ取得
    # ハッシュの値部分のみを配列として取得
    work_processes = order_params[:work_processes].values.first

    # ハッシュのキー"start_date"を引数にパラメータを取得
    start_date = work_processes["start_date"]
    machine_type_id = work_processes["process_estimate"]["machine_type_id"].to_i

    # # earliest_estimated_completion_dateの値を定義
    # # earliest_estimated_completion_date = start_date + "日数を返す関数"

    # # 5個のwork_processインスタンスを作成
    # workprocesses = WorkProcess.initial_processes_list(start_date)

    # # インスタンスの更新
    # # process_estimate_idを入れる

    # # インスタンスの更新
    # # 完了見込日時を入れる
    # updated_workprocesses = WorkProcess.update_deadline(workprocesses, machine_type_id, start_date)
    # # 関連付け
    # @order.work_processes.build(updated_workprocesses)
    # # binding.irb
    # @order.save

    # redirect_to admin_orders_path, notice: "注文が作成されました"
      # 5個のwork_processハッシュからなる配列を作成
      workprocesses = WorkProcess.initial_processes_list(start_date)
      # インスタンスの更新
      # process_estimate_idを入れる
      estimate_workprocesses = WorkProcess.decide_machine_type(workprocesses, machine_type_id)
      # インスタンスの更新
      # 完了見込日時を入れる
      update_workprocesses = WorkProcess.update_deadline(estimate_workprocesses, start_date)
      # ５個のハッシュとorderの関連付け
      update_workprocesses.each do |work_process_data|
        @order.work_processes.build(work_process_data)
      end
      @order.save
      redirect_to admin_orders_path, notice: "注文が作成されました"
  end

  def show
    @work_process = @order.work_processes.joins(:work_process_definition)
    .order("work_process_definitions.sequence ASC")
    # 織機データを取得
    @machines = Machine.joins(work_processes: :order)
                       .where(work_processes: { order_id: @order.id })
                       .distinct
    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_show(@order.work_processes)
  end

  def edit
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
      raise "注文が見つかりません"
    end
    @work_processes = @order.work_processes.joins(:work_process_definition).order("work_process_definitions.sequence ASC")
  end

  def update
    @order.update(order_params.except(:work_processes))
    # strongparameterで許可されたフォームのname属性値を取得
    work_processes_params = order_params[:work_processes].values
    work_processes_params.each do |work_process_params|
      binding.irb
    # フォームから取得したIDでDBからデータ取得
      work_process = WorkProcess.find(work_process_params[:id])
    binding.irb

      # machine_assignments の処理
      if work_process_params[:machine_assignments].present?
        work_process_params[:machine_assignments].each do |assignment_params|
          assignment = work_process.machine_assignments.find(assignment_params[:id])
          unless assignment.update(machine_status_id: assignment_params[:machine_status_id])
            flash[:alert] = "機械割り当ての更新に失敗しました"
            redirect_to edit_admin_order_path(@order) and return
          end
        end
        # machine_assignmentsを削除して残りのWorkProcess属性を更新
        work_process_params.delete(:machine_assignments)
        binding.irb
      end

      # WorkProcessの更新
      unless work_process.update(work_process_params.except(:machine_assignments))
        flash[:alert] = "作業工程の更新に失敗しました"
        binding.irb
        redirect_to edit_admin_order_path(@order) and return
      end
    end

    # 更新後に並び替えを行う
    @work_processes = @work_processes.joins(:work_process_definition)
    .order("work_process_definitions.sequence ASC")

    redirect_to admin_order_path(@order), notice: "作業工程が更新されました。"
  end

  # 削除処理の開始し管理者削除を防ぐロジックはmodelで行う
  def destroy
    if @order.destroy
      # ココ(削除実行直前)でmodelに定義したコールバックが呼ばれる

      flash[:notice] = "発注が削除されました"
    else
      # バリデーションに失敗で@order.errors.full_messagesにエラーメッセージが配列として追加されます
      # .join(", "): 配列内の全てのエラーメッセージをカンマ区切り（, ）で連結
      flash[:alert] = @order.errors.full_messages.join(", ")
    end
    redirect_to admin_orders_path
  end

  private

  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      work_processes: [
        :id,
        :process_estimate_id,
        :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        :actual_completion_date,
        :start_date,
        process_estimate: [:machine_type_id],
        machine_assignments: [:id, :machine_status_id]
      ]
    )
  end


  # def update_work_processes
  #   # パラメータから work_processes を取得
  #   work_processes_params = params[:work_processes] || {}

  #   work_processes_params.each do |id, attributes|
  #     work_process = WorkProcess.find(id)

  #     # 子モデルを更新
  #     work_process.update(
  #       status_id: attributes[:status_id],
  #       start_date: attributes[:start_date]
  #     )
  #   end
  # end

  def set_order
    @order = Order.find(params[:id])
  end

  # 一般ユーザがアクセスした場合には一覧画面にリダイレクト
  def admin_user
    unless current_user&.admin?
      redirect_to orders_path, alert: "管理者以外アクセスできません"
    end
  end

  # 追加: indexアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_index(orders)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status

    # 対象となるWorkProcessを取得（Orderとの関連を事前に読み込み）
    overdue_work_processes = WorkProcess.includes(:order, :work_process_definition)
                                        .where(order_id: orders.ids)
                                        .where("earliest_estimated_completion_date < ?", Date.today)
                                        .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      # Orderごとにグループ化
      grouped = overdue_work_processes.group_by(&:order)
      # 件数の取得
      total_overdue_orders = grouped.keys.size

      # メッセージリストを作成
      message = grouped.map do |order, work_processes|
        # 受注IDと会社名を表示し、リンクを生成
        link_text = "受注 ID:#{order.id} 会社名:#{order.company.name}"
        link = view_context.link_to link_text, admin_order_path(order), class: "underline"
        "<li>#{link}</li>"
      end.join("<br>").html_safe

      # フラッシュメッセージにリンクを含めて設定
      flash.now[:alert] = <<-HTML.html_safe
        <strong>予定納期が過ぎている受注が #{total_overdue_orders} 件あります。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          #{message}
        </ul>
      HTML
    end
  end

  # 追加: showアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_show(work_processes)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status

    # 遅延しているWorkProcessを取得
    overdue_work_processes = work_processes.where("earliest_estimated_completion_date < ?", Date.today)
                                           .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      # 同一Orderなのでグループ化は不要
      wp_links = overdue_work_processes.each_with_index.map do |wp, index|
        if index == 0
          # 最初のWorkProcessには受注IDを含める
          order = wp.order
          "受注 ID:#{order.id} 作業工程: #{wp.work_process_definition.name}"
        else
          # 以降のWorkProcessは受注IDを含めずに作業工程のみ
          "作業工程: #{wp.work_process_definition.name}"
        end
      end.join(", ")

      # リンクを生成
      link = view_context.link_to wp_links, admin_order_path(overdue_work_processes.first.order), class: "underline"

      # フラッシュメッセージをHTMLとして生成
      flash.now[:alert] = <<-HTML.html_safe
        <strong>以下の作業工程が予定完了日を過ぎており、まだ完了していません。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          <li>#{link}</li>
        </ul>
      HTML
    end
  end
end
