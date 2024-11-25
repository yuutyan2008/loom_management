class MachinesController < ApplicationController
  include ApplicationHelper
  before_action :require_login
  before_action :set_company
  before_action :set_machine, only: [:show, :edit, :update, :destroy]
  before_action :authorize_machine, only: [:show, :edit, :update, :destroy]

  def index
    @machines = @company.machines
    @no_machines_message = "現在織機はありません" if @machines.empty?
    @work_processes = WorkProcess.all
  end

  def show
    @work_processes = @machine.work_processes
  end

  def new
    @machine = Machine.new
  end

  def create
    @machine = @company.machines.build(machine_params)
    if @machine.save
      redirect_to machine_path(@machine), notice: "織機が作成されました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    machine_status_id = params[:machine].delete(:machine_status_id)

    ActiveRecord::Base.transaction do
      @machine.update!(machine_params)
      update_machine_assignment(machine_status_id) if machine_status_id.present?
      redirect_to machines_path, notice: "織機が更新されました。"
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "更新に失敗しました: #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @machine.destroy
    redirect_to machines_path, notice: "織機が削除されました。"
  end

  private

  # 現在のユーザーの会社をセット
  def set_company
    @company = current_user.company
  end

  # 織機をセットし、存在しない場合はリダイレクト
  def set_machine
    @machine = Machine.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to machines_path, alert: "指定された織機は存在しません。"
  end

  # アクセス権限のチェック
  def authorize_machine
    unless @machine.company == @company
      redirect_to machines_path, alert: "アクセス権限がありません。"
    end
  end

  # 許可するパラメータの定義（machine_status_id を除外）
  def machine_params
    params.require(:machine).permit(:name, :machine_type_id)
  end

  # MachineAssignmentの更新または作成
  def update_machine_assignment(machine_status_id)
    assignment = @machine.machine_assignments.first_or_initialize(work_process_id: nil)
    assignment.update!(machine_status_id: machine_status_id)
  end
end
