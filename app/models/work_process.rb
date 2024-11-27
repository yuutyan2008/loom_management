class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :process_estimate, optional: true # null allow
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :machines, through: :machine_assignments

  # accepts_nested_attributes_for :process_estimate


  # 発注登録時に一括作成するWorkProcessレコード定義
  def self.dobby_initial_processes_list(start_date)
    [
      {
        work_process_definition_id: 1,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 1
      },
      {
        work_process_definition_id: 2,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 2
      },
      {
        work_process_definition_id: 3,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 3
      },
      {
        work_process_definition_id: 4,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 4
      },
      {
        work_process_definition_id: 5,
        work_process_status_id: 1,
        start_date: start_date,
        process_estimate_id: 5
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
          process_estimate_id: 6
        },
        {
          work_process_definition_id: 2,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 7
        },
        {
          work_process_definition_id: 3,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 8
        },
        {
          work_process_definition_id: 4,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 9
        },
        {
          work_process_definition_id: 5,
          work_process_status_id: 1,
          start_date: start_date,
          process_estimate_id: 10
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
