class User::MachinesController < ApplicationController
  include ApplicationHelper
  before_action :set_machine, only: [ :show, :edit, :update, :destroy ]

  def index
    @machines = Machine.all
    @work_processes = WorkProcess.all
  end

  def show
    @work_processes = @machine.work_processes.all
  end

  def new
    @machine = Machine.new
  end

  def create
    @machine = Machine.new(machine_params)
    if @machine.save
      redirect_to user_machine_path(@machine), notice: "織機が作成されました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @machine.update(machine_params)
      redirect_to user_machines_path, notice: "織機が更新されました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @machine.destroy
    redirect_to user_machines_path, status: :see_other, notice: "織機が削除されました。"
  end

  private

  def set_machine
    @machine = Machine.find(params[:id])
  end

  def machine_params
    params.require(:machine).permit(:name, :machine_type_id, :company_id)
  end
end
