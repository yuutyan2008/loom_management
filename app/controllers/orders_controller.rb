# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  include ApplicationHelper
  before_action :require_login
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :authorize_order, only: [:show, :destroy]

  def index
    @company = current_user.company
    @orders = @company.orders.exists? ? @company.orders : []
    @no_orders_message = "現在受注している商品はありません" unless @orders.any?

    check_overdue_work_processes_index(@orders)
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

        # 受注にMachineを割り当てる場合
        # 例: params[:order][:assign_machine] = { machine_id: 2, machine_status_id: 3 }
        if params[:order][:assign_machine].present?
          machine_id = params[:order][:assign_machine][:machine_id]
          new_status_id = params[:order][:assign_machine][:machine_status_id]
          machine = Machine.find(machine_id)
          assign_machine_to_order(@order, machine, new_status_id)
        end

        # 全WorkProcessが完了しMachineを初期状態に戻す場合
        # 例: params[:order][:complete_all_work_processes] = { machine_id: 2 }
        if params[:order][:complete_all_work_processes].present?
          machine_id = params[:order][:complete_all_work_processes][:machine_id]
          machine = Machine.find(machine_id)
          reset_machine_to_idle(machine)
        end

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
      MachineAssignment.where(machine_id: machine_id).update_all(machine_status_id: new_status_id)
    end
  end

  # Orderに紐づく全WorkProcessを指定Machineに割り当て
  def assign_machine_to_order(order, machine, machine_status_id)
    # 既存データを消さずに、新たなWorkProcessに対してMachineAssignmentを追加する
    wp_ids = order.work_processes.pluck(:id)
    # 既に存在するMachineAssignmentと重複しないWorkProcessだけに割り当てる例（必要に応じてロジックを調整）
    existing_wp_ids = MachineAssignment.where(machine_id: machine.id).pluck(:work_process_id)
    new_wp_ids = wp_ids - existing_wp_ids
    new_wp_ids.each do |wp_id|
      MachineAssignment.create!(
        machine_id: machine.id,
        work_process_id: wp_id,
        machine_status_id: machine_status_id
      )
    end
  end

  # 全WorkProcess完了後にMachineを初期状態へ戻す
  def reset_machine_to_idle(machine)
    MachineAssignment.where(machine_id: machine.id).delete_all
    MachineAssignment.create!(
      machine_id: machine.id,
      work_process_id: nil,
      machine_status_id: 1 # 初期待機状態
    )
  end

  # 以下のチェックメソッドは元のまま維持
  def check_overdue_work_processes_index(orders)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status
    overdue_work_processes = WorkProcess.includes(:order, :work_process_definition)
                                        .where(order_id: orders&.ids)
                                        .where("earliest_estimated_completion_date < ?", Date.today)
                                        .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      grouped = overdue_work_processes.group_by(&:order)
      total_overdue_orders = grouped.keys.size
      message = grouped.map do |order, wps|
        wp_links = wps.each_with_index.map do |wp, index|
          if index == 0
            "受注 ID:#{order.id} 作業工程: #{wp.work_process_definition.name}"
          else
            "作業工程: #{wp.work_process_definition.name}"
          end
        end.join(", ")
        link = view_context.link_to wp_links, order_path(order), class: "underline"
        "<li>#{link}</li>"
      end.join("<br>").html_safe

      flash.now[:alert] = <<-HTML.html_safe
        <strong>予定納期が過ぎている受注が #{total_overdue_orders} 件あります。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          #{message}
        </ul>
      HTML
    end
  end

  def check_overdue_work_processes_show(work_processes)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status
    overdue_work_processes = work_processes.where("earliest_estimated_completion_date < ?", Date.today)
                                           .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      message = overdue_work_processes.each_with_index.map do |wp, index|
        if index == 0
          "受注 ID:#{@order.id} 作業工程: #{wp.work_process_definition.name}"
        else
          "作業工程: #{wp.work_process_definition.name}"
        end
      end.join(", ")

      flash.now[:alert] = <<-HTML.html_safe
        <strong>以下の作業工程が予定完了日を過ぎており、まだ完了していません。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          <li>#{message}</li>
        </ul>
      HTML
    end
  end
end
