class Admin::MachinesController < ApplicationController
  before_action :machine_params, only: %i[update]
  before_action :set_machine, only: %i[show edit update]
  before_action :admin_user
  # 関連するモデルを事前に読み込む
  # Machineモデルごとの作業工程を表示するため、@machinesを中心にデータを取得

  def new
    @machine = Machine.new
  end

  def create
    @machine = Machine.new(machine_params)
    if @machine.save
      redirect_to admin_machines_path, status: :unprocessable_entity, notice: "機械が登録されました。"
    else
      render :new
    end
  end

  def index
    @machines = Machine.machine_associations
  end

  def show
    # modelで定義したlatest_work_processで最新の工程を取得して表示
    @latest_work_process = @machine.latest_work_process
    @latest_work_process_status = @machine.latest_work_process_status
    @latest_factory_estimated_completion_date = @machine.latest_factory_estimated_completion_date
    # modelで定義したlatest_machine_assignmentで最新の機械の割り当てを取得して表示
    @latest_machine_assignment = @machine.latest_machine_assignment
  end

  def edit; end

  def update
    # paramsでフォームのデータを安全に受け取る
    params_machine_assignment_id = params[:machine_assignment_id]
    params_machine_status_id = params[:machine_status_id]

    if @machine.update(machine_params)
      assignment = @machine.machine_assignments.find_by(id: params_machine_assignment_id)

      # assignmentの更新があった場合
      if assignment
        # MachineAssignmentの状態を更新
        assignment.update(machine_status_id: params_machine_status_id)
      else
        flash.now[:alert] = "指定された割り当てが見つかりません。"
      end

      flash[:notice] = "機械の割り当てが更新されました"
      redirect_to admin_machine_path(@machine)
    else
      flash.now[:alert] = @machine.errors.full_messages.join(", ") # エラーメッセージを追加
      render :edit
    end
  end

  # 削除処理の開始し管理者削除を防ぐロジックはmodelで行う
  def destroy
    # binding.irb
    @machine = Machine.find(params[:id])
    if @machine.destroy
      # ココ(削除実行直前)でmodelに定義したコールバックが呼ばれる

      flash[:notice] = t("flash.admin.destroyed")
    else
      # バリデーションに失敗で@user.errors.full_messagesにエラーメッセージが配列として追加されます
      # .join(", "): 配列内の全てのエラーメッセージをカンマ区切り（, ）で連結
      flash[:alert] = @machine.errors.full_messages.join(", ")
    end
    redirect_to admin_machines_path
  end

  private

  # 登録、更新フォームの情報をparams
  def machine_params
    params.require(:machine).permit(
      :machine_type_id,
      :company_id,
      :name
    )
  end

  # Machineモデル、関連するモデルのデータを事前に取得
  def set_machine
    @machine = Machine.find_with_associations(params[:id])

    unless @machine
      redirect_to admin_machines_path, alert: "該当する機械が見つかりません。"
    end
  end

  # 一般ユーザがアクセスした場合には一覧画面にリダイレクト
  def admin_user
    unless current_user&.admin?
      redirect_to orders_path, alert: "管理者以外アクセスできません"
    end
  end
end
