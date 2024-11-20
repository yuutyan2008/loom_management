class User::OrdersController < ApplicationController
  include ApplicationHelper
  before_action :set_order, only: [ :show, :edit, :update, :destroy ]

  def index
    @orders = Order.all
  end

  def show
    @work_processes = @order.work_processes.includes(:work_process_definition, machine_assignments: :machine)
    @current_work_process = find_current_work_process(@order.work_processes)

    if @current_work_process
      @current_machine_assignments = @current_work_process.machine_assignments.includes(:machine)
      @machines = @current_machine_assignments.map(&:machine).uniq
    else
      @current_machine_assignments = []
      @machines = []
    end
  end

  def new
    @order = Order.new
    @order.work_processes.build
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      redirect_to user_order_path(@order), status: :unprocessable_entity, notice: "受注が正常に作成されました。"
    else
      render :new
    end
  end

  def edit
    @order.work_processes.build if @order.work_processes.empty?
  end

  def update
    ActiveRecord::Base.transaction do
      if @order.update(order_params)
        update_related_models
        redirect_to user_order_path(@order), status: :unprocessable_entity, notice: "受注情報が更新されました。"
      else
        render :edit
      end
    end
  rescue ActiveRecord::UnknownAttributeError => e
    render :edit, alert: "更新中にエラーが発生しました: #{e.message}"
  end

  def destroy
    @order.destroy
    redirect_to user_orders_path, status: :see_other, notice: "受注が削除されました。"
  end

  private

  def set_order
    @order = Order.find(params[:id])
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
