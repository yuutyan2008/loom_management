class MachinesController < ApplicationController
  include ApplicationHelper
  before_action :set_machine, only: [:show, :edit, :update, :destroy]
  before_action :require_login

  def index
    @company = current_user.company
    if @company.machines.exists?
      @machines = @company.machines
    else
      @machines = []
      @no_machines_message = "現在受注している商品はありません"
    end
    @work_processes = WorkProcess.all
  end

  def show
    @company = current_user.company
    if @machine.company == @company
      @work_processes = @machine.work_processes
    else
      redirect_to machines_path, alert: "アクセス権限がありません。"
    end
  end

  def new
    @machine = Machine.new
  end

  def create
    @machine = current_user.company.machines.build(machine_params)
    if @machine.save
      redirect_to machine_path(@machine), notice: "織機が作成されました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @company = current_user.company
    unless @machine.company == @company
      redirect_to machines_path, alert: "アクセス権限がありません。"
    end
  end

  def update
    @company = current_user.company
    if @machine.company == @company
      if @machine.update(machine_params)
        redirect_to machines_path, notice: "織機が更新されました。"
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to machines_path, alert: "アクセス権限がありません。"
    end
  end

  def destroy
    @company = current_user.company
    if @machine.company == @company
      @machine.destroy
      redirect_to machines_path, notice: "織機が削除されました。"
    else
      redirect_to machines_path, alert: "アクセス権限がありません。"
    end
  end

  private

  def set_machine
    @machine = Machine.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to machines_path, alert: "指定された織機は存在しません。"
  end

  def machine_params
    params.require(:machine).permit(:name, :machine_type_id, :company_id)
  end
end
