module ApplicationHelper
  # 現在作業中の作業工程を取得するヘルパーメソッド
  def find_current_work_process(work_processes)
    # order.rbのcurrent_work_processと同様のロジックに変更
    processes = work_processes.joins(:work_process_status)

    latest_completed = processes.where(work_process_statuses: { name: '作業完了' }).reorder(work_process_definition_id: :desc).first

    if latest_completed
      # 次の工程ID = 最新完了工程のID + 1
      next_definition_id = latest_completed.work_process_definition_id + 1
      # その工程IDで検索
      processes.where(work_process_definition_id: next_definition_id).first
    else
      # 完了工程がない場合、最初の工程（ID=1）を取得
      processes.where(work_process_definition_id: 1).first
    end
  end

  def not_available(value)
    value.presence || 'ー'
  end

  def not_machine_status(value)
    value.presence || '未稼働'
  end

  # 共通的に現在のワークプロセスを取得するメソッド
  def current_work_process_from(work_processes)
    find_current_work_process(work_processes)
  end

  # machineからorder.work_processesを取得し、共通処理を行うためのヘルパー
  def with_order_work_processes_from_machine(machine)
    current_wp = current_work_process_from(machine.work_processes)
    order = current_wp&.order
    if order
      yield(order.work_processes)
    else
      not_available(nil)
    end
  end

  # ---- 共通ロジックを定義したメソッド群 ----
  def work_process_name_from_processes(work_processes)
    current_wp = current_work_process_from(work_processes)
    not_available(current_wp&.work_process_definition&.name)
  end

  def work_process_status_from_processes(work_processes)
    current_wp = current_work_process_from(work_processes)
    not_available(current_wp&.work_process_status&.name)
  end

  def work_process_start_date_from_processes(work_processes)
    current_wp = current_work_process_from(work_processes)
    not_available(current_wp&.start_date)
  end

  def work_process_factory_estimated_completion_date_from_processes(work_processes)
    current_wp = current_work_process_from(work_processes)
    not_available(current_wp&.factory_estimated_completion_date)
  end

  def machine_names_from_processes(work_processes)
    current_wp = current_work_process_from(work_processes)
    names = current_wp&.machines&.map(&:name)&.join(', ')
    not_available(names)
  end

  def machine_statuses_from_processes(work_processes)
    current_wp = current_work_process_from(work_processes)
    assignments = current_wp&.machine_assignments&.includes(:machine_status)
    statuses = assignments.map { |assignment| assignment&.machine_status&.name }
    ms_name = statuses.uniq.join(', ')
    not_machine_status(ms_name)
  end

  # ---- 既存のorder向けメソッド ----
  def work_process_name(order)
    work_process_name_from_processes(order.work_processes)
  end

  def work_process_status(order)
    work_process_status_from_processes(order.work_processes)
  end

  def work_process_start_date(order)
    work_process_start_date_from_processes(order.work_processes)
  end

  def work_process_factory_estimated_completion_date(order)
    work_process_factory_estimated_completion_date_from_processes(order.work_processes)
  end

  def machine_names(order)
    machine_names_from_processes(order.work_processes)
  end

  def machine_statuses_for_order(order)
    machine_statuses_from_processes(order.work_processes)
  end

  # ---- machine向けメソッド ----
  # machineからorder.work_processesを経由して共通処理を使う
  def work_process_name(machine)
    with_order_work_processes_from_machine(machine) do |order_wps|
      work_process_name_from_processes(order_wps)
    end
  end

  def work_process_status(machine)
    with_order_work_processes_from_machine(machine) do |order_wps|
      work_process_status_from_processes(order_wps)
    end
  end

  def work_process_start_date(machine)
    with_order_work_processes_from_machine(machine) do |order_wps|
      work_process_start_date_from_processes(order_wps)
    end
  end

  def work_process_factory_estimated_completion_date(machine)
    with_order_work_processes_from_machine(machine) do |order_wps|
      work_process_factory_estimated_completion_date_from_processes(order_wps)
    end
  end

  def machine_names(machine)
    with_order_work_processes_from_machine(machine) do |order_wps|
      machine_names_from_processes(order_wps)
    end
  end

  def machine_statuses(machine)
    with_order_work_processes_from_machine(machine) do |order_wps|
      machine_statuses_from_processes(order_wps)
    end
  end

  # # 受注の現在の作業工程名を取得
  # def work_process_name(order)
  #   current_wp = find_current_work_process(order.work_processes)
  #   not_available(current_wp&.work_process_definition&.name)
  # end

  # # 受注の現在のステータスを取得
  # def work_process_status(order)
  #   current_wp = find_current_work_process(order.work_processes)
  #   not_available(current_wp&.work_process_status&.name)
  # end

  # # 受注の開始日を取得
  # def work_process_start_date(order)
  #   current_wp = find_current_work_process(order.work_processes)
  #   not_available(current_wp&.start_date)
  # end

  # # 受注の完了予定日を取得
  # def work_process_factory_estimated_completion_date(order)
  #   current_wp = find_current_work_process(order.work_processes)
  #   not_available(current_wp&.factory_estimated_completion_date)
  # end

  # # 受注に関連する織機の名前を取得
  # def machine_names(order)
  #   current_wp = find_current_work_process(order.work_processes)
  #   names = current_wp&.machines&.map(&:name)&.join(', ')
  #   not_available(names)
  # end

  # # 受注に関連する稼働状況を取得
  # def machine_statuses_for_order(order)
  #   current_wp = find_current_work_process(order.work_processes)
  #   assignments = current_wp&.machine_assignments&.includes(:machine_status)
  #   statuses = assignments.map { |assignment| assignment&.machine_status&.name }
  #   ms_name = statuses.uniq.join(', ')
  #   not_machine_status(ms_name)
  # end

  # # 稼働状況を取得
  # def machine_statuses(machine)
  #   current_wp = find_current_work_process(machine.work_processes)
  #   # 現在の作業工程に関連する MachineAssignment のステータスを追加
  #   current_statuses = current_wp ? current_wp&.machine_assignments&.map { |a| a.machine_status.name } : []
  #   # work_process_id が nil の MachineAssignment のステータスを追加
  #   wp_nil_statuses = machine.machine_assignments
  #                       .where(work_process_id: nil)
  #                       .map { |a| a.machine_status.name }
  #   # 重複を排除し、カンマ区切りで表示
  #   ms_statuses = (current_statuses + wp_nil_statuses).uniq.join(', ')
  #   not_machine_status(ms_statuses)
  # end

  # 品番を取得
  def product_number(machine)
    current_wp = find_current_work_process(machine.work_processes)
    not_available(current_wp&.order&.product_number&.number)
  end

  # # 現在の作業工程名を取得
  # def work_process_name(machine)
  #   # machine.work_processes から現在の作業工程を取得
  #   current_wp = find_current_work_process(machine.work_processes)

  #   # current_wp が存在するなら、そこから order を取得し、
  #   # order.work_processes を用いる work_process_name(order) を再利用
  #   if current_wp
  #     order = current_wp.order
  #     return work_process_name(order) if order.present?
  #   end
  #   # current_wp が取得できない、もしくは order が取得できない場合はデフォルト表示
  #   not_available(nil)
  # end

  # # ステータスを取得
  # def work_process_status(machine)
  #   current_wp = find_current_work_process(machine.work_processes)
  #   not_available(current_wp&.work_process_status&.name)
  # end
end
