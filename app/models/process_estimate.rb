class ProcessEstimate < ApplicationRecord
  belongs_to :machine_type
  belongs_to :work_process_definition
  has_many :work_processes

  # after_update :recalculate_work_processes

  private

  # def recalculate_work_processes
  #   # このProcessEstimateに関連する全てのWorkProcessを取得
  #   work_processes = WorkProcess.where(process_estimate_id: self.id)
  #   # 関連する WorkProcess を再計算
  #   work_processes.find_each do |work_process|
  #     work_process.recalculate_deadlines
  #   end
  # end

  def self.machine_type_process_estimate(machine_type_id)
    if machine_type_id == 1
      where(id: 1..5)
    elsif machine_type_id == 2
      where(id: 6..10)
    else
      none # 該当なしの場合は空の結果を返す
    end
  end
end
