class Admin::OrdersController < ApplicationController
  # 定義された関数の使用
  include ApplicationHelper
before_action :order_params, only: [ :update ]
before_action :create_order_params, only: [ :create ]

before_action :set_order, only: [ :edit, :show, :update, :destroy ]
# before_action :work_process_params, only: [:create, :update]
before_action :admin_user

  def index
    @orders = Order.includes(work_processes: [ :work_process_definition, :work_process_status, process_estimate: :machine_type ])
                   .incomplete
                   .order(:id)
    @no_orders_message = "現在受注している商品はありません" unless @orders.any?
    # 各注文に対して現在作業中の作業工程を取得
    @current_work_processes = {}
    @orders.each do |order|
      if order.work_processes.any?
        if params[:work_process_definitions_id]
          is_match = order.work_processes.current_work_process.work_process_definition_id == params[:work_process_definitions_id].to_i
          @current_work_processes[order.id] = is_match ? order.work_processes.current_work_process : nil
        else
          @current_work_processes[order.id] = order.work_processes.current_work_process
        end
      else
        @current_work_processes[order.id] = nil
      end

    end
    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_index(@orders)

    # 検索の実行（スコープを適用）

    @orders =
    @orders
      .search_by_company(params[:company_id])
      .search_by_product_number(params[:product_number_id])
      .search_by_color_number(params[:color_number_id])
  end

  def past_orders
    @orders = Order.includes(work_processes: [ :work_process_definition, :work_process_status, process_estimate: :machine_type ])
                   .completed
    @no_past_orders_message = "過去の受注はありません" unless @orders.any?
    # 現在の作業工程を取得（完了済みのため基本的にnilになる可能性が高い）
    @current_work_processes = {}
    @orders.each do |order|
      if order.work_processes.any?
        @current_work_processes[order.id] = order.work_processes.current_work_process
      else
        @current_work_processes[order.id] = nil
      end
    end
    # 遅延している作業工程のチェック（必要に応じて）
    check_overdue_work_processes_index(@orders)
  end
  # end

  def new
    @order = Order.new
    @work_process = WorkProcess.new
    @companies = Company.where.not(id: 1)
  end

  def create
    # orderテーブル以外を除外してorderインスタンス作成
    @order = Order.new(create_order_params.except(:work_processes))
    # work_processesのパラメータ取得
    # ハッシュの値部分のみを配列として取得
    work_processes = create_order_params[:work_processes]
    # ハッシュのキー"start_date"を引数にパラメータを取得
    start_date = work_processes["start_date"]
    machine_type_id = work_processes["process_estimate"]["machine_type_id"].to_i

    # 5個のwork_processハッシュからなる配列を作成
    workprocess = WorkProcess.initial_processes_list(start_date)
    # process_estimate_idを入れる
    estimate_workprocess = WorkProcess.decide_machine_type(workprocess, machine_type_id)
    # 完了見込日時を入れる
    update_workprocess = WorkProcess.update_deadline(estimate_workprocess, start_date)
    # ５個のハッシュとorderの関連付け
    update_workprocess.each do |work_process_data|
      @order.work_processes.build(work_process_data)
    end
    @order.save
    redirect_to admin_orders_path, notice: "注文が作成されました"
  end

  def show
    @work_process = @order.work_processes.ordered
    @machines = @work_process.map { |work_process| work_process.machines}.flatten.uniq
    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_show(@order.work_processes)
  end

  def edit
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
    end
    # orderedスコープで並び替えて取得
    @work_processes = @order.work_processes.ordered

    @work_processes.map { |work_process| work_process.machines }.flatten.uniq



  end

  def update
    ActiveRecord::Base.transaction do
      order_work_processes = order_params.except(:machine_assignments_attributes)

      # 完了日の取得
      workprocesses = order_work_processes[:work_processes_attributes].values

      next_start_date = nil

      workprocesses.each_with_index do |workprocess, index|
        # 追記
        work_process_record = WorkProcess.find(workprocess["id"])

        if index == 0
          start_date = workprocess["start_date"]
        else
          start_date = next_start_date
        end

        # 見込み完了日、作業開始日更新
        actual_completion_date = workprocess["actual_completion_date"]

        # 開始日、見込み完了日置き換え
        updated_date, next_start_date = WorkProcess.check_current_work_process(workprocess, start_date, actual_completion_date)

        # 更新された値を反映
        work_process_record.update!(updated_date)

      end
      # MachineAssignmentの更新
      machine_assignments_params = order_params[:machine_assignments_attributes]
      machine_id = machine_assignments_params[0][:machine_id].to_i
      machine_status_id = machine_assignments_params[0][:machine_status_id].to_i
        # フォームで送られた ID に基づき MachineAssignment を取得
      machine_ids = @order.work_processes.joins(:machine_assignments).pluck('machine_assignments.machine_id').uniq
      if machine_ids.any?
        @order.machine_assignments.each do |assignment|
          assignment.update!(
            machine_id: machine_id,
            machine_status_id: machine_status_id
          )
        end
      else
        # 存在しない場合は新規作成し、@order に関連付ける
        @order.work_processes.each do |work_process|
          work_process.machine_assignments.create!(
            machine_id: machine_id,
            machine_status_id: machine_status_id
          )
        end
      end

      # Orderの更新
      update_order = order_params.except(:machine_assignments_attributes, :work_processes_attributes)
      if update_order.present?
        @order.update!(update_order)
      end
    end
    redirect_to admin_order_path(@order), notice: "更新されました。"

  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    # トランザクション内でエラーが発生した場合はロールバックされる
    flash[:alert] = "更新に失敗しました: #{e.message}"
    render :edit
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

  def create_order_params
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
        process_estimate: [ :machine_type_id ],
        machine_assignments: [ :id, :machine_status_id ]
      ]
    )
  end

  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      process_estimate: [ :machine_type_id ],
      machine_assignments_attributes: [:id, :machine_id, :machine_status_id],
      work_processes_attributes: [ # accepts_nested_attributes_forに対応
        :id,
        :process_estimate_id,
        :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        :earliest_estimated_completion_date,
        :latest_estimated_completion_date,
        :actual_completion_date,
        :start_date,

      ]
    )
  end

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
    completed_status = WorkProcessStatus.find_by(name: "\u4F5C\u696D\u5B8C\u4E86")
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
    completed_status = WorkProcessStatus.find_by(name: "\u4F5C\u696D\u5B8C\u4E86")
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

  def set_work_process
    @work_process = Task.find(params[:id])
  end

  def set_product_number
    @product_number = current_user.product_number
  end

end
