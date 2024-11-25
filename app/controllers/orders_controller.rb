class OrdersController < ApplicationController
  include ApplicationHelper
  before_action :require_login
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :authorize_order, only: [:show, :destroy]

  def index
    @company = current_user.company
    @orders = @company.orders.exists? ? @company.orders : []
    @no_orders_message = "現在受注している商品はありません" unless @orders.any?
  end

  def show
    @work_processes = @order.work_processes
                            .includes(:work_process_definition, machine_assignments: :machine)
                            .ordered
    @current_work_process = find_current_work_process(@work_processes)
    load_machine_assignments_and_machines
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
        create_new_machine_assignments if params[:new_machine_assignments].present?
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
      :start_date,
      work_processes_attributes: [
        :id,
        :start_date,
        :factory_estimated_completion_date,
        :actual_completion_date,
        :work_process_status_id,
        :machine_id
      ],
      machine_assignments_attributes: [
        :id,
        :machine_status_id
      ]
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
    update_work_processes if params[:work_processes].present?
    update_machine_assignments if params[:machine_assignments].present?
    update_machine_statuses if params[:machine_statuses].present?
  end

  def update_work_processes
    params[:work_processes].each do |wp_param|
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
    params[:machine_assignments].each do |ma_param|
      ma = MachineAssignment.find(ma_param[:id])
      ma.update!(machine_status_id: ma_param[:machine_status_id])
    end
  end

  def update_machine_statuses
    params[:machine_statuses].each do |ms_param|
      MachineAssignment
        .where(machine_id: ms_param[:machine_id], work_process: @order.work_processes)
        .update_all(machine_status_id: ms_param[:machine_status_id])
    end
  end

  def create_new_machine_assignments
    params[:new_machine_assignments].each do |ma_param|
      work_process_ids = determine_work_process_ids_for_new_assignment
      work_process_ids.each do |wp_id|
        # 各作業工程に対して MachineAssignment を作成
        MachineAssignment.create!(
          machine_id: ma_param[:machine_id],
          machine_status_id: ma_param[:machine_status_id],
          work_process_id: wp_id
        )
      end
    end
  end

  def determine_work_process_ids_for_new_assignment
    current_wp = find_current_work_process(@order.work_processes)
    if current_wp
      # current_wp に紐づくすべての作業工程の ID を取得
      associated_work_processes = @order.work_processes.where(work_process_definition_id: current_wp.work_process_definition_id)
      associated_work_processes.pluck(:id)
    else
      []
    end
  end
end
