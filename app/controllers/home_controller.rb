class HomeController < ApplicationController
  include FlashHelper
  before_action :require_login, only: [:index, :update]

  def index
    @company = current_user&.company
    @machines = @company&.machines&.includes(:company, :work_processes)

    @machine_status_data = @machines.map do |machine|
      work_process = machine.latest_work_process
      work_process_data = update_work_process_data(machine, work_process)
      {
        machine: machine,
        work_process_name: work_process_data[:work_process_name],
        machine_status_name: machine.latest_machine_status&.name || "不明",
        button_label: work_process_data[:button_label],
        button_disabled: work_process_data[:button_disabled],
        confirm_text: work_process_data[:confirm_text],
        order_id: work_process&.order_id
      }
    end
  end


  def update
    @company = current_user&.company
    machine_id = params[:machine_id]
    order_id = params[:order_id] # machine.latest_work_processから取得したorder_id
    @machine = @company&.machines.find(machine_id)
    @order = @company&.orders.find(order_id)

    ActiveRecord::Base.transaction do
      # ボタンの種類(作業開始,作業終了)を識別
      if params[:commit] == "作業開始"
        # 作業開始処理
        today = Date.current

        # 作業1-3を完了にし、完了日を今日に設定
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3])
                   .update_all(
                     work_process_status_id: 3,           # 完了
                     actual_completion_date: today        # 完了日を今日に設定
                   )

        # 作業1-3の完了予定日を条件付きで更新（現在日より後の場合のみ今日に設定）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3])
                   .where('earliest_estimated_completion_date > ?', today)
                   .update_all(earliest_estimated_completion_date: today)

        # 作業1-4の開始日を条件付きで更新（現在日より後の場合のみ今日に設定）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3,4])
                   .where('start_date > ?', today)
                   .update_all(start_date: today)

        # 作業1-3の完了予定日を条件付きで更新（明日以降または空白の場合、本日に設定）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3])
                   .where('factory_estimated_completion_date > ? OR factory_estimated_completion_date IS NULL', today)
                   .update_all(factory_estimated_completion_date: today)

        # 作業4を作業中にする
        WorkProcess.where(order_id: order_id, work_process_definition_id: 4)
                   .update_all(work_process_status_id: 2) # 作業中に更新

        # MachineAssignmentを稼働中に更新
        MachineAssignment.where(machine_id: machine_id, machine_status_id: [1,2,4]) # 未稼働{1}, 準備中{2}, 故障中{4}
                         .update_all(machine_status_id: 3) # 稼働中
      elsif params[:commit] == "作業終了"
        # 作業終了処理
        today = Date.current

        # 作業1-4を完了にする（1-3の完了日は変更しない）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [1,2,3,4])
                   .update_all(work_process_status_id: 3) # 完了

        # 作業4の完了日を今日に設定
        WorkProcess.where(order_id: order_id, work_process_definition_id: 4)
                   .update_all(actual_completion_date: today)

        # 作業4の開始日を条件付きで更新（現在日より後の場合のみ今日に設定）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [4,5])
                   .where('start_date > ?', today)
                   .update_all(start_date: today)

        # 作業4の完了予定日を条件付きで更新（現在日より後の場合のみ今日に設定）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [4])
                   .where('earliest_estimated_completion_date > ?', today)
                   .update_all(earliest_estimated_completion_date: today)

        # 作業4の完了予定日を条件付きで更新（明日以降または空白の場合、本日に設定）
        WorkProcess.where(order_id: order_id, work_process_definition_id: [4])
                   .where('factory_estimated_completion_date > ? OR factory_estimated_completion_date IS NULL', today)
                   .update_all(factory_estimated_completion_date: today)

        # 作業5を作業中に更新
        WorkProcess.where(order_id: order_id, work_process_definition_id: 5)
                   .update_all(work_process_status_id: 2) # 作業中に更新

        # 下記を修正予定
        # MachineAssignmentの織機をnilに更新
        MachineAssignment.where(machine_id: machine_id, work_process_id: @order.work_processes)
                         .update_all(machine_id: nil, machine_status_id: nil)
        # 新規MachineAssignment追加
        MachineAssignment.create!(machine_id: machine_id, machine_status_id: 1, work_process_id: nil)
      end
    end

    @company = current_user&.company
    @machines = @company&.machines&.includes(:company, :work_processes)

    @machine_status_data = @machines.map do |machine|
      work_process = machine.latest_work_process
      work_process_data = update_work_process_data(machine, work_process)
      {
        machine: machine,
        work_process_name: work_process_data[:work_process_name],
        machine_status_name: machine.latest_machine_status&.name || "不明",
        button_label: work_process_data[:button_label],
        button_disabled: work_process_data[:button_disabled],
        order_id: work_process&.order_id
      }
    end

    redirect_to root_path, notice: "ステータスが正常に更新されました。"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: "ステータスの更新に失敗しました: #{e.message}"
  end

  private

  def update_work_process_data(machine, work_process)

    if work_process.nil?
      return {
        work_process_name: "作業工程なし",
        button_label: "更新不可",
        button_disabled: true
      }
    end

    order_id = work_process.order_id
    wps = machine.work_processes.where(order_id: order_id)

    wp1 = wps.find { |wp| wp.work_process_definition_id == 1 }
    wp2 = wps.find { |wp| wp.work_process_definition_id == 2 }
    wp3 = wps.find { |wp| wp.work_process_definition_id == 3 }
    wp4 = wps.find { |wp| wp.work_process_definition_id == 4 }

    wp1_complete = (wp1&.work_process_status_id == 3)? true : false
    wp2_complete = (wp2&.work_process_status_id == 3)? true : false
    wp3_complete = (wp3&.work_process_status_id == 3)? true : false
    wp4_status = wp4&.work_process_status_id
    #button_label, button_disabled = determine_button_status(wp1_complete, wp2_complete, wp3_complete, wp4_status)
    button_label, button_disabled, confirm_text = determine_button_status_and_confirmation(wp1_complete, wp2_complete, wp3_complete, wp4_status)
    {
      work_process_name: work_process.work_process_definition&.name || "作業工程なし",
      button_label: button_label,
      button_disabled: button_disabled,
      confirm_text: confirm_text
    }
  end

  def determine_button_status(wp1_complete, wp2_complete, wp3_complete, wp4_status)
    if wp1_complete && wp2_complete && wp3_complete && (wp4_status == 1 || wp4_status == 2)
      return ["作業終了", false]
    elsif (wp1_complete && wp2_complete && wp3_complete && wp4_status == 3) ||
          (wp1_complete && wp2_complete && wp3_complete && wp4_status == 4)
      return ["更新不可", true]
    else
      return ["作業開始", false]
    end
  end

  def determine_button_status_and_confirmation(wp1, wp2, wp3, wp4)
    if wp1 && wp2 && wp3 && (wp4 == 1 || wp4 == 2)
      [
        "作業終了",
        false,
        "製織工程を完了し、整理加工工程を開始します。よろしいですか？"
      ]
    elsif wp1 && wp2 && wp3 && (wp4 == 3 || wp4 == 4)
      ["更新不可", true, nil]
    else
      [
        "作業開始",
        false,
        "糸工程〜整経工程を完了し、製織工程を開始します。よろしいですか？"
      ]
    end
  end


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
