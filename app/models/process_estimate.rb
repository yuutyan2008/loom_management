class ProcessEstimate < ApplicationRecord
  belongs_to :machine_type
  belongs_to :work_process_definition
  has_many :work_processes

  # ナレッジの計算処理の定義
  def process_estimate

  end
end
