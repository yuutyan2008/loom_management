require 'rails_helper'

RSpec.describe MachineAssignment, type: :model do
  describe '織機選択時のバリデーション' do
    let!(:company) { Company.create!(name: 'Test Company') }
    let!(:machine_type_dobby) { MachineType.create!(name: 'ドビー') }
    let!(:machine_type_jacquard) { MachineType.create!(name: 'ジャガード') }

    let!(:machine_1) { Machine.create!(name: 'Machine A', machine_type: machine_type_dobby, company: company) }
    let!(:machine_2) { Machine.create!(name: 'Machine B', machine_type: machine_type_jacquard, company: company) }

    let!(:status_available) { MachineStatus.create!(id: 1, name: '未稼働') }
    let!(:status_faulty) { MachineStatus.create!(id: 4, name: '故障中') }

    let!(:order) { Order.create!(company: company, product_number: ProductNumber.create!(number: 'PN-12345'), color_number: ColorNumber.create!(color_code: '#FFFFFF'), roll_count: 10, quantity: 100) }

    let!(:work_process) do
      WorkProcess.create!(
        order: order,
        work_process_definition: WorkProcessDefinition.create!(name: '製織', sequence: 4),
        work_process_status: WorkProcessStatus.create!(name: '作業中'),
        start_date: Date.today
      )
    end

    let!(:process_estimate) do
      ProcessEstimate.create!(
        work_process_definition: work_process.work_process_definition,
        machine_type: machine_type_dobby,
        earliest_completion_estimate: 10,
        latest_completion_estimate: 15,
        update_date: Date.today
      )
    end

    before do
      work_process.update!(process_estimate: process_estimate)
    end

    context '有効な選択の場合' do
      it '織機の選択が有効である' do
        machine_assignment = MachineAssignment.new(
          work_process: work_process,
          machine: machine_1,
          machine_status: status_available
        )
        expect(machine_assignment).to be_valid
      end
    end

    context '無効な選択の場合' do
      it '異なる織機タイプを選択した場合、エラーとなる' do
        machine_assignment = MachineAssignment.new(
          work_process: work_process,
          machine: machine_2,
          machine_status: status_available
        )
        expect(machine_assignment).not_to be_valid
      end

      it '選択した織機が他の未完了の受注で使用中の場合、エラーとなる' do
        other_order = Order.create!(
          company: company,
          product_number: ProductNumber.create!(number: 'PN-54321'),
          color_number: ColorNumber.create!(color_code: '#000000'),
          roll_count: 5,
          quantity: 50
        )

        other_work_process = WorkProcess.create!(
          order: other_order,
          work_process_definition: WorkProcessDefinition.create!(name: '整経', sequence: 3),
          work_process_status: WorkProcessStatus.create!(name: '作業中'),
          start_date: Date.today,
          process_estimate: process_estimate
        )

        MachineAssignment.create!(work_process: other_work_process, machine: machine_1, machine_status: status_available)

        machine_assignment = MachineAssignment.new(
          work_process: work_process,
          machine: machine_1,
          machine_status: status_available
        )

        expect(machine_assignment).not_to be_valid
      end

      it '選択した織機が故障中の場合、エラーとなる' do
        MachineAssignment.create!(work_process: work_process, machine: machine_1, machine_status: status_faulty)

        machine_assignment = MachineAssignment.new(
          work_process: work_process,
          machine: machine_1,
          machine_status: status_faulty
        )

        expect(machine_assignment).not_to be_valid
      end
    end
  end
end
