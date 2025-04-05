class Admin::MachinesController < ApplicationController
  include ApplicationHelper
  include FlashHelper
  before_action :machine_params, only: %i[update]
  before_action :set_machine, only: %i[show edit update]
  before_action :admin_user
  # 関連するモデルを事前に読み込む
  # Machineモデルごとの作業工程を表示するため、@machinesを中心にデータを取得

  def index
    @machines = Machine.machine_associations.order(:id)
    check_machine_status_index(@machines)

    # 検索の実行（スコープを適用）
    @machines = @machines
      .search_by_company(params[:company_id])
      .search_by_machine(params[:machine_id])
      .search_by_product_number(params[:product_number_id])
      # .search_by_work_process_definitions(params[:work_process_definitions_id])
  end

  def search_params
    if params[:search].present?
      params.fetch(:search, {}).permit(:company_id, :machine_id, :color_number_id, :work_process_definition_id)
    end
  end

  def show
    # modelで定義したlatest_work_processで最新の工程を取得して表示
    @latest_work_process = @machine.latest_work_process
    @latest_work_process_status = @machine.latest_work_process_status
    @latest_factory_estimated_completion_date = @machine.latest_factory_estimated_completion_date
    # modelで定義したlatest_machine_assignmentで最新の機械の割り当てを取得して表示
    @latest_machine_assignment = @machine.latest_machine_assignment

    # WorkProcessをsequence順に取得
    @ordered_work_processes = @machine.work_processes.ordered
    check_machine_status_show(@machine)
  end

  def new
    @machine = Machine.new
    @companies = Company.where.not(id: 1)
  end

  def create
    @machine = Machine.new(machine_params)
    if @machine.save
      redirect_to admin_machines_path, status: :unprocessable_entity, notice: "機械が登録されました。"
    else
      render :new
    end
  end

  def edit
  end

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

  # ↓↓ フラッシュメッセージを出すのに必要なメソッド ↓↓
  ## 追加: indexアクション用のMachineStatusチェックメソッド
  def check_machine_status_index(machines)
    target_work_process_def = WorkProcessDefinition.find_by(id: 4)
    return unless target_work_process_def

    # 現在の日付を取得
    today = Date.today

    relevant_work_processes = WorkProcess.where(work_process_definition_id: target_work_process_def.id)
    problematic_machine_assignments = MachineAssignment.joins(:work_process)
                                                       .where(work_processes: { work_process_definition_id: 4 })
                                                       .where.not(machine_status_id: 3) # "稼働中" でない
                                                       .where("work_processes.latest_estimated_completion_date < ?", today) # 最遅完了予定日 < 本日 の判定

    problematic_machine_assignments = problematic_machine_assignments.where(machine: machines)
    if problematic_machine_assignments.exists?
      grouped = problematic_machine_assignments.includes(:machine, work_process: :order).group_by(&:machine)
      total_problematic_machines = grouped.keys.size

      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_machine_status_message(
        "予定納期を超えて '稼働中' ではない織機が #{total_problematic_machines} 台あります。",
        grouped.keys,
        ->(machine) { admin_machine_path(machine) },
        ->(machine) { edit_admin_machine_path(machine) }
      )
    end
  end

  ## 追加: showアクション用のMachineStatusチェックメソッド
  def check_machine_status_show(machine)
    target_work_process_def = WorkProcessDefinition.find_by(id: 4)
    return unless target_work_process_def

    # 現在の日付を取得
    today = Date.today

    relevant_work_processes = WorkProcess.where(work_process_definition_id: target_work_process_def.id, order: machine.company.orders)
    problematic_machine_assignments = machine.machine_assignments.joins(:work_process)
                                                                 .where(work_processes: { work_process_definition_id: 4 })
                                                                 .where.not(machine_status_id: 3) # "稼働中" でない
                                                                 .where("work_processes.latest_estimated_completion_date < ?", today) # 最遅完了予定日 < 本日 の判定

    if problematic_machine_assignments.exists?
      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_machine_status_message(
        "予定納期を超えて織機が '稼働中' ではありません。",
        problematic_machine_assignments.map(&:machine),
        nil,
        ->(machine) { edit_admin_machine_path(machine) }
      )
    end
  end
end
