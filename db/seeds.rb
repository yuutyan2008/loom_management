ActiveRecord::Base.transaction do
  ### 会社データの作成 ###
  companies = [
    { name: 'エルトップ' },
    { name: '機屋A' },
    { name: '機屋B' },
    { name: '機屋C' },
    { name: '機屋D' },
    { name: '機屋E' },
    { name: '機屋F' },
    { name: '機屋G' },
    { name: '機屋H' }
  ]

  companies.each do |company_attrs|
    Company.find_or_create_by!(name: company_attrs[:name])
  end

  ### ユーザーデータの作成 ###
  users = [
    {
      name: '山田太郎',
      email: 'aaa@example.com',
      phone_number: '000-0000-0000',
      company_name: 'エルトップ',
      admin: true,
      password: 'password'
    },
    {
      name: '佐藤花子',
      email: 'bbb@example.com',
      phone_number: '000-0000-0001',
      company_name: '機屋A',
      admin: false,
      password: 'password'
    },
    {
      name: '鈴木一郎',
      email: 'ccc@example.com',
      phone_number: '000-0000-0002',
      company_name: '機屋B',
      admin: false,
      password: 'password'
    },
    {
      name: '大谷翔平',
      email: 'ddd@example.com',
      phone_number: '000-0000-0003',
      company_name: '機屋C',
      admin: false,
      password: 'password'
    },
    {
      name: '田中健',
      email: 'eee@example.com',
      phone_number: '000-0000-0004',
      company_name: '機屋D',
      admin: false,
      password: 'password'
    },
    {
      name: '中村美咲',
      email: 'fff@example.com',
      phone_number: '000-0000-0005',
      company_name: '機屋E',
      admin: false,
      password: 'password'
    },
    {
      name: '小林誠',
      email: 'ggg@example.com',
      phone_number: '000-0000-0006',
      company_name: '機屋F',
      admin: false,
      password: 'password'
    },
    {
      name: '高橋直子',
      email: 'hhh@example.com',
      phone_number: '000-0000-0007',
      company_name: '機屋G',
      admin: false,
      password: 'password'
    },
    {
      name: '伊藤翔',
      email: 'iii@example.com',
      phone_number: '000-0000-0008',
      company_name: '機屋H',
      admin: false,
      password: 'password'
    }
  ]

  users.each do |user_attrs|
    company = Company.find_by!(name: user_attrs.delete(:company_name))
    User.find_or_create_by!(email: user_attrs[:email]) do |u|
      u.name = user_attrs[:name]
      u.phone_number = user_attrs[:phone_number]
      u.company = company
      u.admin = user_attrs[:admin]
      u.password = user_attrs[:password]
      u.password_confirmation = user_attrs[:password]
    end
  end

  ### 品番データの作成 ###
  product_numbers = ['PN-10', 'PN-20', 'PN-30', 'PN-40', 'PN-50']

  product_numbers.each do |pn|
    ProductNumber.find_or_create_by!(number: pn)
  end

  ### 色番データの作成 ###
  color_numbers = ['C-001', 'C-002', 'C-003', 'C-004', 'C-005', 'C-006', 'C-007', 'C-008']

  color_numbers.each do |cn|
    ColorNumber.find_or_create_by!(color_code: cn)
  end

  ### 発注データの作成 ###
  orders = [
    {
      company_name: '機屋A',
      product_number: 'PN-10',
      color_number: 'C-001',
      roll_count: 100,
      quantity: 1000,
      start_date: '2024-12-10'
    },
    {
      company_name: '機屋B',
      product_number: 'PN-30',
      color_number: 'C-003',
      roll_count: 50,
      quantity: 500,
      start_date: '2024-12-10'
    }
    # 他の発注も同様に追加
  ]

  orders.each do |order_attrs|
    company = Company.find_by!(name: order_attrs.delete(:company_name))
    product_number = ProductNumber.find_by!(number: order_attrs.delete(:product_number))
    color_number = ColorNumber.find_by!(color_code: order_attrs.delete(:color_number))

    Order.find_or_create_by!(company: company, product_number: product_number, color_number: color_number, start_date: order_attrs[:start_date]) do |o|
      o.roll_count = order_attrs[:roll_count]
      o.quantity = order_attrs[:quantity]
    end
  end

  ### 織機の種類データの作成 ###
  machine_types = ['ドビー', 'ジャガード']

  machine_types.each do |mt_name|
    MachineType.find_or_create_by!(name: mt_name)
  end

  ### 織機データの作成 ###
  machines = [
    { name: 'A001号機', machine_type: 'ドビー', company_name: '機屋A' },
    { name: 'A002号機', machine_type: 'ドビー', company_name: '機屋A' },
    { name: 'A003号機', machine_type: 'ジャガード', company_name: '機屋A' },
    { name: 'B001号機', machine_type: 'ドビー', company_name: '機屋B' },
    { name: 'B002号機', machine_type: 'ジャガード', company_name: '機屋B' },
    { name: 'C001号機', machine_type: 'ドビー', company_name: '機屋C' },
    { name: 'C002号機', machine_type: 'ドビー', company_name: '機屋C' },
    { name: 'C003号機', machine_type: 'ジャガード', company_name: '機屋C' },
    { name: 'C004号機', machine_type: 'ドビー', company_name: '機屋C' },
    { name: 'D001号機', machine_type: 'ジャガード', company_name: '機屋D' },
    { name: 'D002号機', machine_type: 'ドビー', company_name: '機屋D' },
    { name: 'E001号機', machine_type: 'ドビー', company_name: '機屋E' },
    { name: 'E002号機', machine_type: 'ドビー', company_name: '機屋E' },
    { name: 'F001号機', machine_type: 'ドビー', company_name: '機屋F' },
    { name: 'F002号機', machine_type: 'ジャガード', company_name: '機屋F' },
    { name: 'F003号機', machine_type: 'ドビー', company_name: '機屋F' },
    { name: 'F004号機', machine_type: 'ドビー', company_name: '機屋F' },
    { name: 'H001号機', machine_type: 'ジャガード', company_name: '機屋H' },
    { name: 'H002号機', machine_type: 'ドビー', company_name: '機屋H' },
    { name: 'H003号機', machine_type: 'ジャガード', company_name: '機屋H' },
    # 他の織機も同様に追加
  ]

  machines.each do |machine_attrs|
    machine_type = MachineType.find_by!(name: machine_attrs.delete(:machine_type))
    company = Company.find_by!(name: machine_attrs.delete(:company_name))

    Machine.find_or_create_by!(name: machine_attrs[:name]) do |m|
      m.machine_type = machine_type
      m.company = company
    end
  end

  ### 織機の稼働状況データの作成 ###
  machine_statuses = ['未稼働', '準備中', '稼働中', '故障中']

  machine_statuses.each do |ms_name|
    MachineStatus.find_or_create_by!(name: ms_name)
  end

  ### 作業工程定義データの作成 ###
  work_process_definitions = [
    { name: '糸', sequence: 1 },
    { name: '染色', sequence: 2 },
    { name: '整経', sequence: 3 },
    { name: '製織', sequence: 4 },
    { name: '整理加工', sequence: 5 }
  ]

  work_process_definitions.each do |wpd_attrs|
    WorkProcessDefinition.find_or_create_by!(name: wpd_attrs[:name]) do |wpd|
      wpd.sequence = wpd_attrs[:sequence]
    end
  end

  ### 作業工程ステータスデータの作成 ###
  work_process_statuses = ['作業前', '作業中', '作業完了', '確認中']

  work_process_statuses.each do |wps_name|
    WorkProcessStatus.find_or_create_by!(name: wps_name)
  end

  ### ナレッジデータの作成 ###
  process_estimates = [
    {
      work_process_definition: '糸',
      machine_type: 'ドビー',
      earliest_completion_estimate: 90,
      latest_completion_estimate: 150,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '染色',
      machine_type: 'ドビー',
      earliest_completion_estimate: 14,
      latest_completion_estimate: 21,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '整経',
      machine_type: 'ドビー',
      earliest_completion_estimate: 7,
      latest_completion_estimate: 14,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '製織',
      machine_type: 'ドビー',
      earliest_completion_estimate: 25,
      latest_completion_estimate: 30,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '整理加工',
      machine_type: 'ドビー',
      earliest_completion_estimate: 4,
      latest_completion_estimate: 5,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '糸',
      machine_type: 'ジャガード',
      earliest_completion_estimate: 30,
      latest_completion_estimate: 40,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '染色',
      machine_type: 'ジャガード',
      earliest_completion_estimate: 21,
      latest_completion_estimate: 28,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '整経',
      machine_type: 'ジャガード',
      earliest_completion_estimate: 14,
      latest_completion_estimate: 21,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '製織',
      machine_type: 'ジャガード',
      earliest_completion_estimate: 30,
      latest_completion_estimate: 40,
      update_date: '2024-12-17'
    },
    {
      work_process_definition: '整理加工',
      machine_type: 'ジャガード',
      earliest_completion_estimate: 4,
      latest_completion_estimate: 5,
      update_date: '2024-12-17'
    },
  ]

  process_estimates.each do |pe_attrs|
    work_process_definition = WorkProcessDefinition.find_by!(name: pe_attrs[:work_process_definition])
    machine_type = MachineType.find_by!(name: pe_attrs[:machine_type])

    ProcessEstimate.find_or_create_by!(work_process_definition: work_process_definition, machine_type: machine_type, update_date: pe_attrs[:update_date]) do |pe|
      pe.earliest_completion_estimate = pe_attrs[:earliest_completion_estimate]
      pe.latest_completion_estimate = pe_attrs[:latest_completion_estimate]
    end
  end

  ### 作業工程データの作成 ###
  work_processes = [
    {
      order_id: 1,
      work_process_definition_name: '糸',
      work_process_status_name: '作業中',
      start_date: '2024-12-10',
      earliest_estimated_completion_date: '2025-03-10',
      latest_estimated_completion_date: '2025-03-10',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 1,
      work_process_definition_name: '染色',
      work_process_status_name: '作業前',
      start_date: '2025-03-10',
      earliest_estimated_completion_date: '2025-03-24',
      latest_estimated_completion_date: '2025-03-24',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 1,
      work_process_definition_name: '整経',
      work_process_status_name: '作業前',
      start_date: '2025-03-24',
      earliest_estimated_completion_date: '2025-03-31',
      latest_estimated_completion_date: '2025-03-31',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 1,
      work_process_definition_name: '製織',
      work_process_status_name: '作業前',
      start_date: '2025-03-31',
      earliest_estimated_completion_date: '2025-04-25',
      latest_estimated_completion_date: '2025-04-25',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 1,
      work_process_definition_name: '整理加工',
      work_process_status_name: '作業前',
      start_date: '2025-04-25',
      earliest_estimated_completion_date: '2025-04-29',
      latest_estimated_completion_date: '2025-04-29',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 2,
      work_process_definition_name: '糸',
      work_process_status_name: '作業前',
      start_date: '2024-12-10',
      earliest_estimated_completion_date: '2025-03-10',
      latest_estimated_completion_date: '2025-03-10',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 2,
      work_process_definition_name: '染色',
      work_process_status_name: '作業前',
      start_date: '2025-03-10',
      earliest_estimated_completion_date: '2025-03-24',
      latest_estimated_completion_date: '2025-03-24',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 2,
      work_process_definition_name: '整経',
      work_process_status_name: '作業前',
      start_date: '2025-03-24',
      earliest_estimated_completion_date: '2025-03-31',
      latest_estimated_completion_date: '2025-03-31',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 2,
      work_process_definition_name: '製織',
      work_process_status_name: '作業前',
      start_date: '2025-03-31',
      earliest_estimated_completion_date: '2025-04-25',
      latest_estimated_completion_date: '2025-04-25',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    },
    {
      order_id: 2,
      work_process_definition_name: '整理加工',
      work_process_status_name: '作業前',
      start_date: '2025-04-25',
      earliest_estimated_completion_date: '2025-04-29',
      latest_estimated_completion_date: '2025-04-29',
      factory_estimated_completion_date: nil,
      actual_completion_date: nil
    }
    # 他の作業工程も同様に追加
  ]

  # ProcessEstimate を検索するためのマッピングを作成
  process_estimate_map = {}
  ProcessEstimate.includes(:work_process_definition, :machine_type).find_each do |pe|
    key = "#{pe.work_process_definition.name}_#{pe.machine_type.name}"
    process_estimate_map[key] = pe
  end

  work_processes.each do |wp_attrs|
    order = Order.find(wp_attrs[:order_id])
    work_process_definition = WorkProcessDefinition.find_by!(name: wp_attrs[:work_process_definition_name])
    work_process_status = WorkProcessStatus.find_by!(name: wp_attrs[:work_process_status_name])

    # ProcessEstimate を適切に参照
    key = "#{wp_attrs[:work_process_definition_name]}_#{ProcessEstimate.find_by(work_process_definition: work_process_definition).machine_type.name}"
    process_estimate = process_estimate_map[key]

    WorkProcess.find_or_create_by!(order: order, work_process_definition: work_process_definition, start_date: wp_attrs[:start_date]) do |wp|
      wp.process_estimate = process_estimate
      wp.work_process_status = work_process_status
      wp.earliest_estimated_completion_date = wp_attrs[:earliest_estimated_completion_date]
      wp.latest_estimated_completion_date = wp_attrs[:latest_estimated_completion_date]
      wp.factory_estimated_completion_date = wp_attrs[:factory_estimated_completion_date]
      wp.actual_completion_date = wp_attrs[:actual_completion_date]
    end
  end


  ### 織機割り当てデータの作成 ###
  machine_assignments = [
    { work_process_id: nil, machine_name: 'A001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'A002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'A003号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'B001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'B002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'C001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'C002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'C003号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'C004号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'D001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'D002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'E001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'E002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'F001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'F002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'F003号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'F004号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'H001号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'H002号機', machine_status_name: '未稼働' },
    { work_process_id: nil, machine_name: 'H003号機', machine_status_name: '未稼働' }
  ]

  machine_assignments.each do |ma_attrs|
    work_process = ma_attrs[:work_process_id] ? WorkProcess.find_by(order_id: ma_attrs[:work_process_id]) : nil
    machine = Machine.find_by!(name: ma_attrs[:machine_name])
    machine_status = MachineStatus.find_by!(name: ma_attrs[:machine_status_name])

    MachineAssignment.find_or_create_by!(machine: machine, work_process: work_process) do |ma|
      ma.machine_status = machine_status
    end
  end
end
