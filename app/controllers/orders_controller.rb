class OrdersController < ApplicationController
  include ApplicationHelper
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :require_login

  def index
    @company = current_user.company
    if @company.orders.exists?
      @orders = @company.orders
    else
      @orders = []
      @no_orders_message = "現在受注している商品はありません"
    end
  end

  def show
    @company = current_user.company
    if @order.company == @company
      @work_processes = @order.work_processes.includes(:work_process_definition, machine_assignments: :machine)
      @current_work_process = find_current_work_process(@order.work_processes)

      if @current_work_process
        @current_machine_assignments = @current_work_process.machine_assignments.includes(:machine)
        @machines = @current_machine_assignments.map(&:machine).uniq
      else
        @current_machine_assignments = []
        @machines = []
      end
    else
      redirect_to orders_path, alert: "アクセス権限がありません。"
    end
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
    # 既存の work_processes と machines がロードされていることを確認
    @order.work_processes.each do |wp|
      wp.machine_assignments.build if wp.machine_assignments.empty?
    end
  end

  def update
    ActiveRecord::Base.transaction do
      if @order.update(order_params)
        update_work_processes
        update_machine_assignments
        update_machine_statuses
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
    @company = current_user.company
    if @order.company == @company
      @order.destroy
      redirect_to orders_path, notice: "受注が削除されました。"
    else
      redirect_to orders_path, alert: "アクセス権限がありません。"
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: "指定された受注は存在しません。"
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

  def update_related_models
    # work_process_definition_id と work_process_status_id を更新
    if params[:order][:work_process_definition_id].present? || params[:order][:work_process_status_id].present?
      work_process = @order.work_processes.first
      work_process.update(
        work_process_definition_id: params[:order][:work_process_definition_id],
        work_process_status_id: params[:order][:work_process_status_id]
      ) if work_process
    end

    # machine_id と machine_status_id を更新
    if params[:order][:machine_id].present? || params[:order][:machine_status_id].present?
      machine_assignment = @order.machine_assignments.first
      machine_assignment.update(
        machine_id: params[:order][:machine_id],
        machine_status_id: params[:order][:machine_status_id]
      ) if machine_assignment
    end
  end

  def update_work_processes
    if params[:work_processes]
      params[:work_processes].each do |wp_param|
        wp = @order.work_processes.find(wp_param[:id])
        wp.update!(
          start_date: wp_param[:start_date],
          factory_estimated_completion_date: wp_param[:factory_estimated_completion_date],
          work_process_status_id: wp_param[:work_process_status_id]
        )
      end
    end
  end

  def update_machine_assignments
    if params[:machine_assignments]
      params[:machine_assignments].each do |ma_param|
        ma = MachineAssignment.find(ma_param[:id])
        ma.update!(
          machine_status_id: ma_param[:machine_status_id]
        )
      end
    end
  end

  # 織機の稼働状況を一括更新するメソッドの追加
  def update_machine_statuses
    if params[:machine_statuses]
      params[:machine_statuses].each do |ms_param|
        machine_id = ms_param[:machine_id]
        new_status_id = ms_param[:machine_status_id]

        # 同じ machine_id を持つ全ての MachineAssignment を更新
        MachineAssignment.where(machine_id: machine_id, work_process: @order.work_processes).update_all(machine_status_id: new_status_id)
      end
    end
  end
end
