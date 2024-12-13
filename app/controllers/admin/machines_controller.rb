class Admin::MachinesController < ApplicationController
  include ApplicationHelper

  before_action :machine_params, only: %i[update]
  before_action :set_machine, only: %i[show edit update]
  before_action :admin_user
  # 関連するモデルを事前に読み込む
  # Machineモデルごとの作業工程を表示するため、@machinesを中心にデータを取得

  def index
    @machines = Machine.machine_associations.order(:id)
    check_machine_status_index(@machines)

    # 検索の実行（スコープを適用）
    @machines =
    @machines
      .search_by_company(params[:company_id])
      .search_by_machine(params[:machine_id])
      .search_by_product_number(params[:product_number_id])
      .search_by_work_process_definitios(params[:work_process_definition_id])
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

  def gant_index
    @orders = Order.includes(:work_processes, :company)
    colors = ["class-a", "class-b"]

  # 現在の作業工程を取得
  current_work_process = WorkProcess.current_work_process

    @orders = @orders.map.with_index do |order, order_index|
      # custom_classにクラスを指定して代入
      custom_class = colors[order_index % 2]
      order.work_processes.map { |process|
        # tmp = order.work_processes[0..order.work_processes.find_index(process)].map(&:id)
        # tmp.delete(process.id)
        {
          product_number: order.product_number.number,
          company: order.company.name,
          machine: machine_names(order),
          id: process.id.to_s,
          name: process.work_process_definition.name,
          work_process_status: process.work_process_status.name,
          end: process&.earliest_estimated_completion_date&.strftime('%Y-%m-%d'),
          # end: process&.factory_estimated_completion_date&.strftime('%Y-%m-%d'),
          start: process&.start_date&.strftime('%Y-%m-%d'),
          # actual_completion_date: process&.actual_completion_date&.strftime('%Y-%m-%d'),
          progress: 100,
          # dependencies: tmp.join(",")
          custom_index: order.id,
          custom_class: custom_class
        }
      }
    end.flatten.to_json
    # binding.irb
  end

  def orders
    # DBからデータを取得
    @orders = Order.includes(:work_processes)

    # ガントチャート用のフォーマットに変換
    render json: @orders.map { |order|
      {
        machine_name: machine_names(order),
        id: order.id,
        name: order.company.name,
        product_number: order.product_number.number,
        machine_status: machine_statuses_for_order(order),

        work_processes: order.work_processes.map { |process|
        {
          name: process.work_process_definition.name,
          work_process_status: process.work_process_status.name,
          start: process.earliest_estimated_completion_date.strftime('%Y-%m-%d'),
          end: process.factory_estimated_completion_date.strftime('%Y-%m-%d'),
          start_date: process.start_date.strftime('%Y-%m-%d'),
          actual_completion_date: process.actual_completion_date.strftime('%Y-%m-%d'),
        }
      }
    }
  }
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
        link = view_context.link_to("会社名: #{machine.company.name}, 織機名: #{machine.name}, ステータス: #{assignment_messages}", admin_machine_path(machine), class: "underline")
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
        "会社名: #{machine.company.name}, 織機名: #{ma.machine.name}, ステータス: #{ma.machine_status.name}"
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
