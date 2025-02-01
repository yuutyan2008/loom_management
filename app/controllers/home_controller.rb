class HomeController < ApplicationController
  include FlashHelper
  before_action :require_login, only: [:index, :update]

  def index
    @company = current_user&.company
    # 会社に紐づく全Machineを取得し、関連情報をプリロード
    @machines = @company&.machines&.machine_associations
    # if @company&.orders.exists?
    #   @orders = @company&.orders.includes(:work_processes, :machine_assignments)
    #   check_overdue_work_processes_index(@orders)
    #   check_missing_machine_assignments(@orders) # 追加: 織機の割り当てができていない受注をチェック
    # else
    #   @orders = []
    #   @no_orders_message = "現在受注している商品はありません"
    # end
  end

  def update
    @company = current_user&.company
    machine_id = params[:machine_id]
    order_id = params[:order_id] # machine.latest_work_processから取得したorder_id
    @machine = @company&.machines.find(machine_id)
    @order = @company&.orders.find(order_id)

    ActiveRecord::Base.transaction do
      if params[:commit] == "作業開始"
        # 作業開始処理
        # 指定のWorkProcessを更新
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3])
                   .update_all(work_process_status_id: 3) # 完了
        WorkProcess.where(order_id: order_id, work_process_definition_id: 4)
                   .update_all(work_process_status_id: 2) # 作業中に更新
        # MachineAssignmentを稼働中に更新
        MachineAssignment.where(machine_id: machine_id, machine_status_id: [1,2,4]) # 未稼働{1}, 準備中{2}, 故障中{4}
                         .update_all(machine_status_id: 3) # 稼働中
      elsif params[:commit] == "作業終了"
        # 作業終了処理
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3,4])
                   .update_all(work_process_status_id: 3) # 完了
        WorkProcess.where(order_id: order_id, work_process_definition_id: 5)
                   .update_all(work_process_status_id: 2) # 作業中に更新
        # MachineAssignmentの織機をnilに更新
        MachineAssignment.where(machine_id: machine_id, work_process_id: @order.work_processes)
                         .update_all(machine_id: nil, machine_status_id: nil)
        # 新規MachineAssignment追加
        MachineAssignment.create!(machine_id: machine_id, machine_status_id: 1, work_process_id: nil)
      end
    end
    redirect_to root_path, notice: "ステータスが正常に更新されました。"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: "ステータスの更新に失敗しました: #{e.message}"
  end

  private

  # ↓↓ フラッシュメッセージを出すのに必要なメソッド ↓↓
  ## 既存: indexアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_index(orders)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status

    overdue_work_processes = WorkProcess.includes(:order, :work_process_definition)
                                        .where(order_id: orders.ids)
                                        .where("factory_estimated_completion_date < ?", Date.today)
                                        .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      grouped = overdue_work_processes.group_by(&:order)
      total_overdue_orders = grouped.keys.size

      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_alert_message(
        "予定納期が過ぎている受注が #{total_overdue_orders} 件あります。",
        grouped.keys,
        ->(order) { edit_order_path(order) },
        ->(order) { order_path(order) }
      )
    end
  end

  ## 追加: 織機の割り当てができていない受注をチェックするメソッド
  def check_missing_machine_assignments(orders)
    orders = Order.where(company_id: current_user&.company&.id)

    orders_without_assignment = orders.left_outer_joins(:machine_assignments)
                                      .where(machine_assignments: { machine_id: nil })
                                      .distinct
    all_work_process_definition_ids = [1, 2, 3, 4, 5]
    orders_with_work_process = orders.joins(:work_processes)
                                     .where(work_processes: { work_process_definition_id: all_work_process_definition_ids })
                                     .where.not(work_processes: { work_process_status_id: 3 })
                                     .distinct
    matched_orders = orders_without_assignment.where(id: orders_with_work_process.select(:id))

    if matched_orders.any?
      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_alert_message(
        "以下の受注は織機の割り当てができていません。",
        matched_orders,
        ->(order) { edit_order_path(order) },
        ->(order) { order_path(order) }
      )
    end
  end
end
