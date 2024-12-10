class Admin::OrdersController < ApplicationController
  # 定義された関数の使用
  include ApplicationHelper
before_action :order_params, only: [:update]
before_action :create_order_params, only: [:create]

before_action :set_order, only: [:edit, :show, :update, :destroy]
# before_action :work_process_params, only: [:create, :update]
before_action :admin_user

  def index
    @orders = Order.includes(work_processes: [:work_process_definition, :work_process_status, process_estimate: :machine_type])
                   .order(id: "DESC")

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
    @work_process = WorkProcess.new
    @companies = Company.where.not(id: 1)
  end

  def create
    # orderテーブル以外を除外してorderインスタンス作成
    # マージしてOrderに保存
    # start_date = params[:work_process][:start_date]
    # @order = Order.new(order_params.merge(start_date: start_date))
    # @order = Order.new(order_params)

    @order = Order.new(create_order_params.except(:work_processes))

    # work_processesのパラメータ取得
    # ハッシュの値部分のみを配列として取得
    work_processes = create_order_params[:work_processes]
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
      workprocess = WorkProcess.initial_processes_list(start_date)
      # インスタンスの更新
      # process_estimate_idを入れる
      estimate_workprocess = WorkProcess.decide_machine_type(workprocess, machine_type_id)
      # インスタンスの更新
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
    @machines = @work_process.map(&:machines).flatten.uniq
    # @work_process = @order.work_processes.joins(:work_process_definition)
    # .order("work_process_definitions.sequence ASC")
    # # 織機データを取得
    # @machines = Machine.joins(work_processes: :order)
    #                    .where(work_processes: { order_id: @order.id })
    #                    .distinct
    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_show(@order.work_processes)
  end

  def edit
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
    end
    @work_processes = @order.work_processes.ordered

    @machines = @work_processes.map(&:machines).flatten.uniq
  end

  def update
    order_work_processes = order_params.except(:machine_status_id)

    # 完了日の取得
    # workprocesses = order_work_processes[:work_processes_attributes].values
    # workprocesses.each_with_index do |workprocess, index|
    #   # 見込み完了日、作業開始日更新
    #   start_date = workprocess["start_date"]
    #   actual_completion_date = workprocess["actual_completion_date"]
    #   # binding.irb

    #   # 次の工程を取得
    #   next_process = workprocesses[index + 1]

    #   if actual_completion_date.present?

    #     # 開始日、見込み完了日置き換え、
    #     updated_date = WorkProcess.check_current_work_process(workprocess, start_date, actual_completion_date, index, next_process)
    #     binding.irb
    #     if next_process.present?
    #       next_start_date = WorkProcess.determine_next_start_date(next_process)
    #       next_process["start_date"] = next_start_date
    #       # binding.irb

    #     end
    #     workprocess["start_date"] = updated_date
    #     workprocess["latest_estimated_completion_date"] = updated_date
    #     # binding.irb
    #   end

    # end

    # binding.irb
    @order.update(order_params.except(:machine_status_id))
    machine_status_id = order_params[:machine_status_id]
    target_machine_assignments = MachineAssignment.where(work_process_id: @order.work_processes.pluck(:id))
    target_machine_assignments.update_all(machine_status_id: machine_status_id)

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
        process_estimate: [:machine_type_id],
        machine_assignments: [:id, :machine_status_id]
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
      :machine_status_id,
      work_processes_attributes: [ # accepts_nested_attributes_forに対応
        :id,
        :process_estimate_id,
        :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        :latest_estimated_completion_date,
        :actual_completion_date,
        :start_date,
        process_estimate: [:machine_type_id],
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
