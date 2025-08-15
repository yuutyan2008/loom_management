class OrdersController < ApplicationController
  include ApplicationHelper
  include FlashHelper
  before_action :require_login
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :authorize_order, only: [:show, :destroy]
  # 追記：parameterの型変換(accept_nested_attributes_for使用のため)
  before_action :convert_work_processes_params, only: [:update]
  # 【追加】更新時にmachine_assignments_attributesを事前整理するためのbefore_actionを追加
  before_action :sanitize_machine_assignments_params, only: [:update]
  before_action :set_machine_statuses_for_form, only: [:edit, :update]

  def index
    @company = current_user&.company
    @orders = @company&.orders&.incomplete || Order.none
    @no_orders_message = "現在受注している商品はありません" unless @orders.any?

    check_overdue_work_processes_index(@orders)
  end

  def past_orders
    @company = current_user&.company
    @orders = @company&.orders&.completed || Order.none
    @no_past_orders_message = "過去の受注はありません" unless @orders.any?

    check_overdue_work_processes_index(@orders) # 必要に応じて修正
  end

  def show
    @work_processes = @order.work_processes
                            .includes(:work_process_definition, machine_assignments: :machine)
                            .ordered
    @current_work_process = find_current_work_process(@work_processes)
    load_machine_assignments_and_machines

    check_overdue_work_processes_show(@order.work_processes)
  end

  def new
    @order = current_user.company.orders.build
    @order.work_processes.build
  end

  def create
    @order = current_user.company.orders.build(order_params)
    if @order.save
      redirect_to order_path(@order), notice: "受注が正常に作成されました。"
    else
      render :new
    end
  end

  def edit
    build_missing_machine_assignments
  end

  # 追記：ハッシュ形式にすることでネストデータを更新
  def convert_work_processes_params
    if params[:order][:work_processes].present?
      # 空のハッシュを用意
      work_processes_attributes = {}

      # work_processes 配列を work_processes_attributes ハッシュに変換
      params[:order][:work_processes].each_with_index do |work_process, index|
        work_processes_attributes[index.to_s] = work_process
      end

      # 変換したデータを params[:order][:work_processes_attributes] に代入
      params[:order][:work_processes_attributes] = work_processes_attributes

      # 元の work_processes を削除しておく
      params[:order].delete(:work_processes)
    end
  end

  # 修正対象
  def update
    # ここで織機の選択条件を検証
    unless validate_machine_selection
      # 条件に合わず更新できない場合はここで処理を終了
      render :edit and return
    end

    ActiveRecord::Base.transaction do
      update_work_processes
      set_work_process_status_completed
      if machine_assignments_present?
        update_machine_assignments
        handle_machine_assignment_updates
      end
      update_order_details
    end
    redirect_to order_path(@order), notice: "更新されました。"
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    flash.now[:alert] = "更新に失敗しました: #{e.message}"
    Rails.logger.debug "Flash alert set: 更新に失敗しました: #{e.message}"
    render :edit
  end

  def destroy
    @order.destroy
    redirect_to orders_path, notice: "受注が削除されました。"
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: "指定された受注は存在しません。"
  end

  def authorize_order
    redirect_to orders_path, alert: "アクセス権限がありません。" unless @order.company == current_user.company
  end

  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      :start_date,
    )
  end

  # 追記：作業完了日入力時の更新
  def update_order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      # accepts_nested_attributes_forに対応
      machine_assignments_attributes: [:id, :machine_id, :machine_status_id],
      # accepts_nested_attributes_forに対応
      work_processes_attributes: [
        :id,
        :process_estimate_id,
        :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        :earliest_estimated_completion_date,
        :latest_estimated_completion_date,
        :actual_completion_date,
        :start_date,
      ]
    )
  end

  # ↓↓ showアクションに必要なメソッド ↓↓
  def load_machine_assignments_and_machines
    @current_machine_assignments = @current_work_process&.machine_assignments&.includes(:machine) || []
    @machines = @current_machine_assignments.map(&:machine).uniq
  end

  # ↓↓ editアクションに必要なメソッド ↓↓
  def build_missing_machine_assignments
    @order.work_processes.each do |wp|
      wp.machine_assignments.build if wp.machine_assignments.empty?
    end
  end

  # ↓↓ updateアクションに必要なメソッド ↓↓
  # def update_machine_assignments
  #   params[:order][:machine_assignments].each do |ma_param|
  #     ma = MachineAssignment.find(ma_param[:id])
  #     ma.update!(machine_status_id: ma_param[:machine_status_id])
  #   end
  # end

  # def update_machine_statuses
  #   params[:order][:machine_statuses].each do |ms_param|
  #     machine_id = ms_param[:machine_id]
  #     new_status_id = ms_param[:machine_status_id]

  #     # 関連するMachineAssignmentを取得
  #     assignments = MachineAssignment.where(machine_id: machine_id)

  #     assignments.each do |assignment|
  #       assignment.update!(machine_status_id: new_status_id)
  #     end
  #   end
  # end

  # WorkProcess の更新を担当
  def update_work_processes
    order_work_processes = update_order_params.except(:machine_assignments_attributes)
    workprocesses_params = order_work_processes[:work_processes_attributes].values

      # 織機の種類変更がある場合
      # WorkProcessのprocess_estimate_idを更新
      # 変更があった場合の新しいナレッジ

      machine_type_id = 1 # デフォルト値を設定（ドビー）
      # 織機が指定されている場合、その織機の種類を取得
      if update_order_params[:machine_assignments_attributes].present?
        machine = Machine.find_by(id: update_order_params[:machine_assignments_attributes][0][:machine_id])
        machine_type_id = machine.machine_type.id if machine.present?
      # 織機が指定されていない場合、orderに紐づく最初のwork_processのprocess_estimatesの織機種別を参照する
      else
        machine_type_id = @order.work_processes.first.process_estimate.machine_type_id if @order.work_processes.any?
      end
      process_estimates = ProcessEstimate.where(machine_type_id: machine_type_id)

      current_work_processes = @order.work_processes

      next_start_date = nil

      workprocesses_params.each_with_index do |workprocess_params, index|

        target_work_prcess = current_work_processes.find(workprocess_params[:id])
        if index == 0
          start_date = target_work_prcess["start_date"]
        else
          input_start_date = workprocess_params[:start_date].to_date
          # 入力された開始日が新しい場合は置き換え
          start_date = input_start_date > next_start_date ? input_start_date : next_start_date
        end

        actual_completion_date =  workprocess_params[:actual_completion_date]

        # 織機の種類を変更した場合
        # 選択されたmachine_type_id params[:machine_type_id]

        if target_work_prcess.process_estimate.machine_type != process_estimates.first.machine_type
          estimate = process_estimates.find_by(work_process_definition_id: target_work_prcess.work_process_definition_id)
          # ナレッジ置き換え
          target_work_prcess.process_estimate = estimate
        end
        target_work_prcess.work_process_status_id = workprocess_params[:work_process_status_id]
        target_work_prcess.factory_estimated_completion_date = workprocess_params[:factory_estimated_completion_date]
        target_work_prcess.actual_completion_date = workprocess_params[:actual_completion_date]
        target_work_prcess.start_date = workprocess_params[:start_date] #25.8.15 追加 開始日の変更が反映されない問題の対応
        target_work_prcess.save!
        # 更新したナレッジで全行程の日時の更新処理の呼び出し
        new_target_work_prcess, next_start_date = WorkProcess.check_current_work_process(target_work_prcess, start_date, actual_completion_date)
        # 開始日の方が新しい場合は置き換え
        next_start_date = start_date > next_start_date ? start_date : next_start_date

      end
  end

  # machine_status_id:1をselect_tagに出さないためのメソッド
  def set_machine_statuses_for_form
    @machine_statuses_for_form = filter_machine_statuses
  end

  def filter_machine_statuses
    # machine_status_id:1を除外
    MachineStatus.where.not(id: 1)
  end

  # MachineAssignmentの存在を確認
  def machine_assignments_present?
    update_order_params[:machine_assignments_attributes].present?
  end

  # MachineAssignmentの更新
  def update_machine_assignments
    # MachineAssignmentの更新
    machine_assignments_params = update_order_params[:machine_assignments_attributes]
    machine_id = machine_assignments_params[0][:machine_id].to_i
    machine_status_id = machine_assignments_params[0][:machine_status_id].to_i
    # フォームで送られた ID に基づき MachineAssignment を取得
    machine_ids = @order.work_processes.joins(:machine_assignments).pluck('machine_assignments.machine_id').uniq
    if machine_ids.any?
      @order.machine_assignments.each do |assignment|
        assignment.update!(
          machine_id: machine_id,
          machine_status_id: machine_status_id
        )
      end
    else
      # 存在しない場合は新規作成し、@order に関連付ける
      @order.work_processes.each do |work_process|
        # ここでfind_or_initialize_byを利用して同一work_process_idでの重複作成を防ぐ
        ma = MachineAssignment.find_or_initialize_by(
          work_process_id: work_process.id,
          machine_id: machine_id,
          machine_status_id: 2
        )
        ma.save!
      end
    end
  end

  # Order のその他の詳細を更新
  def update_order_details
    update_order = update_order_params.except(:machine_assignments_attributes, :work_processes_attributes)
    @order.update!(update_order) if update_order.present?
  end

  # machine_assignments_attributesが配列で来た場合にも対応
  def sanitize_machine_assignments_params
    return unless params[:order].present?
    if params[:order][:machine_assignments_attributes].present?
      # params[:order][:machine_assignments_attributes]が配列の場合、以下のように処理
      # rejectで織機IDもステータスIDも空文字の場合は削除
      cleaned = params[:order][:machine_assignments_attributes].reject do |ma|
        ma[:machine_id].blank? && ma[:machine_status_id].blank?
      end
      if cleaned.empty?
        params[:order].delete(:machine_assignments_attributes)
      else
        params[:order][:machine_assignments_attributes] = cleaned
      end
    end
  end

  def handle_machine_assignment_updates
    relevant_work_process_definition_ids = [1, 2, 3, 4]
    # 対象のWorkProcess群を取得
    relevant_work_processes = @order.work_processes.where(work_process_definition_id: relevant_work_process_definition_ids)
    target_work_processes = relevant_work_processes.where(work_process_status_id: 3)
    # 条件: 全てがstatus_id=3の場合のみ処理
    if relevant_work_processes.count == target_work_processes.count && relevant_work_processes.count > 0
      machine_id = update_order_params[:machine_assignments_attributes][0][:machine_id].to_i
      if machine_id.present?
        # 全WorkProcessを取得(5などその他も含む場合)
        all_work_process_ids = @order.work_processes.pluck(:id)
        # 既存の該当machine_idに紐づく全WorkProcessのMachineAssignmentを未割り当て状態に戻す
        MachineAssignment.where(
          machine_id: machine_id,
          work_process_id: all_work_process_ids
        ).update_all(machine_id: nil, machine_status_id: nil)
        # work_process_idがnil、machine_idが同一のMachineAssignmentがあるか確認
        # 既存があればそれを使い、新たなcreateは行わない
        assignment = MachineAssignment.find_or_initialize_by(machine_id: machine_id, work_process_id: nil)
        if assignment.new_record?
          # 新規の場合のみ作成
          assignment.machine_status_id = 1
          assignment.save!
        end
      end
    end
  end

  # actual_completion_date が入力された WorkProcess のステータスを「作業完了」（3）に設定するメソッド
  def set_work_process_status_completed
    @order.work_processes.each do |work_process|
      if work_process.actual_completion_date.present? && work_process.work_process_status_id != 3
        work_process.update!(work_process_status_id: 3)
      end
    end
  end

  # ↓↓ フラッシュメッセージを出すのに必要なメソッド ↓↓
  ## 追加: indexアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_index(orders)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status

    overdue_work_processes = WorkProcess.includes(:order, :work_process_definition)
                                        .where(order_id: orders.ids)
                                        .where("earliest_estimated_completion_date < ?", Date.today)
                                        .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      grouped = overdue_work_processes.group_by(&:order)
      total_overdue_orders = grouped.keys.size

      flash.now[:alerts] ||= []
      flash.now[:alerts] << build_flash_alert_message(
        "予定納期が過ぎている受注が #{total_overdue_orders} 件あります。",
        grouped.keys,
        ->(order) { edit_order_path(order) },
        ->(order) { order_path(order) }
      )
    end
  end

  ## 追加: showアクション用のWorkProcess遅延チェックメソッド
  def check_overdue_work_processes_show(work_processes)
    completed_status = WorkProcessStatus.find_by(name: '作業完了')
    return unless completed_status

    overdue_work_processes = work_processes.where("earliest_estimated_completion_date < ?", Date.today)
                                          .where.not(work_process_status_id: completed_status.id)

    if overdue_work_processes.exists?
      flash.now[:alerts] ||= []
      flash.now[:alerts] << {
        title: "以下の作業工程が予定完了日を過ぎており、まだ完了していません。修正がある場合は 編集 を確認ください。",
        messages: overdue_work_processes.map do |wp|
          {
            content: "作業工程: #{wp.work_process_definition.name}, 完了見込み: #{wp.latest_estimated_completion_date.strftime('%Y-%m-%d')}",
            edit_path: edit_admin_order_path(wp.order) # 編集リンクのパスを追加
          }
        end
      }
    end
  end

  # 織機選択時のバリデーションを行うメソッド
  def validate_machine_selection
    machine_assignments_params = update_order_params[:machine_assignments_attributes]
    return true unless machine_assignments_params.present? # 織機が未指定の場合は特にチェックせずスキップ

    selected_machine_id = machine_assignments_params[0][:machine_id].to_i
    selected_machine = Machine.find_by(id: selected_machine_id)

    # 存在しない織機の場合は特にチェックしない（別エラーになるはず）
    return true unless selected_machine

    order_machine_type_name = @order&.work_processes&.first&.process_estimate&.machine_type&.name
    selected_machine_type_name = selected_machine.machine_type.name

    # 1. 織機タイプのチェック
    if order_machine_type_name.present? && order_machine_type_name != selected_machine_type_name
      flash.now[:alert] = "織機のタイプが異なります。別の織機を選択してください。"
      return false
    end

    # 2. 既に割り当てられているかチェック
    # 他の未完了の受注に同じ織機が割り当てられていないかを確認
    # 未完了の作業工程がある受注で同じ織機を使用している場合はエラー
    incomplete_orders_using_machine = Order
      .incomplete
      .joins(:machine_assignments)
      .where(machine_assignments: { machine_id: selected_machine_id })
      .where.not(id: @order.id) # 自分自身は除外
    if incomplete_orders_using_machine.exists?
      flash.now[:alert] = "選択した織機は既に他の未完了の受注で使用されています。別の織機を選択してください。"
      return false
    end

    # 条件3: machine_status_idが4（使用できない状態）の場合
    current_assignment = selected_machine.machine_assignments.order(created_at: :desc).first
    current_machine_status_id = current_assignment&.machine_status_id
    # binding.irb
    # current_machine_status_idが4ならエラーメッセージを表示する例
    if current_machine_status_id == 4
      flash.now[:alert] = "選択した織機は現在故障中です。別の織機を選択してください。"
      return false
    end

    true
  end
end
