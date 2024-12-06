class MachinesController < ApplicationController
  include ApplicationHelper
  before_action :require_login
  before_action :set_company
  before_action :set_machine, only: [:show, :edit, :update, :destroy]
  before_action :authorize_machine, only: [:show, :edit, :update, :destroy]

  def index
    @machines = @company.machines.includes(machine_assignments: [:work_process, :machine_status])
    @no_machines_message = "現在保有している織機はありません" if @machines.empty?
    @work_processes = WorkProcess.ordered
    check_machine_status_index(@machines)
  end

  def show
    @work_processes = @machine.work_processes.ordered.includes(machine_assignments: [:machine_status])
    check_machine_status_show(@machine)
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
    # machine_status_idをパラメータから取得して、machine_paramsからは除外
    machine_status_id = params[:machine].delete(:machine_status_id)

    ActiveRecord::Base.transaction do
      # 織機が現在のユーザーの会社に所属しているか再確認（authorize_machineがあるなら不要）
      if @machine.company_id != current_user.company_id
        raise ActiveRecord::RecordInvalid, "現在のユーザーの会社に属していない織機は更新できません"
      end

      # 織機自体の属性を更新
      @machine.update!(machine_params)

      # machine_status_idがあれば、関連するMachineAssignmentを一括更新
      if machine_status_id.present?
        # @machineに紐づくMachineAssignmentを一括更新
        # ここではmachine_status_idのみ更新しているが、必要に応じて他のカラムもまとめて更新可能
        @machine.machine_assignments.update_all(machine_status_id: machine_status_id, updated_at: Time.current)
      end
    end

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

  # 追加: indexアクション用のMachineStatusチェックメソッド
  def check_machine_status_index(machines)
    # WorkProcessDefinition id = 4 を取得
    target_work_process_def = WorkProcessDefinition.find_by(id: 4)
    return unless target_work_process_def
    # WorkProcessDefinition id=4 に関連する WorkProcess を取得
    relevant_work_processes = WorkProcess.where(work_process_definition_id: target_work_process_def.id)
    # MachineAssignments を通じて MachineStatus が "稼働中" でないものを取得
    problematic_machine_assignments = MachineAssignment.joins(:work_process)
                                                       .where(work_processes: { work_process_definition_id: 4 })
                                                       .where.not(machine_status_id: 3) # machine_status_id:3 が "稼働中"

    # 対象のマシンに関連するものに絞る
    problematic_machine_assignments = problematic_machine_assignments.where(machine: machines)
    if problematic_machine_assignments.exists?
      # マシンごとにグループ化
      grouped = problematic_machine_assignments.includes(:machine, work_process: :order).group_by(&:machine)
      # 件数の取得
      total_problematic_machines = grouped.keys.size
      # メッセージの設定
      message = grouped.map do |machine, assignments|
        assignment_messages = assignments.map do |ma|
          "#{ma.machine_status.name}"
        end.join(", ")
        # マシンへのリンクを作成
        link = view_context.link_to("織機名: #{machine.name} ステータス: #{assignment_messages}", machine_path(machine), class: "underline")
        "<li>#{link}</li>"
      end.join("<br>").html_safe

      flash.now[:alert] = <<-HTML.html_safe
        <strong>予定納期を超えて '稼働中' ではない織機が #{total_problematic_machines} 台あります。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          #{message}
        </ul>
      HTML
    end
  end

  # 追加: showアクション用のMachineStatusチェックメソッド
  def check_machine_status_show(machine)
    # WorkProcessDefinition id = 4 を取得
    target_work_process_def = WorkProcessDefinition.find_by(id: 4)
    return unless target_work_process_def
    # WorkProcessDefinition id=4 に関連する WorkProcess を取得
    relevant_work_processes = WorkProcess.where(work_process_definition_id: target_work_process_def.id, order: machine.company.orders)
    # MachineAssignments を通じて MachineStatus が "稼働中" でないものを取得
    problematic_machine_assignments = machine.machine_assignments.joins(:work_process)
                                                                 .where(work_processes: { work_process_definition_id: 4 })
                                                                 .where.not(machine_status_id: 3) # machine_status_id:3 が "稼働中"

    if problematic_machine_assignments.exists?
      # 各MachineAssignmentごとにメッセージを生成
      message = problematic_machine_assignments.map do |ma|
        "織機名: #{ma.machine.name} ステータス: #{ma.machine_status.name}"
      end.join("<br>").html_safe

      flash.now[:alert] = <<-HTML.html_safe
        <strong>予定納期を超えて織機が '稼働中' ではありません。</strong>
        <ul class="text-red-700 list-disc ml-4 px-4 py-2">
          <li>#{message}</li>
        </ul>
      HTML
    end
  end
end
