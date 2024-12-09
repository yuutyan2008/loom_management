class Admin::HomeController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_company, only: [:show]

  def index
    @orders = Order.all
    @no_orders_message = "現在、受注はありません。"
    @companies = Company.includes(machines: { machine_assignments: :machine_status })
                        .where.not(id: 1)
                        .map do |company|
      # 各機屋の稼働状況を集計
      machines = company.machines
      {
        id: company.id,
        name: company.name,
        inactive_count: machines.joins(machine_assignments: :machine_status)
                                .where(machine_statuses: { name: "未稼働" }).uniq.count,
        preparation_count: machines.joins(machine_assignments: :machine_status)
                                .where(machine_statuses: { name: "準備中" }).uniq.count,
        active_count: machines.joins(machine_assignments: :machine_status)
                              .where(machine_statuses: { name: "稼働中" }).uniq.count,
        broken_count: machines.joins(machine_assignments: :machine_status)
                              .where(machine_statuses: { name: "故障中" }).uniq.count
      }
    end
  end

  def show
    @machines = @company.machines.includes(machine_assignments: :machine_status).order(:id).uniq

    # 最新の情報を各機械ごとに取得
    @latest_work_processes = @machines.map(&:latest_work_process)
    @latest_work_process_statuses = @machines.map(&:latest_work_process_status)
    @latest_factory_estimated_completion_dates = @machines.map(&:latest_factory_estimated_completion_date)
    @latest_machine_assignments = @machines.map(&:latest_machine_assignment)
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
end
