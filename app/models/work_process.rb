class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :process_estimate, optional: true # null allow
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :machines, through: :machine_assignments

  scope :ordered, -> { joins(:work_process_definition).order('work_process_definitions.sequence') }

  def self.update_deadline(workprocesses, process_estimate, start_date)
    if machine_type_id == 1

    end

  end
  # ドビー

  def self.update_dobby_deadline(workprocesses, machine_type_id, start_date)

    # データを配列で取得
    # processes = WorkProcess.where(work_process_definition_id: 1..5).to_a
    processe_estimates = ProcessEstimate.where(id: 1..5)

    short = 0
    long = 0

    # 配列を一個ずつ取り出す
    workprocesses.map do |process|
      # 計算対象のナレッジレコードを取得
      target_estimate = processe_estimates.find_by(
        work_process_definition_id:  process[:work_process_definition_id]
      )
      # ナレッジの値を取得
      short += target_estimate.earliest_completion_estimate
      long += target_estimate.latest_completion_estimate

      # ナレッジの値を計算して更新
      process[:earliest_estimated_completion_date] = start_date.to_date + short
      process[:latest_estimated_completion_date] = start_date.to_date + long
      process
    end
  end




  # ジャカード
  def self.update_jacquard_deadline(jacquard_workprocesses, machine_type_id, start_date)
    # データを配列で取得
    # processes = WorkProcess.where(work_process_definition_id: 1..5).to_a
    processe_estimates = ProcessEstimate.where(id: 1..5)

    short = 0
    long = 0

    jacquard_workprocesses.map do |process|
      target_estimate = processe_estimates.find_by(
        work_process_definition_id:  process[:work_process_definition_id]
      )
      short += target_estimate.earliest_completion_estimate
      long += target_estimate.latest_completion_estimate

      process[:earliest_estimated_completion_date] = start_date.to_date + short
      process[:latest_estimated_completion_date] = start_date.to_date + long
      process
    end
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
        # process_estimate_id: 3,
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

    # # 発注登録時に一括作成するWorkProcessレコード定義
    # def self.jacquard_initial_processes_list(start_date)
    #   [
    #     {
    #       work_process_definition_id: 1,
    #       work_process_status_id: 1,
    #       start_date: start_date,
    #       process_estimate_id: 6,
    #       earliest_estimated_completion_date: nil,
    #       latest_estimated_completion_date: nil,
    #       actual_completion_date: nil
    #     },
    #     {
    #       work_process_definition_id: 2,
    #       work_process_status_id: 1,
    #       start_date: start_date,
    #       process_estimate_id: 7,
    #       earliest_estimated_completion_date: nil,
    #       latest_estimated_completion_date: nil,
    #       actual_completion_date: nil
    #     },
    #     {
    #       work_process_definition_id: 3,
    #       work_process_status_id: 1,
    #       start_date: start_date,
    #       process_estimate_id: 8,
    #       earliest_estimated_completion_date: nil,
    #       latest_estimated_completion_date: nil,
    #       actual_completion_date: nil
    #     },
    #     {
    #       work_process_definition_id: 4,
    #       work_process_status_id: 1,
    #       start_date: start_date,
    #       process_estimate_id: 9,
    #       earliest_estimated_completion_date: nil,
    #       latest_estimated_completion_date: nil,
    #       actual_completion_date: nil
    #     },
    #     {
    #       work_process_definition_id: 5,
    #       work_process_status_id: 1,
    #       start_date: start_date,
    #       process_estimate_id: 10,
    #       earliest_estimated_completion_date: nil,
    #       latest_estimated_completion_date: nil,
    #       actual_completion_date: nil
    #     },
    #   ]
    # end

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
