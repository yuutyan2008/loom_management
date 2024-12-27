require 'rails_helper'

RSpec.describe WorkProcess, type: :model do
  describe '現在の進捗と完了日入力のテスト' do
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


  describe 'check_current_work_processメソッドのテスト' do
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



    # it '全てのwork_processを順番に更新して正しい日付が反映されること' do
    #   actual_completion_date_1 = Date.new(2025, 1, 5)
    #   actual_completion_date_2 = Date.new(2025, 1, 15)
    #   # binding.irb
    #   # 第一工程を更新
    #   updated_process_1, next_start_date_1 = WorkProcess.check_current_work_process(work_process_1, work_process_1.start_date, actual_completion_date_1)
    #   # binding.irb
    #   # work_process_1.update!(
    #   #   earliest_estimated_completion_date: updated_process_1.earliest_estimated_completion_date,
    #   #   latest_estimated_completion_date: updated_process_1.latest_estimated_completion_date,
    #   #   actual_completion_date: actual_completion_date_1
    #   # )

    #   # # 第二工程を更新
    #   # updated_process_2, next_start_date_2 = WorkProcess.check_current_work_process(work_process_2, next_start_date_1, actual_completion_date_2)
    #   # work_process_2.update!(
    #   #   earliest_estimated_completion_date: updated_process_2.earliest_estimated_completion_date,
    #   #   latest_estimated_completion_date: updated_process_2.latest_estimated_completion_date,
    #   #   start_date: next_start_date_1
    #   # )

    #   # # 確認: 第二工程の開始日が第一工程の完了日と一致
    #   # expect(work_process_2.start_date).to eq(next_start_date_1)

    #   # # 確認: 第二工程の最短/最長完了日が正しく更新
    #   # expect(work_process_2.earliest_estimated_completion_date).to eq(next_start_date_1 + 5) # 2025-01-10
    #   # expect(work_process_2.latest_estimated_completion_date).to eq(next_start_date_1 + 10) # 2025-01-15
    # end
end
