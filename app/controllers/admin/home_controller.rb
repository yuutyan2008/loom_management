class Admin::HomeController < ApplicationController
  include FlashHelper
  before_action :authenticate_admin!
  before_action :set_company, only: [:show]

  def index
    @orders = Order.all
    @no_orders_message = "現在、受注はありません。" unless @orders.exists?

    # WorkProcessにMachineAssignmentがないOrderを取得
    @orders_needing_assignment = @orders.select do |order|
      !order.work_processes.any? { |wp| wp.machine_assignments.any? }
    end

    # デバッグ用に binding.irb を挿入
    # binding.irb if @orders_needing_assignment.any?

    if @orders_needing_assignment.any?
      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_alert_message(
        "織機の割り当てができていない発注が #{ @orders_needing_assignment.count } 件あります。",
        @orders_needing_assignment,
        ->(order) { edit_admin_order_path(order) },
        ->(order) { admin_order_path(order) }
      )
    end

    @companies = Company.includes(machines: :machine_assignments)
                        .where.not(id: 1)
                        .map do |company|
      machines = company.machines

      # 各Machineの最新の稼働状況を取得
      status_counts = {
        "未稼働" => 0,
        "準備中" => 0,
        "稼働中" => 0,
        "故障中" => 0
      }

      machines.each do |machine|
        latest_status = machine.latest_machine_status&.name
        status_counts[latest_status] += 1 if status_counts.key?(latest_status)
      end

      {
        id: company.id,
        name: company.name,
        inactive_count: status_counts["未稼働"],
        preparation_count: status_counts["準備中"],
        active_count: status_counts["稼働中"],
        broken_count: status_counts["故障中"]
      }
    end
  end

  def show
    @machines = @company.machines.includes(machine_assignments: :machine_status).order(:id).uniq

    # 最新の情報を各機械ごとに取得
    @machines_with_details = @machines.map do |machine|
      {
        machine: machine,
        latest_process: machine.latest_work_process,
        latest_status: machine.latest_work_process_status,
        latest_completion_date: machine.latest_factory_estimated_completion_date,
        latest_assignment: machine.latest_machine_assignment
      }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_root_path, alert: "指定された会社が見つかりませんでした。"
  end

  private

  def authenticate_admin!
    # 管理者認証のロジックをここに追加
    redirect_to root_path unless current_user&.admin?
  end

  def set_company
    @company = Company.find(params[:id])
  end

  # ↓↓ フラッシュメッセージを出すのに必要なメソッド ↓↓
  # フラッシュメッセージを構造化データとして生成
  def build_flash_alert_message(title, orders, edit_path_helper, detail_path_helper)
    helpers.build_flash_alert_message(title, orders, edit_path_helper, detail_path_helper)
  end
end
