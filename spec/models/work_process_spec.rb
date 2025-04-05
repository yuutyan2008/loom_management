require 'rails_helper'

RSpec.describe WorkProcess, type: :model do

  describe 'associations' do
    it { should belong_to(:work_process_status) }
    it { should belong_to(:order) }
    it { should belong_to(:process_estimate).optional }
  end

  describe 'validations' do
    subject { build(:work_process) }

    it { is_expected.to validate_presence_of(:start_date) }

    context 'process_estimate が nil の場合' do
      it 'レコードが有効であること' do
        subject.process_estimate = nil
        expect(subject).to be_valid
      end
    end
  end

  describe 'initial_processes_list' do
    it '正しい初期値を持つ配列を返す' do
      start_date = Date.today
      result = WorkProcess.initial_processes_list(start_date)

      expect(result).to be_an(Array)
      expect(result.size).to eq(5)
      expect(result.first[:start_date]).to eq(start_date)
      expect(result.first[:process_estimate_id]).to be_nil
    end
  end

  describe 'decide_machine_type' do
    let(:machine_type) { create(:machine_type) }
    let!(:process_estimates) do
      (1..5).map do |i|
        create(:process_estimate, work_process_definition: create(:work_process_definition, id: i), machine_type: machine_type)
      end
    end

    it 'process_estimate_idを正しく更新する' do
      start_date = Date.today
      workprocesses = WorkProcess.initial_processes_list(start_date)

      WorkProcess.decide_machine_type(workprocesses, machine_type.id)

      workprocesses.each_with_index do |process, index|
        expect(process[:process_estimate_id]).to eq(process_estimates[index].id)
      end
    end
  end

  describe '新規作成:update_deadline' do
    let(:machine_type) { create(:machine_type) }
    let!(:process_estimates) do
      (1..5).map do |i|
        work_process_definition = create(:work_process_definition, id: i)
        create(:process_estimate, work_process_definition: work_process_definition, machine_type: machine_type)
      end
    end

    before do
      puts "### ProcessEstimate Before Test: #{ProcessEstimate.all.inspect}"
      puts "### MachineType Before Test: #{MachineType.all.inspect}"
    end

    context 'definition_idが1~3の場合' do
      it 'process[:earliest_estimated_completion_date]が(start_date + estimate.earliest_completion_estimate)になる' do
        start_date = Date.new(2024, 12, 1)
        workprocesses = WorkProcess.initial_processes_list(start_date)
        WorkProcess.decide_machine_type(workprocesses, machine_type.id)
        updated_workprocesses = WorkProcess.update_deadline(workprocesses, start_date)

        (0..2).each do |index| # definition_idが1~3の場合
          process = updated_workprocesses[index]
          estimate = process_estimates[index]
          expect(process[:earliest_estimated_completion_date]).to eq(start_date + estimate.earliest_completion_estimate)
          expect(process[:latest_estimated_completion_date]).to eq(start_date + estimate.latest_completion_estimate)
          start_date = process[:earliest_estimated_completion_date]
        end
      end
    end

    context 'definition_idが4の場合' do
      context 'process[:earliest_estimated_completion_date]が日曜の場合' do
        it 'next_start_dateを、process[:earliest_estimated_completion_date]の8日後にする' do
          start_date = Date.new(2024, 12, 1)
          workprocesses = WorkProcess.initial_processes_list(start_date)
          WorkProcess.decide_machine_type(workprocesses, machine_type.id)

          # 定義IDが4の工程の完了予定日を日曜日に設定
          workprocesses[3][:earliest_estimated_completion_date] = Date.new(2025, 4, 13) # 日曜日
          updated_workprocesses = WorkProcess.update_deadline(workprocesses, start_date)

          # process = updated_workprocesses[3]
          # expect(process[:earliest_estimated_completion_date]).to eq(Date.new(2025, 4, 16))
          # expect(process[:latest_estimated_completion_date]).to eq(Date.new(2025, 4, 21))
          expect(updated_workprocesses[4][:start_date]).to eq(Date.new(2025, 4, 21)) # 翌々週の月曜日
        end
      end

      context 'process[:earliest_estimated_completion_date]が日曜以外の場合' do
        it 'next_start_dateを、翌週の月曜にする' do
          start_date = Date.new(2024, 12, 1)
          workprocesses = WorkProcess.initial_processes_list(start_date)
          WorkProcess.decide_machine_type(workprocesses, machine_type.id)

          # 定義IDが4の工程の完了予定日を月曜日に設定
          workprocesses[3][:earliest_estimated_completion_date] = Date.new(2025, 4, 14)
          updated_workprocesses = WorkProcess.update_deadline(workprocesses, start_date)

          # process = updated_workprocesses[3]
          # expect(process[:earliest_estimated_completion_date]).to eq(Date.new(2025, 4, 16))
          # expect(process[:latest_estimated_completion_date]).to eq(Date.new(2025, 4, 21))
          expect(updated_workprocesses[4][:start_date]).to eq(Date.new(2025, 4, 21)) # 次の月曜日
        end
      end
    end
  end


  describe '更新処理:update_work_processes' do
    let!(:order) { create(:order) }
    let!(:machine_type) { create(:machine_type) }
    let!(:process_estimates) do
      (1..5).map do |i|
        work_process_definition = create(:work_process_definition, id: i)
        create(:process_estimate, work_process_definition: work_process_definition, machine_type: machine_type)
      end
    end
    let(:start_date) { Date.new(2024, 12, 1) }
    let!(:work_processes) do
      process_estimates.each_with_index.map do |estimate, index|
        create(:work_process,
               order: order,
               work_process_definition: estimate.work_process_definition,
               process_estimate: estimate,
               start_date: start_date + (index * 5).days, # スタート日を適宜増加
               earliest_estimated_completion_date: start_date + (index * 5).days + estimate.earliest_completion_estimate,
               latest_estimated_completion_date: start_date + (index * 5).days + estimate.latest_completion_estimate,
               work_process_status: create(:work_process_status))
      end
    end

    let(:workprocesses_params) do
      work_processes.map do |process|
        {
          id: process.id,
          start_date: process.start_date.to_s,
          actual_completion_date: nil,
          work_process_status_id: process.work_process_status.id,
          factory_estimated_completion_date: nil,
          earliest_estimated_completion_date: process.earliest_estimated_completion_date.to_s,
          latest_estimated_completion_date: process.latest_estimated_completion_date.to_s,
          work_process_definition_id: process.work_process_definition.id,
          process_estimate_id: process.process_estimate.id
        }
      end
    end

    let!(:current_work_processes) { WorkProcess.where(order: order) }

    it '全てのwork_processを更新し、適切な日付を計算する' do
      expect do
        binding.irb
        WorkProcess.update_work_processes(workprocesses_params, current_work_processes, machine_type.id)
      end.to_not raise_error
