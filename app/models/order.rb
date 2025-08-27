class Order < ApplicationRecord
  belongs_to :company
  belongs_to :product_number
  belongs_to :color_number
  has_many :work_processes, -> { ordered }
  has_many :machine_assignments, through: :work_processes
  accepts_nested_attributes_for :work_processes

  # 未完了の作業工程を持つ注文を簡単に参照できるアソシエーション
  has_many :incomplete_work_processes, -> { where.not(work_process_status_id: 3) }, class_name: "WorkProcess"

  validates :company_id, :product_number_id, :color_number_id, :roll_count, :quantity, presence: true
  validates :roll_count, :quantity, numericality: { greater_than_or_equal_to: 1 }
  validate :validate_start_date_presence, on: :create

  # すべての作業工程が完了している注文を取得
  scope :completed, -> {
    left_outer_joins(:incomplete_work_processes)
      .where(work_processes: { id: nil })
  }

  # 少なくとも一つの作業工程が未完了の注文を取得
  scope :incomplete, -> {
    joins(:incomplete_work_processes).distinct
  }


  # 取得中のorderインスタンスに関連するレコードを取得するため、work_processクラスメソッドから移動
  def current_work_process
    processes = work_processes.joins(:work_process_status)  # 変数に代入

    latest_completed = processes.where(work_process_statuses: { name:'作業完了' }).reorder(work_process_definition_id: :desc).first

    if latest_completed
      # 次の工程ID = 最新完了工程のID + 1
      next_definition_id = latest_completed.work_process_definition_id + 1
      # その工程IDで検索
      processes.where(work_process_definition_id:next_definition_id).first
    else
      # 完了工程がない場合、最初の工程（ID=1）を取得
      processes.where(work_process_definition_id:1).first
    end

  end

  # 最新の MachineAssignment を取得するメソッド
  def latest_machine_assignment
    machine_assignments.order(created_at: :desc).first
  end
  # 検索のスコープ
  # 会社名
  scope :search_by_company, ->(company_id) {
    joins(:company).where(company: { id: company_id }) if company_id.present?
  }

  # 品番
  scope :search_by_product_number, ->(product_number_id) {
    joins(:product_number).where(product_number: { id: product_number_id }) if product_number_id.present?
  }

  # 色番
  scope :search_by_color_number, ->(color_number_id) {
    joins(:color_number).where(color_number: { id: color_number_id }) if color_number_id.present?
  }

  # 現在の工程
  scope :search_by_work_process_definitions, ->(work_process_definition_id) {
    joins(:work_processes).where(work_processes: { work_process_definition_id: work_process_definition_id }) if work_process_definition_id.present?
  }


  ## 織機選択時のバリデーションを行うメソッド
  def validate_machine_selection(machine_assignments_params, flash)
    # 整理加工はvalidation不要
    return true if skip_machine_assignment_validation?

    # machine_assignments_params = update_order_params[:machine_assignments_attributes]

    # 織機が未指定の場合はバリデーションエラー
    if machine_assignments_params.blank? || machine_assignments_params[0][:machine_id].blank?
      flash[:alert] = "織機を選択してください"
      return false
    end

    selected_machine_id = machine_assignments_params[0][:machine_id].to_i
    selected_machine = Machine.find_by(id: selected_machine_id)

    # 存在しない織機の場合はskip
    return true unless selected_machine

    order_machine_type_name = work_processes&.first&.process_estimate&.machine_type&.name
    selected_machine_type_name = selected_machine.machine_type.name

    # 1. 織機タイプのチェック
    if order_machine_type_name.present? && order_machine_type_name != selected_machine_type_name
      # 新しいmachine_typeが一致する場合は変更を許可
      return true if permit_change_machine_type_same_time(selected_machine_type_name)
      flash[:alert] = "織機のタイプが異なります。別の織機を選択してください。"
      return false
    end

    # 2. 既に割り当てられているかチェック
    # 他の未完了の受注に同じ織機が割り当てられていないかを確認
    # 未完了の作業工程がある受注で同じ織機を使用している場合はエラー
    if Order.incomplete.joins(:machine_assignments)
      .where(machine_assignments: { machine_id: selected_machine_id })
      .where.not(id: id).exists?
      flash[:alert] = "選択した織機は既に他の未完了の受注で使用されています。"
      return false
    end


    # 条件3: machine_status_idが4（使用できない状態）の場合
    current_assignment = selected_machine.machine_assignments.order(created_at: :desc).first
    # current_machine_status_idが4ならエラーメッセージを表示する例
    if current_assignment&.machine_status_id == 4
      flash[:alert] = "選択した織機は現在故障中です。"
      return false
    end

    # すべて問題ない場合
    true # 呼び出し元の処理を続ける
  end

  # 整理加工では machine_assignment_validationを実施しない
  def skip_machine_assignment_validation?
    current_work_process&.work_process_definition&.name == "整理加工"
  end

  # 同時にmachine_typeが変更される場合は許可
  def permit_change_machine_type_same_time(selected_machine_type_name)
    return false unless params[:machine_type_id].present?

    new_machine_type = MachineType.find_by(id: params[:machine_type_id])
    return false unless new_machine_type && new_machine_type.name == selected_machine_type_name

    work_processes.each do |work_process|
      process_estimate = ProcessEstimate.find_by(
        work_process_definition_id: work_process.work_process_definition_id,
        machine_type_id: new_machine_type.id
      )
      work_process.update!(process_estimate: process_estimate)
    end

    true # 呼び出し元の処理を続ける
  end

  # 注文が1週間以内に作成されたかを判定するメソッド
  def recent?
    created_at >= 1.weeks.ago
  end

  private

  def validate_start_date_presence
    return if work_processes.blank? # 作業工程がまだ作成されていない場合はスキップ

    if work_processes.any? { |wp| wp.start_date.blank? }
      errors.add(:start_date, "開始日を入力してください")
    end
  end
end
