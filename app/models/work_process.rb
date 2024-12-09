class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :process_estimate, optional: true # null allow
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
  accepts_nested_attributes_for :machine_assignments
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :machines, through: :machine_assignments

  scope :ordered, -> {
    # ネストされた全ての発注関連データを取得
    includes(
      :work_process_definition,
      machine_assignments: :machine_status,
      order: [:company, :product_number, :color_number]
    )
    .joins(:work_process_definition)
    .order('work_process_definitions.sequence') }


    # 発注登録時に一括作成するWorkProcess配列を定義
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


  def self.decide_machine_type(workprocesses, machine_type_id)
    if machine_type_id == 1
      # 初期のWorkProcess配列のprocess_estimate_idを更新
      workprocesses.each do |process|
        process[:process_estimate_id] = process[:work_process_definition_id]
      end
    elsif machine_type_id == 2
      workprocesses.each do |process|
        process[:process_estimate_id] = process[:work_process_definition_id] + 5
      end
    end
  end


  # def self.update_deadline(workprocess, start_date)
  #   binding.irb
  #   short = 0
  #   long = 0
  #   update = true
  #   # 配列を一個ずつ取り出す
  #   workprocess.each do |process|
  #     unless update == true
  #       # 開始日の更新が必要
  #       binding.irb
  #       process[:start_date] = start_date
  #     end


  #   work_process_id = process["id"]
  #   target_estimate_record = ProcessEstimate.joins(:work_processes)
  #   .where(work_processes: { id: work_process_id })
  #   .first

  #   # ナレッジの値を計算して更新
  #   process["earliest_estimated_completion_date"] = start_date.to_date + target_estimate_record.earliest_completion_estimate
  #   process["latest_estimated_completion_date"] = start_date.to_date + target_estimate_record.latest_completion_estimate
  #   # start_date = self.new_start_date(workprocess, start_date)
  #   binding.irb

  #     # 納期の見込み日数のレコードを取得
  #     # process = self.arrange_estimate_record(process, start_date)
  #     binding.irb
  #     if process[:work_process_definition_id] == 4
  #       # 日曜日なら翌々週の月曜が作業開始日
  #         if process[:latest_estimated_completion_date].wday == 0
  #           start_date = process[:latest_estimated_completion_date] + 8
  #         else
  #           # 次の月曜日が開始日
  #           start_date = process[:latest_estimated_completion_date].next_week
  #         end
  #     else
  #       start_date = process[:latest_estimated_completion_date]
  #     end
  #     # binding.irb

  #     update = false
  #     #
  #     process[:start_date] = start_date
  #     # binding.irb
  #     process
  #   end
  # end


  # 納期の見込み日数のレコードを取得
  # def self.arrange_estimate_record(process, start_date)
  #   work_process_id = process["id"]
  #   target_estimate_record = ProcessEstimate.joins(:work_processes)
  #   .where(work_processes: { id: work_process_id })
  #   .first

  #   # ナレッジの値を計算して更新
  #   process["earliest_estimated_completion_date"] = start_date.to_date + target_estimate_record.earliest_completion_estimate
  #   process["latest_estimated_completion_date"] = start_date.to_date + target_estimate_record.latest_completion_estimate
  #   # start_date = self.new_start_date(workprocess, start_date)
  #   binding.irb
  # end


  def self.check_current_work_process(process, start_date, actual_completion_date, index, next_process = nil)
    # short = 0
    # long = 0
    # 配列を一個ずつ取り出す
    # estimate_workprocesses.each do |process|
    if index != 0
      # 開始日の更新が必要
      start_date = actual_completion_date


      self.calc_process_estimate(process, start_date)

            # binding.irb
    elsif index == 0
      process["latest_estimated_completion_date"] = actual_completion_date
      # binding.irb
    end
    process
  end

  def self.calc_process_estimate(process)
      # 納期の見込み日数のレコードを取得
      work_process_id = process["id"]
      target_estimate_record = ProcessEstimate.joins(:work_processes)
      .where(work_processes: { id: work_process_id })
      .first

      # ナレッジの値を計算して更新
      process["earliest_estimated_completion_date"] = start_date.to_date + target_estimate_record.earliest_completion_estimate
      process["latest_estimated_completion_date"] = start_date.to_date + target_estimate_record.latest_completion_estimate

      process
  end

  # 次の工程のstart_dateを決定
  def self.determine_next_start_date(process)
    if process[:work_process_definition_id] == 4
      # 日曜日なら翌々週の月曜が作業開始日
      if process[:latest_estimated_completion_date].wday == 0
      start_date = process[:latest_estimated_completion_date] + 8
      else
      # 次の月曜日が開始日
      start_date = process[:latest_estimated_completion_date].next_week
      end
    else
      start_date = process[:latest_estimated_completion_date]
    end
    # binding.irb
          start_date
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
      where('work_processes.start_date > ?', latest_completed_wp.start_date).order(:start_date).first
    else
      # 「作業完了」がない場合、最も古い作業工程を取得
      order(:start_date).first
    end
  end

  # 発注の更新処理
  # def self.update_work_process(work_processes_attributes)
  #   ActiveRecord::Base.transaction(requires_new: true) do
  #     # WorkProcessの直接的な更新
  #     self.update!(
  #       work_process_status_id: params["work_process_status_id"],
  #       factory_estimated_completion_date: params["factory_estimated_completion_date"],
  #       actual_completion_date: params["actual_completion_date"],
  #       start_date: params["start_date"]
  #     )
  #   end
  # end

  # # 完了日の置き換え
  # def self.update_by_actual_completion_date(workprocess, actual_completion_date)
  #   binding.irb
  #   workprocess["latest_estimated_completion_date"] = actual_completion_date
  #   # workprocess["start_date"] = actual_completion_date
  #   workprocess
  # end

  def self.update_deadline(estimate_workprocesses, start_date)
    short = 0
    long = 0
    update = true
    # 配列を一個ずつ取り出す
    estimate_workprocesses.each do |process|
      unless update == true
        # 開始日の更新が必要
        process[:start_date] = start_date
      end
      # 納期の見込み日数のレコードを取得
      target_estimate_record = ProcessEstimate.find_by(
        id: process[:process_estimate_id]
      )
      # ナレッジの値を計算して更新
      process[:earliest_estimated_completion_date] = start_date.to_date + target_estimate_record.earliest_completion_estimate
      process[:latest_estimated_completion_date] = start_date.to_date + target_estimate_record.latest_completion_estimate
      # 次の工程のstart_dateを決定
      if process[:work_process_definition_id] == 4
        # 日曜日なら翌々週の月曜が作業開始日
          if process[:latest_estimated_completion_date].wday == 0
          start_date = process[:latest_estimated_completion_date] + 8
          else
          # 次の月曜日が開始日
          start_date = process[:latest_estimated_completion_date].next_week
          end
      else
        start_date = process[:latest_estimated_completion_date]
      end
      update = false
      #
      process
    end
  end




end
