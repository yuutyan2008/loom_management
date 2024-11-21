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
    @company = current_user.company
    unless @order.company == @company
      redirect_to orders_path, alert: "アクセス権限がありません。"
    else
      @order.work_processes.build if @order.work_processes.empty?
    end
  end

  def update
    @company = current_user.company
    if @order.company == @company
      ActiveRecord::Base.transaction do
        if @order.update(order_params)
          update_related_models
          redirect_to order_path(@order), notice: "受注情報が更新されました。"
        else
          render :edit
        end
      end
    else
      redirect_to orders_path, alert: "アクセス権限がありません。"
    end
  rescue ActiveRecord::UnknownAttributeError => e
    render :edit, alert: "更新中にエラーが発生しました: #{e.message}"
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
end
