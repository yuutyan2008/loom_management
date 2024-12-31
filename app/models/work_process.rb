class WorkProcess < ApplicationRecord
  belongs_to :order
  belongs_to :work_process_definition
  belongs_to :work_process_status
  has_many :machine_assignments
  accepts_nested_attributes_for :machine_assignments
  belongs_to :process_estimate, optional: true # null allow
  accepts_nested_attributes_for :process_estimate
  # WorkControllerでの関連情報取得簡略化のため、throughを追加
  has_many :machines, through: :machine_assignments

  # 新規時バリデーション
  validates :start_date, presence: true, on: :create
  # 更新時バリデーション
  validates :work_process_status, presence: true, on: :update
  validate :actual_completion_date_presence_if_completed, on: :update

  scope :ordered, -> {
    # ネストされた全ての発注関連データを取得
    includes(
      :work_process_definition,
      machine_assignments: [:machine, :machine_status],
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

  # 織機の種類登録、変更でwork_processのprocess_estimate_idを更新
  def self.decide_machine_type(workprocesses, machine_type_id)
    # params[:machine_type_id]と一致するDBの値を取得
    process_estimates = ProcessEstimate.where(machine_type_id: machine_type_id)
    # 初期のWorkProcess配列のprocess_estimate_idを更新

    workprocesses.each do |process|
      estimate = process_estimates.find_by(work_process_definition_id: process[:work_process_definition_id])
      process[:process_estimate_id] = estimate[:id]
    end
  end


  # 新規登録：全行程の日時の更新
  def self.update_deadline(estimate_workprocesses, start_date)
    update = true
    next_start_date = start_date
    # 配列を一個ずつ取り出す
    estimate_workprocesses.each do |process|
      unless update == true
        # 開始日の更新が必要
        process[:start_date] = next_start_date
        start_date = process[:start_date]
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
          if process[:earliest_estimated_completion_date].wday == 0
          next_start_date = process[:earliest_estimated_completion_date] + 8
          else
          # 次の月曜日が開始日
          next_start_date = process[:earliest_estimated_completion_date].next_week
          end
      else
        next_start_date = process[:earliest_estimated_completion_date]
      end
      update = false
      #

    end
    estimate_workprocesses
  end


  def self.update_work_processes(workprocesses_params, current_work_processes, machine_type_id)
    # 入力値を元にDBからProcessEstimateデータ5個分を取得
    process_estimates = ProcessEstimate.where(machine_type_id: machine_type_id)
    # 選択されている織機typeと新しいナレッジの織機タイプが一致しているか確認
      # machine = Machine.find_by(id: machine_id)
    # DBに登録されている、5個のwork_process
    # current_work_processes = @order.work_processes

    next_start_date = nil

    workprocesses_params.each_with_index do |workprocess_params, index|
      target_work_prcess = current_work_processes.find(workprocess_params[:id])

      # target_work_prcess：current_work_processesの１工程
      # target_work_prcess = current_work_processes.find(workprocess_params[:id])
      if index == 0
        start_date = target_work_prcess["start_date"]
      else
        input_start_date = workprocess_params[:start_date].to_date
        # 入力された開始日が新しい場合は置き換え
        start_date = input_start_date > next_start_date ? input_start_date : next_start_date
        # if input_start_date < next_start_date
        #   flash[:alert] = "開始日 (#{input_start_date}) は前の工程の完了日 (#{next_start_date}) よりも新しい日付にしてください。"
        #   render :edit and return
        # end
      end

      actual_completion_date =  workprocess_params[:actual_completion_date]

      # 織機の種類を変更した場合
      # 選択されたparams[:machine_type_id]
      if target_work_prcess.process_estimate.machine_type != process_estimates.first.machine_type
        estimate = process_estimates.find_by(work_process_definition_id: target_work_prcess.work_process_definition_id)
        # ナレッジ置き換え
        target_work_prcess.process_estimate = estimate
      end
      target_work_prcess.work_process_status_id = workprocess_params[:work_process_status_id]
      target_work_prcess.factory_estimated_completion_date = workprocess_params[:factory_estimated_completion_date]
      # binding.irb
      target_work_prcess.save
      # 更新したナレッジで全行程の日時の更新処理の呼び出し
      new_target_work_prcess, next_start_date = WorkProcess.check_current_work_process(target_work_prcess, start_date, actual_completion_date)
      # 開始日の方が新しい場合は置き換え
      next_start_date = start_date > next_start_date ? start_date : next_start_date

      new_target_work_prcess.actual_completion_date = actual_completion_date
      new_target_work_prcess.save

    end
  end


  # 更新：全行程の日時の更新
  def self.check_current_work_process(process, start_date, actual_completion_date)

    # 工程idが2以上の場合
    if process[:work_process_definition_id].to_i >= 2
      if actual_completion_date.present?
        process[:latest_estimated_completion_date] = actual_completion_date
        process[:earliest_estimated_completion_date] = actual_completion_date
        # start_date = process[:start_date]
        # 追記
        process[:start_date] = start_date
      else
      # 開始日の更新が必要

        process[:start_date] = start_date
        # 更新された開始日からナレッジを再計算
        self.calc_process_estimate(process, start_date)
      end
      # process[:start_date] = start_date
    end

    if process[:work_process_definition_id].to_i == 1
      if actual_completion_date.present?
        process[:latest_estimated_completion_date] = actual_completion_date
        process[:earliest_estimated_completion_date] = actual_completion_date
      else
        process = self.calc_process_estimate(process, start_date)
      end
    end

    # 整理加工の開始日調整
    if process[:work_process_definition_id].to_i == 4
      # 日曜日なら翌々週の月曜が作業開始日
      if process[:earliest_estimated_completion_date].to_date.wday == 0
        next_start_date = process[:earliest_estimated_completion_date].to_date + 8
      else
        # 次の月曜日が開始日
        next_start_date = process[:earliest_estimated_completion_date].to_date.next_week
      end
    else
      # ここに、工程が５なら次の開始日は不要の処理を作りたい
      next_start_date = process[:earliest_estimated_completion_date]
    end
    return [process, next_start_date]
  end


  # ナレッジ更新処理
  def self.calc_process_estimate(process, start_date)
      # 納期の見込み日数のレコードを取得
      work_process_id = process["id"]
      target_estimate_record = ProcessEstimate.joins(:work_processes)
      .find_by(work_processes: { id: work_process_id })

      # ナレッジの値を計算して更新
      process[:earliest_estimated_completion_date] = start_date.to_date + target_estimate_record.earliest_completion_estimate
      process[:latest_estimated_completion_date] = start_date.to_date + target_estimate_record.latest_completion_estimate
      process
  end

  # 更新：織機詳細変更処理
  def self.change_machine_assignment(order, machine_id, machine_status_id)
    machine_ids = order.work_processes.joins(:machine_assignments).pluck('machine_assignments.machine_id').uniq

    if machine_ids.any?
      # 既存のMachineAssignmentを更新
      order.machine_assignments.each do |assignment|
        assignment.update!(
          machine_id: machine_id.present? ? machine_id : nil,
          machine_status_id: machine_status_id.present? ? machine_status_id : nil
        )
      end
    else
      # 存在しない場合は新規作成
      order.work_processes.each do |work_process|
        ma = MachineAssignment.find_or_initialize_by(
          work_process_id: work_process.id,
          machine_id: machine_id
        )
        ma.machine_status_id ||= 2 # デフォルトのステータス
        ma.save!
      end
    end
  end




  # 現在作業中の作業工程を取得するスコープ
  def self.current_work_process
    # 最新の「作業完了」ステータスの作業工程を取得
    latest_completed_wp = joins(:work_process_status)
                            .where(work_process_statuses: { name: '作業完了' })
                            .order(start_date: :desc)
                            .last

    if latest_completed_wp
      # 最新の「作業完了」より後の作業工程を取得
      where('work_processes.start_date > ?', latest_completed_wp.start_date).order(:start_date).first
    else
      # 「作業完了」がない場合、最も古い作業工程を取得
      order(:start_date).first
    end
  end

  private

  # 更新時のバリデーション
  def actual_completion_date_presence_if_completed
    completed_status_id = WorkProcessStatus.find_by(name: "作業完了")&.id
    if work_process_status_id == completed_status_id && actual_completion_date.blank?

      errors.add(:actual_completion_date, "完了日が入力されていません")
    end
  end
end
