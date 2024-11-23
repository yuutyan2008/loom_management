module ApplicationHelper
  # 現在作業中の作業工程を取得するヘルパーメソッド
  def find_current_work_process(work_processes)
    # 「作業完了」ステータスの最新の作業工程を取得
    latest_completed_wp = work_processes.joins(:work_process_status)
                                        .where(work_process_statuses: { name: '作業完了' })
                                        .order(start_date: :desc)
                                        .first
    if latest_completed_wp
      # 最新の「作業完了」より後の作業工程を取得
      next_process = work_processes.where('start_date > ?', latest_completed_wp.start_date).order(:start_date).first
      next_process
    else
      # 「作業完了」がない場合、最も古い作業工程を取得
      work_processes.order(:start_date).first
    end
  end

  def not_available(value)
    value.presence || 'N/A'
  end

  def not_machine_status(value)
    value.presence || '未稼働'
  end

  # 受注の現在の作業工程名を取得
  def work_process_name(order)
    current_wp = find_current_work_process(order.work_processes)
    not_available(current_wp&.work_process_definition&.name)
  end

  # 受注の現在のステータスを取得
  def work_process_status(order)
    current_wp = find_current_work_process(order.work_processes)
    not_available(current_wp&.work_process_status&.name)
  end

  # 受注に関連する織機の名前を取得
  def machine_names(order)
    current_wp = find_current_work_process(order.work_processes)
    names = current_wp&.machines&.map(&:name)&.join(', ')
    not_available(names)
  end

  # 稼働状況を取得
  def machine_statuses(machine)
    current_wp = find_current_work_process(machine.work_processes)
    statuses = []
    if current_wp
      # 現在の作業工程に関連する MachineAssignment のステータスを追加
      statuses += current_wp.machine_assignments.map { |a| a.machine_status.name }
    end
    # work_process_id が nil の MachineAssignment のステータスを追加
    statuses += machine.machine_assignments.where(work_process_id: nil).map { |a| a.machine_status.name }
    # 重複を排除し、カンマ区切りで表示
    statuses = statuses.uniq.join(', ')
    not_machine_status(statuses)
  end

  # 品番を取得
  def product_number(machine)
    current_wp = find_current_work_process(machine.work_processes)
    number = current_wp&.order&.product_number&.number
    not_available(number)
  end

  # 現在の作業工程名を取得
  def work_process_name(machine)
    current_wp = find_current_work_process(machine.work_processes)
    name = current_wp&.work_process_definition&.name
    not_available(name)
  end

  # ステータスを取得
  def work_process_status(machine)
    current_wp = find_current_work_process(machine.work_processes)
    status = current_wp&.work_process_status&.name
    not_available(status)
  end
end
