class OrdersController < ApplicationController
  include ApplicationHelper
  before_action :require_login
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :authorize_order, only: [:show, :destroy]

  def index
    @company = current_user&.company
    @orders = @company&.orders&.incomplete || Order.none
    @no_orders_message = "現在受注している商品はありません" unless @orders.any?

    check_overdue_work_processes_index(@orders)
  end

  def past_orders
    @company = current_user&.company
    @orders = @company&.orders&.completed || Order.none
    @no_past_orders_message = "過去の受注はありません" unless @orders.any?

    check_overdue_work_processes_index(@orders) # 必要に応じて修正
  end

  def show
    @work_processes = @order.work_processes
                            .includes(:work_process_definition, machine_assignments: :machine)
                            .ordered
    @current_work_process = find_current_work_process(@work_processes)
    load_machine_assignments_and_machines

    check_overdue_work_processes_show(@order.work_processes)
  end

  def new
    @order = current_user.company.orders.build
    @order.work_processes.build
  end

  def create
    @order = current_user.company.orders.build(order_params)
    if @order.save
      redirect_to order_path(@order), notice: "受注が正常に作成されました。"
    else
      render :new
    end
  end

  def edit
    build_missing_machine_assignments
  end

  def update
    ActiveRecord::Base.transaction do
      if @order.update(order_params)
        update_related_models
        create_new_machine_assignments if params[:order][:new_machine_assignments].present?
        redirect_to @order, notice: '受注が正常に更新されました。'
      else
        render :edit
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "更新に失敗しました: #{e.message}"
    render :edit
  end

  def destroy
    @order.destroy
    redirect_to orders_path, notice: "受注が削除されました。"
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: "指定された受注は存在しません。"
  end

  def authorize_order
    redirect_to orders_path, alert: "アクセス権限がありません。" unless @order.company == current_user.company
  end

  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      :start_date
    )
  end

  def build_missing_machine_assignments
    @order.work_processes.each do |wp|
      wp.machine_assignments.build if wp.machine_assignments.empty?
    end
  end

  def load_machine_assignments_and_machines
    @current_machine_assignments = @current_work_process&.machine_assignments&.includes(:machine) || []
    @machines = @current_machine_assignments.map(&:machine).uniq
  end

  def update_related_models
    update_work_processes if params[:order][:work_processes].present?
    update_machine_assignments if params[:order][:machine_assignments].present?
    update_machine_statuses if params[:order][:machine_statuses].present?
  end

  def update_work_processes
    params[:order][:work_processes].each do |wp_param|
      wp = @order.work_processes.find(wp_param[:id])
      wp.update!(
        start_date: wp_param[:start_date],
        factory_estimated_completion_date: wp_param[:factory_estimated_completion_date],
        actual_completion_date: wp_param[:actual_completion_date],
        work_process_status_id: wp_param[:work_process_status_id]
      )
    end
  end

  def update_machine_assignments
    params[:order][:machine_assignments].each do |ma_param|
      ma = MachineAssignment.find(ma_param[:id])
      ma.update!(machine_status_id: ma_param[:machine_status_id])
    end
  end

  def update_machine_statuses
    params[:order][:machine_statuses].each do |ms_param|
      machine_id = ms_param[:machine_id]
      new_status_id = ms_param[:machine_status_id]

      # 関連するMachineAssignmentを取得
      assignments = MachineAssignment.where(machine_id: machine_id)

      assignments.each do |assignment|
        assignment.update!(machine_status_id: new_status_id)
      end
    end
  end

  def create_new_machine_assignments
    params[:order][:new_machine_assignments].each do |ma_param|
      machine_id = ma_param[:machine_id]
      machine_status_id = ma_param[:machine_status_id]
      work_process_id = ma_param[:work_process_id]
      # 各WorkProcessに対してMachineAssignmentを作成
      MachineAssignment.create!(
        machine_id: machine_id,
        machine_status_id: machine_status_id,
        work_process_id: work_process_id
      )
    end
  end

  ## 追加: indexアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_index(orders)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status
    # 対象となるWorkProcessを取得（Orderとの関連を事前に読み込み）
    overdue_work_processes = WorkProcess.includes(:order, :work_process_definition)
                                        .where(order_id: orders&.ids)
                                        .where("earliest_estimated_completion_date < ?", Date.today)
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
        link = view_context.link_to wp_links, order_path(order), class: "underline"
        "<li>#{link}</li>"
      end.join("<br>").html_safe

      # フラッシュメッセージをHTMLとして生成
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
      message = overdue_work_processes.each_with_index.map do |wp, index|
        if index == 0
          # 最初のWorkProcessには受注IDを含める
          "受注 ID:#{@order.id} 作業工程: #{wp.work_process_definition.name}"
        else
          # 以降のWorkProcessは受注IDを含めずに作業工程のみ
          "作業工程: #{wp.work_process_definition.name}"
        end
      end.join(", ")

      # フラッシュメッセージをHTMLとして生成
      flash.now[:alert] = <<-HTML.html_safe
        <strong>以下の作業工程が予定完了日を過ぎており、まだ完了していません。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          <li>#{message}</li>
        </ul>
      HTML
    end
  end
end
