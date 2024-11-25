ActiveRecord::Base.transaction do
  # 企業データを作成
  Company.find_or_create_by!(name: 'エルトップ') { |c| c.name = 'エルトップ' }
  Company.find_or_create_by!(name: '機屋A') { |c| c.name = '機屋A' }
  Company.find_or_create_by!(name: '機屋B') { |c| c.name = '機屋B' }
  Company.find_or_create_by!(name: '機屋C') { |c| c.name = '機屋C' }

  # ユーザーデータを作成
  User.find_or_create_by!(name: '山田太郎') do |u|
    u.name = '山田太郎'
    u.email = 'aaa@example.com'
    u.phone_number = '000-0000-0000'
    u.company_id = 1
    u.admin = true
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(name: '佐藤花子') do |u|
    u.name = '佐藤花子'
    u.email = 'bbb@example.com'
    u.phone_number = '000-0000-0001'
    u.company_id = 2
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(name: '鈴木一郎') do |u|
    u.name = '鈴木一郎'
    u.email = 'ccc@example.com'
    u.phone_number = '000-0000-0002'
    u.company_id = 3
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  User.find_or_create_by!(name: '大谷翔平') do |u|
    u.name = '大谷翔平'
    u.email = 'ddd@example.com'
    u.phone_number = '000-0000-0004'
    u.company_id = 4
    u.admin = false
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  # 品番データを作成
  ProductNumber.find_or_create_by!(number: 'PN-10') { |pn| pn.number = 'PN-10' }
  ProductNumber.find_or_create_by!(number: 'PN-20') { |pn| pn.number = 'PN-20' }
  ProductNumber.find_or_create_by!(number: 'PN-30') { |pn| pn.number = 'PN-30' }

  # 色番データを作成
  ColorNumber.find_or_create_by!(color_code: 'C-001') { |cn| cn.color_code = 'C-001' }
  ColorNumber.find_or_create_by!(color_code: 'C-002') { |cn| cn.color_code = 'C-002' }
  ColorNumber.find_or_create_by!(color_code: 'C-003') { |cn| cn.color_code = 'C-003' }
  ColorNumber.find_or_create_by!(color_code: 'C-004') { |cn| cn.color_code = 'C-004' }

  # 発注データを作成
  Order.find_or_create_by!(id: 1) do |o|
    o.company_id = 2
    o.product_number_id = 1
    o.color_number_id = 1
    o.roll_count = 100
    o.quantity = 1000
    o.start_date = '2023-10-01'
  end

  Order.find_or_create_by!(id: 2) do |o|
    o.company_id = 3
    o.product_number_id = 3
    o.color_number_id = 3
    o.roll_count = 50
    o.quantity = 500
    o.start_date = '2023-10-05'
  end

  # 織機の種類データを作成
  MachineType.find_or_create_by!(id: 1) { |mt| mt.name = 'ドビー' }
  MachineType.find_or_create_by!(id: 2) { |mt| mt.name = 'ジャガード' }

  # 織機データを作成
  Machine.find_or_create_by!(id: 1) do |m|
    m.name = '1号機'
    m.machine_type_id = 1
    m.company_id = 2
  end

  Machine.find_or_create_by!(id: 2) do |m|
    m.name = '2号機'
    m.machine_type_id = 1
    m.company_id = 2
  end

  Machine.find_or_create_by!(id: 3) do |m|
    m.name = '3号機'
    m.machine_type_id = 2
    m.company_id = 2
  end

  Machine.find_or_create_by!(id: 4) do |m|
    m.name = '1号機'
    m.machine_type_id = 1
    m.company_id = 3
  end

  Machine.find_or_create_by!(id: 5) do |m|
    m.name = '2号機'
    m.machine_type_id = 2
    m.company_id = 3
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
    wp.work_process_status_id = 3
    wp.start_date = '2023-10-01'
    wp.earliest_estimated_completion_date = '2023-12-30'
    wp.latest_estimated_completion_date = '2023-12-30'
    wp.factory_estimated_completion_date = '2023-10-05'
    wp.actual_completion_date = '2023-10-03'
  end

  WorkProcess.find_or_create_by!(id: 2) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 2
    wp.work_process_definition_id = 2
    wp.work_process_status_id = 2
    wp.start_date = '2023-10-03'
    wp.earliest_estimated_completion_date = '2023-10-17'
    wp.latest_estimated_completion_date = '2023-10-17'
    wp.factory_estimated_completion_date = '2023-10-10'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 3) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 3
    wp.work_process_definition_id = 3
    wp.work_process_status_id = 1
    wp.start_date = '2023-10-05'
    wp.earliest_estimated_completion_date = '2023-10-27'
    wp.latest_estimated_completion_date = '2023-10-27'
    wp.factory_estimated_completion_date = '2023-10-20'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 4) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 4
    wp.work_process_definition_id = 4
    wp.work_process_status_id = 4
    wp.start_date = '2023-10-15'
    wp.earliest_estimated_completion_date = '2023-11-26'
    wp.latest_estimated_completion_date = '2023-11-26'
    wp.factory_estimated_completion_date = '2023-11-01'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 5) do |wp|
    wp.order_id = 1
    wp.process_estimate_id = 5
    wp.work_process_definition_id = 5
    wp.work_process_status_id = 1
    wp.start_date = '2023-10-20'
    wp.earliest_estimated_completion_date = '2023-12-02'
    wp.latest_estimated_completion_date = '2023-12-02'
    wp.factory_estimated_completion_date = '2023-11-28'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 6) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 1
    wp.work_process_definition_id = 1
    wp.work_process_status_id = 3
    wp.start_date = '2023-10-01'
    wp.earliest_estimated_completion_date = '2023-12-30'
    wp.latest_estimated_completion_date = '2023-12-30'
    wp.factory_estimated_completion_date = '2023-10-05'
    wp.actual_completion_date = '2023-10-03'
  end

  WorkProcess.find_or_create_by!(id: 7) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 2
    wp.work_process_definition_id = 2
    wp.work_process_status_id = 2
    wp.start_date = '2023-10-03'
    wp.earliest_estimated_completion_date = '2023-10-17'
    wp.latest_estimated_completion_date = '2023-10-17'
    wp.factory_estimated_completion_date = '2023-10-10'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 8) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 3
    wp.work_process_definition_id = 3
    wp.work_process_status_id = 1
    wp.start_date = '2023-10-05'
    wp.earliest_estimated_completion_date = '2023-10-27'
    wp.latest_estimated_completion_date = '2023-10-27'
    wp.factory_estimated_completion_date = '2023-10-20'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 9) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 4
    wp.work_process_definition_id = 4
    wp.work_process_status_id = 4
    wp.start_date = '2023-10-15'
    wp.earliest_estimated_completion_date = '2023-11-26'
    wp.latest_estimated_completion_date = '2023-11-26'
    wp.factory_estimated_completion_date = '2023-11-01'
    wp.actual_completion_date = '2023-10-10'
  end

  WorkProcess.find_or_create_by!(id: 10) do |wp|
    wp.order_id = 2
    wp.process_estimate_id = 5
    wp.work_process_definition_id = 5
    wp.work_process_status_id = 1
    wp.start_date = '2023-10-20'
    wp.earliest_estimated_completion_date = '2023-12-02'
    wp.latest_estimated_completion_date = '2023-12-02'
    wp.factory_estimated_completion_date = '2023-11-28'
    wp.actual_completion_date = '2023-10-10'
  end

  # 織機割り当てデータを作成（全作業工程を1つの織機に割り当て）
  MachineAssignment.find_or_create_by!(id: 1) do |ma|
    ma.work_process_id = 1
    ma.machine_id = 1
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 2) do |ma|
    ma.work_process_id = 2
    ma.machine_id = 1
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 3) do |ma|
    ma.work_process_id = 3
    ma.machine_id = 1
    ma.machine_status_id = 3 # 稼働中
  end

  MachineAssignment.find_or_create_by!(id: 4) do |ma|
    ma.work_process_id = 4
    ma.machine_id = 1
    ma.machine_status_id = 4 # 確認中（WorkProcessDefinition id:4に対応）
  end

  MachineAssignment.find_or_create_by!(id: 5) do |ma|
    ma.work_process_id = 5
    ma.machine_id = 1
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 6) do |ma|
    ma.work_process_id = 6
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end

  MachineAssignment.find_or_create_by!(id: 7) do |ma|
    ma.work_process_id = 7
    ma.machine_id = 4
    ma.machine_status_id = 2 # 準備中
  end

  MachineAssignment.find_or_create_by!(id: 8) do |ma|
    ma.work_process_id = 8
    ma.machine_id = 4
    ma.machine_status_id = 3 # 稼働中
  end

  MachineAssignment.find_or_create_by!(id: 9) do |ma|
    ma.work_process_id = 9
    ma.machine_id = 4
    ma.machine_status_id = 4 # 確認中（WorkProcessDefinition id:4に対応）
  end

  MachineAssignment.find_or_create_by!(id: 10) do |ma|
    ma.work_process_id = 10
    ma.machine_id = 4
    ma.machine_status_id = 1 # 未稼働
  end
end
