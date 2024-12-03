module ApplicationHelper
  # 現在作業中の作業工程を取得するヘルパーメソッド
  def find_current_work_process(work_processes)
    work_processes.current_work_process
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

  # 受注の開始日を取得
  def work_process_start_date(order)
    current_wp = find_current_work_process(order.work_processes)
    not_available(current_wp&.start_date)
  end

  # 受注の完了予定日を取得
  def work_process_factory_estimated_completion_date(order)
    current_wp = find_current_work_process(order.work_processes)
    not_available(current_wp&.factory_estimated_completion_date)
  end

  # 受注に関連する織機の名前を取得
  def machine_names(order)
    current_wp = find_current_work_process(order.work_processes)
    names = current_wp&.machines&.map(&:name)&.join(', ')
    not_available(names)
  end

  # 受注に関連する稼働状況を取得
  def machine_statuses_for_order(order)
    current_wp = find_current_work_process(order.work_processes)
    assignments = current_wp&.machine_assignments&.includes(:machine_status)
    statuses = assignments.map { |assignment| assignment.machine_status&.name }
    ms_name = statuses.uniq.join(', ')
    not_machine_status(ms_name)
  end

  # 稼働状況を取得
  def machine_statuses(machine)
    current_wp = find_current_work_process(machine.work_processes)
    # 現在の作業工程に関連する MachineAssignment のステータスを追加
    current_statuses = current_wp ? current_wp&.machine_assignments&.map { |a| a.machine_status.name } : []
    # work_process_id が nil の MachineAssignment のステータスを追加
    wp_nil_statuses = machine.machine_assignments
                        .where(work_process_id: nil)
                        .map { |a| a.machine_status.name }
    # 重複を排除し、カンマ区切りで表示
    ms_statuses = (current_statuses + wp_nil_statuses).uniq.join(', ')
    not_machine_status(ms_statuses)
  end

  # 品番を取得
  def product_number(machine)
    current_wp = find_current_work_process(machine.work_processes)
    not_available(current_wp&.order&.product_number&.number)
  end

  # 現在の作業工程名を取得
  def work_process_name(machine)
    current_wp = find_current_work_process(machine.work_processes)
    not_available(current_wp&.work_process_definition&.name)
  end

  # ステータスを取得
  def work_process_status(machine)
    current_wp = find_current_work_process(machine.work_processes)
    not_available(current_wp&.work_process_status&.name)
  end
end
