class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :process_estimate, optional: true # null allow
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :machines, through: :machine_assignments

  scope :ordered, -> { joins(:work_process_definition).order('work_process_definitions.sequence') }

  before_save :recalculate_deadlines

  private

  # def self.machine_type_process_estimate(machine_type_id)
  #   if machine_type_id == 1
  #     process_estimate = ProcessEstimate.where(id: 1..5)
  #   elsif machine_type_id == 2
  #     process_estimate = ProcessEstimate.where(id: 6..10)
  #   end
  #   binding.irb
  # end

  # def self.update_deadline(workprocesses, machine_type_id, start_date)
  #   short = 0
  #   long = 0

  #   workprocesses.map do |process|
  #     # 計算対象のナレッジレコードを取得
  #     target_estimate = ProcessEstimate.machine_type_process_estimate(machine_type_id).find_by(
  #       work_process_definition_id: process[:work_process_definition_id]
  #     )

  #     next unless target_estimate # 該当ナレッジがなければスキップ

  #     # ナレッジの値を取得
  #     short += target_estimate.earliest_completion_estimate
  #     long += target_estimate.latest_completion_estimate

  #     # ナレッジの値を計算して更新
  #     process[:earliest_estimated_completion_date] = start_date.to_date + short
  #     process[:latest_estimated_completion_date] = start_date.to_date + long
  #     process[:start_date] ||= start_date # 上書きされる場合は既存値を優先

  #     start_date = process[:earliest_estimated_completion_date] # 次の工程の開始日を更新

  #     process
  #   end
  # end

  # 完了見込みに関するスコープ
  def self.update_deadline(workprocesses, machine_type_id, initial_start_date)
    # 初期の開始日を設定
    current_start_date = initial_start_date.to_date

    workprocesses.each_with_index do |process, index|
      # 対応する ProcessEstimate を取得
      target_estimate = ProcessEstimate.machine_type_process_estimate(machine_type_id).find_by(
        work_process_definition_id: process[:work_process_definition_id]
      )

      next unless target_estimate # 該当するデータがない場合はスキップ

      if index == 0
        # 最初の工程の場合
        process[:start_date] = current_start_date
        process[:earliest_estimated_completion_date] = current_start_date + target_estimate.earliest_completion_estimate
        process[:latest_estimated_completion_date] = current_start_date + target_estimate.latest_completion_estimate
      else
        # 他の工程の場合、前の工程の完了日時を基に計算
        previous_process = workprocesses[index - 1]
        process[:start_date] = previous_process[:earliest_estimated_completion_date]
        process[:earliest_estimated_completion_date] = previous_process[:earliest_estimated_completion_date] + target_estimate.earliest_completion_estimate
        process[:latest_estimated_completion_date] = previous_process[:latest_estimated_completion_date] + target_estimate.latest_completion_estimate
      end
    end

    workprocesses
  end

  def recalculate_deadlines
    return unless self.process_estimate || self.order

    # 対応する ProcessEstimate を取得
    target_estimate = ProcessEstimate.machine_type_process_estimate(self.process_estimate&.machine_type_id).find_by(
      work_process_definition_id: self.work_process_definition_id
    )

    return unless target_estimate

    # 再計算
    if self.work_process_definition_id == 1
      # 最初の工程の場合、オーダーの開始日を基に計算
      self.start_date ||= self.order&.start_date
    else
      # 他の工程の場合、前の工程の最短完了日時を開始日に設定
      previous_process = self.order.work_processes.find_by(
        work_process_definition_id: self.work_process_definition_id - 1
      )

      self.start_date = previous_process&.earliest_estimated_completion_date
    end

    # 完了予定日を計算
    self.earliest_estimated_completion_date = self.start_date + target_estimate.earliest_completion_estimate
    self.latest_estimated_completion_date = self.start_date + target_estimate.latest_completion_estimate

    self.save!
  end

  # 発注登録時に一括作成するWorkProcessレコード定義
  def self.initial_processes_list(start_date)
    [
      {
        work_process_definition_id: 1,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: nil,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 2,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: nil,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 3,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: nil,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 4,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: nil,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 5,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: nil,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
    ]
  end


  # 現在作業中の作業工程を取得するスコープ
  def self.current_work_process
    # 最新の「作業完了」ステータスの作業工程を取得
    latest_completed_wp = joins(:work_process_status)
                            .where(work_process_statuses: { name: '作業完了' })
                            .order(start_date: :desc)
                            .first

    if latest_completed_wp
      # 最新の「作業完了」より後の作業工程を取得
      where('start_date > ?', latest_completed_wp.start_date).order(:start_date).first
    else
      # 「作業完了」がない場合、最も古い作業工程を取得
      order(:start_date).first
    end
  end
end
