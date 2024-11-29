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
    # 処理
  end
  # ドビー

  def self.update_dobby_deadline(dobby_workprocesses, machine_type_id, start_date)

    # データを配列で取得
    # processes = WorkProcess.where(work_process_definition_id: 1..5).to_a
    processe_estimates = ProcessEstimate.where(id: 1..5)

    short = 0
    long = 0

    return dobby_workprocesses.map do |process|
      target_estimate = processe_estimates.find_by(
        work_process_definition_id:  process[:work_process_definition_id]
      )
      short += target_estimate.earliest_completion_estimate
      long += target_estimate.latest_completion_estimate

      process[:earliest_estimated_completion_date] = start_date.to_date + short
      process[:latest_estimated_completion_date] = start_date.to_date + long
      process
    end

    processes.each do |process|

      dobby_workprocess = []
      # ハッシュ初期化
      dobby_workprocess = {}
      dobby_workprocess[:earliest_estimated_completion_date] = start_date.to_date +  process.process_estimate.earliest_completion_estimate.to_i

      dobby_workprocess[:latest_estimated_completion_date] = start_date.to_date + process.process_estimate.latest_completion_estimate.to_i
      # 1レコード更新
      dobby_workprocesses << dobby_workprocess

      # start_dateを更新
      # new_start_dateが空でなければlatest_estimated_completion_dateで置き換える
      new_start_date = dobby_workprocess[:latest_estimated_completion_date]
      if new_start_date
        start_date = new_start_date
      end

      # 各工程完了時、機屋がactual_completion_dateを入力した場合
      if dobby_workprocess[:actual_completion_date].present?
        start_date = dobby_workprocess[:actual_completion_date].to_date
      end
    end
    binding.irb
  end


  # ジャカード
  def self.update_jacquard_deadline(jacquard_workprocesses, machine_type_id, start_date)

    # process_estimateデータを配列で取得
    estimates = ProcessEstimate.where(id: 6..10, machine_type_id: machine_type_id).to_a

    estimates.each do |estimate|

      # ハッシュ初期化
      jacquard_workprocess = {}
      jacquard_workprocess[:earliest_estimated_completion_date] = start_date.to_date +  estimate.earliest_completion_estimate.to_i

      jacquard_workprocess[:latest_estimated_completion_date] = start_date.to_date + estimate.latest_completion_estimate.to_i
      # 1レコード更新
      jacquard_workprocesses << jacquard_workprocess

      # start_dateを更新
      # new_start_dateが空でなければlatest_estimated_completion_dateで置き換える
      new_start_date = jacquard_workprocess[:latest_estimated_completion_date]
      if new_start_date
        start_date = new_start_date
      end

      # 各工程完了時、機屋がactual_completion_dateを入力した場合
      if jacquard_workprocess[:actual_completion_date].present?
        start_date = jacquard_workprocess[:actual_completion_date]
      end
    end

    jacquard_workprocesses
  end



  # 発注登録時に一括作成するWorkProcessレコード定義
  def self.dobby_initial_processes_list(start_date)
    [
      {
        work_process_definition_id: 1,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 1,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 2,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 2,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 3,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 3,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 4,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 4,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
      {
        work_process_definition_id: 5,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 5,
        earliest_estimated_completion_date: nil,
        latest_estimated_completion_date: nil,
        actual_completion_date: nil
      },
    ]
  end

    # 発注登録時に一括作成するWorkProcessレコード定義
    def self.jacquard_initial_processes_list(start_date)
      [
        {
          work_process_definition_id: 1,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 6,
          earliest_estimated_completion_date: nil,
          latest_estimated_completion_date: nil,
          actual_completion_date: nil
        },
        {
          work_process_definition_id: 2,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 7,
          earliest_estimated_completion_date: nil,
          latest_estimated_completion_date: nil,
          actual_completion_date: nil
        },
        {
          work_process_definition_id: 3,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 8,
          earliest_estimated_completion_date: nil,
          latest_estimated_completion_date: nil,
          actual_completion_date: nil
        },
        {
          work_process_definition_id: 4,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 9,
          earliest_estimated_completion_date: nil,
          latest_estimated_completion_date: nil,
          actual_completion_date: nil
        },
        {
          work_process_definition_id: 5,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 10,
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
