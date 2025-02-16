class MachinesController < ApplicationController
  include ApplicationHelper
  include FlashHelper
  before_action :require_login
  before_action :set_company
  before_action :set_machine, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_machine, only: [ :show, :edit, :update, :destroy ]

  def index
    # set_company で current_userのcompanyが @companyに入る

    @machines = @company.machines.includes(
      machine_assignments:
        [ :work_process, :machine_status ]
        ).order(:id) # order(:id) は そのモデルの主キー id を使ってソート する。

    @no_machines_message = "現在保有している織機はありません" if @machines.empty?

    @work_processes = WorkProcess.ordered

    check_machine_status_index(@machines)
      # 検索の実行（スコープを適用）
      @machines = @machines
      .search_by_company(params[:company_id])
      .search_by_machine(params[:machine_id])
      .search_by_product_number(params[:product_number_id])
      .search_by_work_process_definitions(params[:work_process_definition_id])
  end

  def search_params
    if params[:search].present?
      params.fetch(:search, {}).permit(:company_id, :machine_id, :color_number_id, :work_process_definition_id)
    end
  end

  def show
    @work_processes = @machine.work_processes.ordered.includes(machine_assignments: [ :machine_status ])
    check_machine_status_show(@machine)
  end

  def new
    @machine = Machine.new
    @company = current_user.company
  end

  def create
    ActiveRecord::Base.transaction do
      @machine = @company.machines.build(machine_params)

      if @machine.save
        # 織機が保存されたら、関連する MachineAssignment を作成
        MachineAssignment.create!(
          machine_id: @machine.id,
          machine_status_id: 1,  # デフォルトで「未稼働」の状態とする
          work_process_id: nil  # 初期状態では作業工程なし
        )

        redirect_to machine_path(@machine), notice: "織機が作成されました。"
      else
        raise ActiveRecord::Rollback  # 織機が保存できなかったらロールバック
      end
    end

    render :new, status: :unprocessable_entity if @machine.new_record?
  end

  def edit
  end

  def update
    # machine_status_idをパラメータから取得して、machine_paramsからは除外
    machine_status_id = params[:machine].delete(:machine_status_id)

    ActiveRecord::Base.transaction do
      # 織機が現在のユーザーの会社に所属しているか再確認
      if @machine.company_id != current_user.company_id
        raise ActiveRecord::RecordInvalid, "現在のユーザーの会社に属していない織機は更新できません"
      end

      # 織機自体の属性を更新
      @machine.update!(machine_params)

      # machine_status_idがあれば、関連するMachineAssignmentを個別に更新
      if machine_status_id.present?
        @machine.machine_assignments.each do |assignment|
          assignment.update!(machine_status_id: machine_status_id)
        end
      end
    end

    # 修正対象
    redirect_to machines_path, notice: "織機が更新されました。"
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
    params.require(:machine).permit(
      :name,
      :machine_type_id
    )
  end

  # ↓↓ フラッシュメッセージを出すのに必要なメソッド ↓↓
  ## 追加: indexアクション用のMachineStatusチェックメソッド
  def check_machine_status_index(machines)
    target_work_process_def = WorkProcessDefinition.find_by(id: 4)
    return unless target_work_process_def

    relevant_work_processes = WorkProcess.where(work_process_definition_id: target_work_process_def.id)
    problematic_machine_assignments = MachineAssignment.joins(:work_process)
                                                       .where(work_processes: { work_process_definition_id: 4 })
                                                       .where.not(machine_status_id: 3) # "稼働中" でない

    problematic_machine_assignments = problematic_machine_assignments.where(machine: machines)
    if problematic_machine_assignments.exists?
      grouped = problematic_machine_assignments.includes(:machine, work_process: :order).group_by(&:machine)
      total_problematic_machines = grouped.keys.size

      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_machine_status_message(
        "予定納期を超えて '稼働中' ではない織機が #{total_problematic_machines} 台あります。",
        grouped.keys,
        ->(machine) { machine_path(machine) },
        ->(machine) { edit_machine_path(machine) }
      )
    end
  end

  ## 追加: showアクション用のMachineStatusチェックメソッド
  def check_machine_status_show(machine)
    target_work_process_def = WorkProcessDefinition.find_by(id: 4)
    return unless target_work_process_def

    relevant_work_processes = WorkProcess.where(work_process_definition_id: target_work_process_def.id, order: machine.company.orders)
    problematic_machine_assignments = machine.machine_assignments.joins(:work_process)
                                                                 .where(work_processes: { work_process_definition_id: 4 })
                                                                 .where.not(machine_status_id: 3) # "稼働中" でない

    if problematic_machine_assignments.exists?
      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_machine_status_message(
        "予定納期を超えて織機が '稼働中' ではありません。",
        problematic_machine_assignments.map(&:machine),
        nil,
        ->(machine) { edit_machine_path(machine) }
      )
    end
  end
end