binding.irb
      work_processes.each do |work_process|
        work_process.reload
        expect(work_process.start_date).to be_present
        expect(work_process.earliest_estimated_completion_date).to be_present
        expect(work_process.latest_estimated_completion_date).to be_present
      end
    end
  end



  describe '更新処理：現在の進捗と完了日入力のテスト' do
    let!(:order) { Order.create!(company: company, product_number: product_number, color_number: color_number, roll_count: 10, quantity: 100) }
    let!(:company) { Company.create!(name: "Test Company") }
    let!(:product_number) { ProductNumber.create!(number: "PN-12345") }
    let!(:color_number) { ColorNumber.create!(color_code: "#FFFFFF") }
    let!(:work_process_definition) { WorkProcessDefinition.create!(name: "製織", sequence: 1) }
    let!(:status_in_progress) { WorkProcessStatus.create!(name: "作業中") }
    let!(:status_completed) { WorkProcessStatus.create!(name: "作業完了") }
    let!(:work_process_in_progress) do
      WorkProcess.create!(
        order: order,
        work_process_definition: work_process_definition,
        work_process_status: status_in_progress,
        start_date: Date.today,
        earliest_estimated_completion_date: Date.today + 10,
        latest_estimated_completion_date: Date.today + 15,
        actual_completion_date: nil
      )
    end
    let!(:work_process_completed) do
      WorkProcess.create!(
        order: order,
        work_process_definition: work_process_definition,
        work_process_status: status_completed,
        start_date: Date.today,
        earliest_estimated_completion_date: Date.today + 10,
        latest_estimated_completion_date: Date.today + 15,
        actual_completion_date: Date.today + 20
      )
    end

    context '現在の進捗を変更する' do
      it '完了以外に変更する場合' do
        expect(work_process_in_progress).to be_valid
      end

      it '完了に変更する場合(完了日入力があれば更新できる)' do
        expect(work_process_completed).to be_valid
      end
    end

    context '無効な属性の場合' do
      it '作業完了に更新しようとして、完了日入力がなければエラーになり更新できない' do

        work_process_in_progress.save
        work_process_in_progress.update(
          actual_completion_date: nil,
          work_process_status: status_completed
        )
        expect(work_process_in_progress).not_to be_valid
        expect(work_process_in_progress.errors[:actual_completion_date]).to include("完了日が入力されていません")
      end
    end
  end


  describe 'check_current_work_process' do
    let!(:order) { Order.create!(company: company, product_number: product_number, color_number: color_number, roll_count: 10, quantity: 100) }
    let!(:company) { Company.create!(name: "Test Company") }
    let!(:product_number) { ProductNumber.create!(number: "PN-12345") }
    let!(:color_number) { ColorNumber.create!(color_code: "#FFFFFF") }
    let!(:work_process_definition_1) { WorkProcessDefinition.create!(id: 1, name: "糸", sequence: 1) }
    let!(:work_process_definition_2) { WorkProcessDefinition.create!(id: 2, name: "染色", sequence: 2) }
    let!(:work_process_definition_4) { WorkProcessDefinition.create!(id: 4, name: "整理加工", sequence: 4) }
    let!(:process_estimate_1) {
      ProcessEstimate.create!(work_process_definition: work_process_definition_1, machine_type: machine_type, earliest_completion_estimate: 10, latest_completion_estimate: 15)
    }
    let!(:process_estimate_2) {
      ProcessEstimate.create!(work_process_definition: work_process_definition_2, machine_type: machine_type, earliest_completion_estimate: 5, latest_completion_estimate: 10)
    }
    let!(:process_estimate_4) {
      ProcessEstimate.create!(work_process_definition: work_process_definition_4, machine_type: machine_type, earliest_completion_estimate: 7, latest_completion_estimate: 12)
    }
    let!(:machine_type) { MachineType.create!(name: "ドビー") }
    let!(:work_process_1) do
      WorkProcess.create!(
        order: order,
        work_process_definition: work_process_definition_1,
        work_process_status: WorkProcessStatus.create!(name: "作業中"),
        start_date: Date.new(2024, 12, 26),
        process_estimate: process_estimate_1
      )
    end
    let!(:work_process_2) do
      WorkProcess.create!(
        order: order,
        work_process_definition: work_process_definition_2,
        work_process_status: WorkProcessStatus.create!(name: "作業前"),
        start_date: Date.new(2025, 1, 1),
        process_estimate: process_estimate_2
      )
    end
    let!(:work_process_4) do
      WorkProcess.create!(
        order: order,
        work_process_definition: work_process_definition_4,
        work_process_status: WorkProcessStatus.create!(name: "作業前"),
        start_date: Date.new(2025, 1, 15),
        process_estimate: process_estimate_4
      )
    end

    context 'definition_idが1の場合' do
      context 'actual_completion_dateが存在する場合' do
        it 'latest_estimated_completion_dateとearliest_estimated_completion_dateがactual_completion_dateになる' do
          actual_completion_date = Date.new(2025, 1, 5)
          updated_process, _next_start_date = WorkProcess.check_current_work_process(work_process_1, work_process_1.start_date, actual_completion_date)

          expect(updated_process.earliest_estimated_completion_date).to eq(actual_completion_date)
          expect(updated_process.latest_estimated_completion_date).to eq(actual_completion_date)
        end
      end

      context 'actual_completion_dateが存在しない場合' do
        it 'ナレッジを元にlatest_estimated_completion_dateとearliest_estimated_completion_dateが計算される' do
          start_date = Date.new(2024, 12, 26)
          updated_process, _next_start_date = WorkProcess.check_current_work_process(work_process_1, start_date, nil)

          expect(updated_process.earliest_estimated_completion_date).to eq(start_date + 10)
          expect(updated_process.latest_estimated_completion_date).to eq(start_date + 15)
        end
      end
    end

    context 'definition_idが2以上の場合' do
      context 'actual_completion_dateが存在する場合' do
        it 'ナレッジがactual_completion_dateに置き換わり、入力したprocess[:start_date]はstart_dateで置き換わる' do
          actual_completion_date = Date.new(2025, 1, 10)
          updated_process, _next_start_date = WorkProcess.check_current_work_process(work_process_2, work_process_2.start_date, actual_completion_date)

          expect(updated_process.earliest_estimated_completion_date).to eq(actual_completion_date)
          expect(updated_process.latest_estimated_completion_date).to eq(actual_completion_date)
          expect(updated_process.start_date).to eq(work_process_2.start_date)
        end
      end

      context 'actual_completion_dateが存在しない場合' do
        it '入力したprocess[:start_date]はstart_dateで置き換わり、そこからナレッジを計算' do
          start_date = Date.new(2025, 1, 15)
          updated_process, _next_start_date = WorkProcess.check_current_work_process(work_process_2, start_date, nil)

          expect(updated_process.start_date).to eq(start_date)
          expect(updated_process.earliest_estimated_completion_date).to eq(start_date + 5)
          expect(updated_process.latest_estimated_completion_date).to eq(start_date + 10)
        end
      end
    end

    context 'definition_idが4の場合' do
      context 'process[:earliest_estimated_completion_date]が日曜の場合' do
        it 'next_start_dateを、process[:earliest_estimated_completion_date]の8日後にする' do
          work_process_4.update(earliest_estimated_completion_date: Date.new(2025, 1, 19)) # 日曜日
          _, next_start_date = WorkProcess.check_current_work_process(work_process_4, work_process_4.start_date, nil)

          expect(next_start_date).to eq(Date.new(2025, 1, 27)) # 翌々週の月曜日
        end
      end

      context 'process[:earliest_estimated_completion_date]が日曜以外の場合' do
        it 'next_start_dateを、翌週の月曜にする' do
          work_process_4.update(earliest_estimated_completion_date: Date.new(2025, 1, 20)) # 月曜日
          _, next_start_date = WorkProcess.check_current_work_process(work_process_4, work_process_4.start_date, nil)

          expect(next_start_date).to eq(Date.new(2025, 1, 27)) # 次の月曜日
        end
      end
    end
  end

end
