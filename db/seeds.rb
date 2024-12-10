ActiveRecord::Base.transaction do
  # 企業データを作成
  Company.find_or_create_by!(id: 1) { |c| c.name = 'エルトップ' }
  Company.find_or_create_by!(id: 2) { |c| c.name = '機屋A' }
  Company.find_or_create_by!(id: 3) { |c| c.name = '機屋B' }
  Company.find_or_create_by!(id: 4) { |c| c.name = '機屋C' }
  Company.find_or_create_by!(id: 5) { |c| c.name = '機屋D' }
  Company.find_or_create_by!(id: 6) { |c| c.name = '機屋E' }
  Company.find_or_create_by!(id: 7) { |c| c.name = '機屋F' }
  Company.find_or_create_by!(id: 8) { |c| c.name = '機屋G' }
  Company.find_or_create_by!(id: 9) { |c| c.name = '機屋H' }

  # ユーザーデータを作成
  User.find_or_create_by!(id: 1) do |u|
    u.name = '山田太郎'
    u.email = 'aaa@example.com'
    u.phone_number = '000-0000-0000'
    u.company_id = 1
    u.admin = true
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 2) do |u|
    u.name = '佐藤花子'
    u.email = 'bbb@example.com'
    u.phone_number = '000-0000-0001'
    u.company_id = 2
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 3) do |u|
    u.name = '鈴木一郎'
    u.email = 'ccc@example.com'
    u.phone_number = '000-0000-0002'
    u.company_id = 3
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 4) do |u|
    u.name = '大谷翔平'
    u.email = 'ddd@example.com'
    u.phone_number = '000-0000-0004'
    u.company_id = 4
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 5) do |u|
    u.name = '田中健'
    u.email = 'eee@example.com'
    u.phone_number = '000-0000-0005'
    u.company_id = 5
    u.admin = true
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 6) do |u|
    u.name = '中村美咲'
    u.email = 'fff@example.com'
    u.phone_number = '000-0000-0006'
    u.company_id = 6
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 7) do |u|
    u.name = '小林誠'
    u.email = 'ggg@example.com'
    u.phone_number = '000-0000-0007'
    u.company_id = 7
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 8) do |u|
    u.name = '高橋直子'
    u.email = 'hhh@example.com'
    u.phone_number = '000-0000-0008'
    u.company_id = 8
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(id: 9) do |u|
    u.name = '伊藤翔'
    u.email = 'iii@example.com'
    u.phone_number = '000-0000-0009'
    u.company_id = 9
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  # 品番データを作成
  ProductNumber.find_or_create_by!(id: 1) { |pn| pn.number = 'PN-10' }
  ProductNumber.find_or_create_by!(id: 2) { |pn| pn.number = 'PN-20' }
  ProductNumber.find_or_create_by!(id: 3) { |pn| pn.number = 'PN-30' }
  ProductNumber.find_or_create_by!(id: 4) { |pn| pn.number = 'PN-40' }
  ProductNumber.find_or_create_by!(id: 5) { |pn| pn.number = 'PN-50' }

  # 色番データを作成
  ColorNumber.find_or_create_by!(id: 1) { |cn| cn.color_code = 'C-001' }
  ColorNumber.find_or_create_by!(id: 2) { |cn| cn.color_code = 'C-002' }
  ColorNumber.find_or_create_by!(id: 3) { |cn| cn.color_code = 'C-003' }
  ColorNumber.find_or_create_by!(id: 4) { |cn| cn.color_code = 'C-004' }
  ColorNumber.find_or_create_by!(id: 5) { |cn| cn.color_code = 'C-005' }
  ColorNumber.find_or_create_by!(id: 6) { |cn| cn.color_code = 'C-006' }
  ColorNumber.find_or_create_by!(id: 7) { |cn| cn.color_code = 'C-007' }
  ColorNumber.find_or_create_by!(id: 8) { |cn| cn.color_code = 'C-008' }

  # 発注データを作成
  Order.find_or_create_by!(id: 1) do |o|
    o.company_id = 2
    o.product_number_id = 1
    o.color_number_id = 1
    o.roll_count = 100
    o.quantity = 1000
    o.start_date = '2024-12-10'
  end

  Order.find_or_create_by!(id: 2) do |o|
    o.company_id = 3
    o.product_number_id = 3
    o.color_number_id = 3
    o.roll_count = 50
    o.quantity = 500
    o.start_date = '2024-12-10'
  end

  # 織機の種類データを作成
  MachineType.find_or_create_by!(id: 1) { |mt| mt.name = 'ドビー' }
  MachineType.find_or_create_by!(id: 2) { |mt| mt.name = 'ジャガード' }

  # 織機データを作成
  Machine.find_or_create_by!(id: 1) do |m|
    m.name = 'A001号機'
    m.machine_type_id = 1
    m.company_id = 2
  end

  Machine.find_or_create_by!(id: 2) do |m|
    m.name = 'A002号機'
    m.machine_type_id = 1
    m.company_id = 2
  end

  Machine.find_or_create_by!(id: 3) do |m|
    m.name = 'A003号機'
    m.machine_type_id = 2
    m.company_id = 2
  end

  Machine.find_or_create_by!(id: 4) do |m|
    m.name = 'B001号機'
    m.machine_type_id = 1
    m.company_id = 3
  end

  Machine.find_or_create_by!(id: 5) do |m|
    m.name = 'B002号機'
    m.machine_type_id = 2
    m.company_id = 3
  end

  Machine.find_or_create_by!(id: 6) do |m|
    m.name = 'C001号機'
    m.machine_type_id = 1
    m.company_id = 4
  end

  Machine.find_or_create_by!(id: 7) do |m|
    m.name = 'C002号機'
    m.machine_type_id = 1
    m.company_id = 4
  end

  Machine.find_or_create_by!(id: 8) do |m|
    m.name = 'C003号機'
    m.machine_type_id = 2
    m.company_id = 4
  end

  Machine.find_or_create_by!(id: 9) do |m|
    m.name = 'C004号機'
    m.machine_type_id = 1
    m.company_id = 4
  end

  Machine.find_or_create_by!(id: 10) do |m|
    m.name = 'D001号機'
    m.machine_type_id = 2
    m.company_id = 5
  end

  Machine.find_or_create_by!(id: 11) do |m|
    m.name = 'D002号機'
    m.machine_type_id = 1
    m.company_id = 5
  end

  Machine.find_or_create_by!(id: 12) do |m|
    m.name = 'E001号機'
    m.machine_type_id = 1
    m.company_id = 6
  end

  Machine.find_or_create_by!(id: 13) do |m|
    m.name = 'E002号機'
    m.machine_type_id = 2
    m.company_id = 6
  end

  Machine.find_or_create_by!(id: 14) do |m|
    m.name = 'F001号機'
    m.machine_type_id = 1
    m.company_id = 7
  end

  Machine.find_or_create_by!(id: 15) do |m|
    m.name = 'F002号機'
    m.machine_type_id = 2
    m.company_id = 7
  end

  Machine.find_or_create_by!(id: 16) do |m|
    m.name = 'F003号機'
    m.machine_type_id = 1
    m.company_id = 7
  end

  Machine.find_or_create_by!(id: 17) do |m|
    m.name = 'F004号機'
    m.machine_type_id = 1
    m.company_id = 7
  end

  Machine.find_or_create_by!(id: 18) do |m|
    m.name = 'H001号機'
    m.machine_type_id = 2
    m.company_id = 9
  end

  Machine.find_or_create_by!(id: 19) do |m|
    m.name = 'H002号機'
    m.machine_type_id = 1
    m.company_id = 9
  end

  Machine.find_or_create_by!(id: 20) do |m|
    m.name = 'H003号機'
    m.machine_type_id = 2
    m.company_id = 9
  end

  # 織機の稼働状況データを作成
  MachineStatus.find_or_create_by!(id: 1) { |ms| ms.name = '未稼働' }
  MachineStatus.find_or_create_by!(id: 2) { |ms| ms.name = '準備中' }
  MachineStatus.find_or_create_by!(id: 3) { |ms| ms.name = '稼働中' }
  MachineStatus.find_or_create_by!(id: 4) { |ms| ms.name = '故障中' }

  # 作業工程定義データを作成
  WorkProcessDefinition.find_or_create_by!(id: 1) { |wpd| wpd.name = '糸'; wpd.sequence = 1 }
  WorkProcessDefinition.find_or_create_by!(id: 2) { |wpd| wpd.name = '染色'; wpd.sequence = 2 }
  WorkProcessDefinition.find_or_create_by!(id: 3) { |wpd| wpd.name = '整経'; wpd.sequence = 3 }
  WorkProcessDefinition.find_or_create_by!(id: 4) { |wpd| wpd.name = '製織'; wpd.sequence = 4 }
  WorkProcessDefinition.find_or_create_by!(id: 5) { |wpd| wpd.name = '整理加工'; wpd.sequence = 5 }

  # 作業工程ステータスデータを作成
  WorkProcessStatus.find_or_create_by!(id: 1) { |wps| wps.name = '作業前' }
  WorkProcessStatus.find_or_create_by!(id: 2) { |wps| wps.name = '作業中' }
  WorkProcessStatus.find_or_create_by!(id: 3) { |wps| wps.name = '作業完了' }
  WorkProcessStatus.find_or_create_by!(id: 4) { |wps| wps.name = '確認中' }

  # ナレッジデータを作成
  ProcessEstimate.find_or_create_by!(id: 1) do |pe|
    pe.work_process_definition_id = 1
    pe.machine_type_id = 1
    pe.earliest_completion_estimate = 90
    pe.latest_completion_estimate = 150
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 2) do |pe|
    pe.work_process_definition_id = 2
    pe.machine_type_id = 1
    pe.earliest_completion_estimate = 14
    pe.latest_completion_estimate = 21
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 3) do |pe|
    pe.work_process_definition_id = 3
    pe.machine_type_id = 1
    pe.earliest_completion_estimate = 7
    pe.latest_completion_estimate = 14
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 4) do |pe|
    pe.work_process_definition_id = 4
    pe.machine_type_id = 1
    pe.earliest_completion_estimate = 25
    pe.latest_completion_estimate = 30
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 5) do |pe|
    pe.work_process_definition_id = 5
    pe.machine_type_id = 1
    pe.earliest_completion_estimate = 4
    pe.latest_completion_estimate = 5
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 6) do |pe|
    pe.work_process_definition_id = 1
    pe.machine_type_id = 2
    pe.earliest_completion_estimate = 30
    pe.latest_completion_estimate = 40
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 7) do |pe|
    pe.work_process_definition_id = 2
    pe.machine_type_id = 2
    pe.earliest_completion_estimate = 21
    pe.latest_completion_estimate = 28
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 8) do |pe|
    pe.work_process_definition_id = 3
    pe.machine_type_id = 2
    pe.earliest_completion_estimate = 14
    pe.latest_completion_estimate = 21
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 9) do |pe|
    pe.work_process_definition_id = 4
    pe.machine_type_id = 2
    pe.earliest_completion_estimate = 30
    pe.latest_completion_estimate = 40
    pe.update_date = '2024-12-01'
  end

  ProcessEstimate.find_or_create_by!(id: 10) do |pe|
    pe.work_process_definition_id = 5
    pe.machine_type_id = 2
    pe.earliest_completion_estimate = 4
    pe.latest_completion_estimate = 5
    pe.update_date = '2024-12-01'
  end

  # 作業工程データを作成
  WorkProcess.find_or_create_by!(id: 1) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 1
    wp.work_process_definition_id = 1
    wp.work_process_status_id = 2
    wp.start_date = '2024-12-10'
    wp.earliest_estimated_completion_date = '2025-03-10'
    wp.latest_estimated_completion_date = '2025-03-10'
    wp.factory_estimated_completion_date = '2024-12-15'
    wp.actual_completion_date = '2025-03-10'
  end

  WorkProcess.find_or_create_by!(id: 2) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 2
    wp.work_process_definition_id = 2
    wp.work_process_status_id = 2
    wp.start_date = '2025-03-10'
    wp.earliest_estimated_completion_date = '2025-03-24'
    wp.latest_estimated_completion_date = '2025-03-24'
    wp.factory_estimated_completion_date = '2025-03-15'
    wp.actual_completion_date = '2025-03-24'
  end

  WorkProcess.find_or_create_by!(id: 3) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 3
    wp.work_process_definition_id = 3
    wp.work_process_status_id = 2
    wp.start_date = '2025-03-24'
    wp.earliest_estimated_completion_date = '2025-03-31'
    wp.latest_estimated_completion_date = '2025-03-31'
    wp.factory_estimated_completion_date = '2025-03-29'
    wp.actual_completion_date = '2025-03-31'
  end

  WorkProcess.find_or_create_by!(id: 4) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 4
    wp.work_process_definition_id = 4
    wp.work_process_status_id = 2
    wp.start_date = '2025-03-31'
    wp.earliest_estimated_completion_date = '2025-04-25'
    wp.latest_estimated_completion_date = '2025-04-25'
    wp.factory_estimated_completion_date = '2025-04-05'
    wp.actual_completion_date = '2025-04-25'
  end

  WorkProcess.find_or_create_by!(id: 5) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 5
    wp.work_process_definition_id = 5
    wp.work_process_status_id = 2
    wp.start_date = '2025-04-25'
    wp.earliest_estimated_completion_date = '2025-04-29'
    wp.latest_estimated_completion_date = '2025-04-29'
    wp.factory_estimated_completion_date = '2025-04-30'
    wp.actual_completion_date = '2025-04-29'
  end

  # Order ID: 2
  WorkProcess.find_or_create_by!(id: 6) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 6
    wp.work_process_definition_id = 1
    wp.work_process_status_id = 1
    wp.start_date = '2024-09-01'
    wp.earliest_estimated_completion_date = '2024-10-01'
    wp.latest_estimated_completion_date = '2024-10-01'
    wp.factory_estimated_completion_date = '2024-09-06'
    wp.actual_completion_date = '2024-10-01'
  end

  WorkProcess.find_or_create_by!(id: 7) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 7
    wp.work_process_definition_id = 2
    wp.work_process_status_id = 1
    wp.start_date = '2024-10-01'
    wp.earliest_estimated_completion_date = '2024-10-22'
    wp.latest_estimated_completion_date = '2024-10-22'
    wp.factory_estimated_completion_date = '2024-10-06'
    wp.actual_completion_date = '2024-10-22'
  end

  WorkProcess.find_or_create_by!(id: 8) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 8
    wp.work_process_definition_id = 3
    wp.work_process_status_id = 1
    wp.start_date = '2024-10-22'
    wp.earliest_estimated_completion_date = '2024-11-05'
    wp.latest_estimated_completion_date = '2024-11-05'
    wp.factory_estimated_completion_date = '2024-10-27'
    wp.actual_completion_date = '2024-11-05'
  end

  WorkProcess.find_or_create_by!(id: 9) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 9
    wp.work_process_definition_id = 4
    wp.work_process_status_id = 1
    wp.start_date = '2024-11-05'
    wp.earliest_estimated_completion_date = '2024-12-05'
    wp.latest_estimated_completion_date = '2024-12-05'
    wp.factory_estimated_completion_date = '2024-11-10'
    wp.actual_completion_date = '2024-12-05'
  end

  WorkProcess.find_or_create_by!(id: 10) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 10
    wp.work_process_definition_id = 5
    wp.work_process_status_id = 1
    wp.start_date = '2024-12-05'
    wp.earliest_estimated_completion_date = '2024-12-09'
    wp.latest_estimated_completion_date = '2024-12-09'
    wp.factory_estimated_completion_date = '2024-12-10'
    wp.actual_completion_date = '2024-12-09'
  end

  # 織機割り当てデータを作成（全作業工程を1つの織機に割り当て）
  MachineAssignment.find_or_create_by!(id: 1) do |ma|
    ma.work_process_id = 1
    ma.machine_id = 1
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 2) do |ma|
    ma.work_process_id = 2
    ma.machine_id = 1
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 3) do |ma|
    ma.work_process_id = 3
    ma.machine_id = 1
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 4) do |ma|
    ma.work_process_id = 4
    ma.machine_id = 1
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 5) do |ma|
    ma.work_process_id = 5
    ma.machine_id = 1
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 6) do |ma|
    ma.work_process_id = 6
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 7) do |ma|
    ma.work_process_id = 7
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 8) do |ma|
    ma.work_process_id = 8
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 9) do |ma|
    ma.work_process_id = 9
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 10) do |ma|
    ma.work_process_id = 10
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 11) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 2
    ma.machine_status_id = 4 # 故障中
  end

  MachineAssignment.find_or_create_by!(id: 12) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 3
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 13) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 5
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 14) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 6
    ma.machine_status_id = 4 # 故障中
  end

  MachineAssignment.find_or_create_by!(id: 15) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 7
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 16) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 8
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 17) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 9
    ma.machine_status_id = 4 # 故障中
  end

  MachineAssignment.find_or_create_by!(id: 18) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 10
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 19) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 11
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 20) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 12
    ma.machine_status_id = 4 # 故障中
  end

  MachineAssignment.find_or_create_by!(id: 21) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 13
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 22) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 14
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 23) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 15
    ma.machine_status_id = 4 # 故障中
  end

  MachineAssignment.find_or_create_by!(id: 24) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 16
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 25) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 17
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 26) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 18
    ma.machine_status_id = 4 # 故障中
  end

  MachineAssignment.find_or_create_by!(id: 27) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 19
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 28) do |ma|
    ma.work_process_id = nil
    ma.machine_id = 20
    ma.machine_status_id = 1 # 未稼働
  end
end
