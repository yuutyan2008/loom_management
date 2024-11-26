class Admin::ProcessEstimatesController < ApplicationController

  def index
    @dobbie_estimates = ProcessEstimate.includes(:machine_type, :work_process_definition)
    .where(machine_types: { name: "ドビー" })
    .order("work_process_definitions.sequence ASC")

    @jacquard_estimates = ProcessEstimate.includes(:machine_type, :work_process_definition)
      .where(machine_types: { name: "ジャガード" })
      .order("work_process_definitions.sequence ASC")
  end

  def new
    @process_estimate = ProcessEstimate.new
  end

  def create
    @process_estimate = ProcessEstimate.new(process_estimate_params)
    if @process_estimate.save
      redirect_to admin_process_estimates_path(@process_estimate)
    else
      render :new
    end
  end

  def edit_all
    @dobbie_estimates = ProcessEstimate.includes(:machine_type, :work_process_definition)
    .where(machine_types: { name: "ドビー" })
    .order("work_process_definitions.sequence ASC")

    @jacquard_estimates = ProcessEstimate.includes(:machine_type, :work_process_definition)
      .where(machine_types: { name: "ジャガード" })
      .order("work_process_definitions.sequence ASC")
  end

  def update_all
    params[:process_estimates].each do |id, estimate_params|
      process_estimate = ProcessEstimate.find(id)
      process_estimate.update(estimate_params.permit(:earliest_completion_estimate, :latest_completion_estimate))
    end
    redirect_to admin_process_estimates_path, notice: "すべての工程を更新しました。"
  end

  private
  def process_estimate_params
    params.require(:process_estimate).permit(
      :work_process_definition_id,
      :machine_type_id,
      :earliest_completion_estimate,
      :latest_completion_estimate,
      :update_date
      )
  end

end
