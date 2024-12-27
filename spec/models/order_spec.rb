require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "新規作成時のバリデーション" do
    let!(:company) { Company.create!(name: "Test Company") }
    let!(:product_number) { ProductNumber.create!(number: "PN-12345") }
    let!(:color_number) { ColorNumber.create!(color_code: "#FFFFFF") }
    let!(:work_process_definition) { WorkProcessDefinition.create!(name: "糸", sequence: 1) }
    let!(:work_process_status) { WorkProcessStatus.create!(name: "作業前") }

    context "すべての必須項目が揃っている場合" do
      it "バリデーションに成功する" do
        order = Order.new(
          company: company,
          product_number: product_number,
          color_number: color_number,
          roll_count: 10,
          quantity: 100
        )
        order.work_processes.build(
          work_process_definition: work_process_definition,
          work_process_status: work_process_status,
          start_date: Date.today
        )

        expect(order).to be_valid
      end
    end

    context "必須項目が不足している場合" do
      it "バリデーションに失敗する" do
        order = Order.new(
          company: nil, # companyが不足
          product_number: product_number,
          color_number: color_number,
          roll_count: 10,
          quantity: 100
        )
        expect(order).not_to be_valid
        expect(order.errors[:company]).to include("must exist")
      end
    end
  end
end


  RSpec.describe "Order 更新フォームのテスト", type: :system do
    before do
      # 必要なマスターデータをセットアップ
      company1 = Company.create!(id: 1, name: "エルトップ")
      company2 = Company.create!(id: 2, name: "機屋A")

      product_number1 = ProductNumber.create!(id: 1, number: "PN-10")
      product_number2 = ProductNumber.create!(id: 3, number: "PN-30")

      color_number1 = ColorNumber.create!(id: 1, color_code: "C-001")
      color_number2 = ColorNumber.create!(id: 3, color_code: "C-003")

      machine_type1 = MachineType.create!(id: 1, name: "ドビー")
      machine_type2 = MachineType.create!(id: 2, name: "ジャガード")

      machine1 = Machine.create!(id: 1, name: "1号機", machine_type: machine_type1, company: company2)
      machine2 = Machine.create!(id: 2, name: "2号機", machine_type: machine_type1, company: company2)
      machine3 = Machine.create!(id: 3, name: "3号機", machine_type: machine_type2, company: company2)

      machine_status1 = MachineStatus.create!(id: 1, name: "未稼働")
      machine_status2 = MachineStatus.create!(id: 2, name: "準備中")
      machine_status3 = MachineStatus.create!(id: 3, name: "稼働中")

      work_process_definitions = [
        { id: 1, name: "糸", sequence: 1 },
        { id: 2, name: "染色", sequence: 2 }
      ].map { |attrs| WorkProcessDefinition.create!(attrs) }

      process_estimates = [
        { id: 1, work_process_definition_id: 1, machine_type_id: 1, earliest_completion_estimate: 90, latest_completion_estimate: 150, update_date: "2024-12-01" },
        { id: 2, work_process_definition_id: 2, machine_type_id: 1, earliest_completion_estimate: 14, latest_completion_estimate: 21, update_date: "2024-12-01" },
        { id: 6, work_process_definition_id: 1, machine_type_id: 2, earliest_completion_estimate: 30, latest_completion_estimate: 40, update_date: "2024-12-01" },
        { id: 7, work_process_definition_id: 2, machine_type_id: 2, earliest_completion_estimate: 21, latest_completion_estimate: 28, update_date: "2024-12-01" }
      ].map { |attrs| ProcessEstimate.create!(attrs) }

      work_process_statuses = [
        { id: 1, name: "作業前" },
        { id: 2, name: "作業中" },
        { id: 3, name: "作業完了" }
      ].map { |attrs| WorkProcessStatus.create!(attrs) }

      # 発注データと関連する作業工程をセットアップ
      @order1 = Order.create!(id: 1, company: company1, product_number: product_number1, color_number: color_number1, roll_count: 100, quantity: 1000)
      @order2 = Order.create!(id: 2, company: company2, product_number: product_number2, color_number: color_number2, roll_count: 50, quantity: 500)

      work_processes = [
        { id: 1, order: @order1, process_estimate_id: 1, work_process_definition_id: 1, work_process_status_id: 3, start_date: "2023-10-01", earliest_estimated_completion_date: "2023-12-30", latest_estimated_completion_date: "2023-12-30", factory_estimated_completion_date: "2023-10-05", actual_completion_date: "2023-10-03" },
        { id: 2, order: @order1, process_estimate_id: 2, work_process_definition_id: 2, work_process_status_id: 2, start_date: "2023-10-03", earliest_estimated_completion_date: "2023-10-17", latest_estimated_completion_date: "2023-10-17", factory_estimated_completion_date: "2023-10-10", actual_completion_date: nil },
        { id: 6, order: @order2, process_estimate_id: 6, work_process_definition_id: 1, work_process_status_id: 3, start_date: "2023-10-05", earliest_estimated_completion_date: "2023-12-15", latest_estimated_completion_date: "2023-12-15", factory_estimated_completion_date: "2023-10-10", actual_completion_date: "2023-10-10" }
      ].map { |attrs| WorkProcess.create!(attrs) }

      machine_assignments = [
        { id: 1, work_process_id: 1, machine_id: 1, machine_status_id: 1 },
        { id: 2, work_process_id: 2, machine_id: 1, machine_status_id: 2 },
        { id: 3, work_process_id: 6, machine_id: 2, machine_status_id: 3 }
      ].map { |attrs| MachineAssignment.create!(attrs) }
    end

    it "発注と関連データが正しく作成されている" do
      expect(Order.count).to eq(2)
      expect(WorkProcess.count).to eq(3)
      expect(MachineAssignment.count).to eq(3)
    end

    it "発注データを更新する" do
      @order1.update!(roll_count: 120, quantity: 1100)
      expect(@order1.roll_count).to eq(120)
      expect(@order1.quantity).to eq(1100)
    end
  end

