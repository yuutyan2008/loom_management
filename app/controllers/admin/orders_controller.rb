class Admin::OrdersController < ApplicationController
  # 定義された関数の使用
  include ApplicationHelper
  include FlashHelper
  before_action :order_params, only: [ :update ]
  before_action :create_order_params, only: [ :create ]

  before_action :set_order, only: [ :edit, :show, :update, :destroy ]
  # before_action :work_process_params, only: [:create, :update]
  before_action :admin_user
  # 【追加】更新時にmachine_assignments_attributesを事前整理するためのbefore_actionを追加
  before_action :sanitize_machine_assignments_params, only: [:update]
  before_action :set_machine_statuses_for_form, only: [:edit, :update]

  def index
    @orders = Order.includes(work_processes: [ :work_process_definition, :work_process_status, process_estimate: :machine_type ])
                   .incomplete
                   .order(:id)
    @no_orders_message = "現在受注している商品はありません" unless @orders.any?
    # 各注文に対して現在作業中の作業工程を取得
    @current_work_processes = {}
    @orders.each do |order|
      if order.work_processes.any?
        if params[:work_process_definitions_id].present?
          is_match = order.work_processes.current_work_process.work_process_definition_id == params[:work_process_definitions_id].to_i
          @current_work_processes[order.id] = is_match ? order.work_processes.current_work_process : nil
        else
          @current_work_processes[order.id] = order.work_processes.current_work_process
        end
      else
        @current_work_processes[order.id] = nil
      end

    end
    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_index(@orders)

    # 検索の実行（スコープを適用）

    @orders =
    @orders
      .search_by_company(params[:company_id])
      .search_by_product_number(params[:product_number_id])
      .search_by_color_number(params[:color_number_id])
  end

  def past_orders
    @orders = Order.includes(work_processes: [ :work_process_definition, :work_process_status, process_estimate: :machine_type ])
                   .completed
    @no_past_orders_message = "過去の受注はありません" unless @orders.any?
    # 現在の作業工程を取得（完了済みのため基本的にnilになる可能性が高い）
    @current_work_processes = {}
    @orders.each do |order|
      if order.work_processes.any?
        @current_work_processes[order.id] = order.work_processes.current_work_process
      else
        @current_work_processes[order.id] = nil
      end
    end
    # 遅延している作業工程のチェック（必要に応じて）
    check_overdue_work_processes_index(@orders)
  end
  # end

  def new
    @order = Order.new
    @work_process = WorkProcess.new
    @companies = Company.where.not(id: 1)
  end

  def create
    # orderテーブル以外を除外してorderインスタンス作成
    @order = Order.new(create_order_params.except(:work_processes))
    # work_processesのパラメータ取得
    # ハッシュの値部分のみを配列として取得
    work_processes = create_order_params[:work_processes]
    # ハッシュのキー"start_date"を引数にパラメータを取得
    start_date = work_processes["start_date"]
    machine_type_id = work_processes["process_estimate"]["machine_type_id"].to_i

    # 5個のwork_processハッシュからなる配列を作成
    workprocess = WorkProcess.initial_processes_list(start_date)
    # process_estimate_idを入れる
    estimate_workprocess = WorkProcess.decide_machine_type(workprocess, machine_type_id)
    # 完了見込日時を入れる
    update_workprocess = WorkProcess.update_deadline(estimate_workprocess, start_date)
    # ５個のハッシュとorderの関連付け
    update_workprocess.each do |work_process_data|
      @order.work_processes.build(work_process_data)
    end
    @order.save
    redirect_to admin_orders_path, notice: "注文が作成されました"
  end

  def show
    @work_process = @order.work_processes.ordered
    @machines = @work_process.map { |work_process| work_process.machines}.flatten.uniq
    # 追加: 遅延している作業工程のチェック
    check_overdue_work_processes_show(@order.work_processes)
  end

  def edit
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
    end
    # orderedスコープで並び替えて取得
    @work_processes = @order.work_processes.ordered

    @work_processes.map { |work_process| work_process.machines }.flatten.uniq
  end

  def update
    # ここで織機の選択条件を検証
    unless validate_machine_selection
      # 条件に合わず更新できない場合はここで処理を終了
      render :edit and return
    end

    ActiveRecord::Base.transaction do
      order_work_processes = order_params.except(:machine_assignments_attributes)

      # 完了日の取得
      workprocesses_params = order_work_processes[:work_processes_attributes].values
      machine = nil

      # 織機の種類変更がある場合
      # WorkProcessのprocess_estimate_idを更新
      # 変更があった場合の新しいナレッジ
      process_estimates = ProcessEstimate.where(machine_type_id: params[:machine_type_id])
      # 選択されている織機typeと新しいナレッジの織機タイプが一致しているか確認
      if order_params[:machine_assignments_attributes]
        machine = Machine.find_by(id: order_params[:machine_assignments_attributes][0][:machine_id])
      end

      # unless machine&.machine_type == process_estimates.first.machine_type
      #   # type不一致です
      #   flash[:notice] = "織機の種類が一致していないため、更新できません"
      #   render :edit and return
      # end

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
          # if input_start_date < next_start_date
          #   flash[:alert] = "開始日 (#{input_start_date}) は前の工程の完了日 (#{next_start_date}) よりも新しい日付にしてください。"
          #   render :edit and return
          # end
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
        # binding.irb
        target_work_prcess.save
        # 更新したナレッジで全行程の日時の更新処理の呼び出し
        new_target_work_prcess, next_start_date = WorkProcess.check_current_work_process(target_work_prcess, start_date, actual_completion_date)
        # 開始日の方が新しい場合は置き換え
        next_start_date = start_date > next_start_date ? start_date : next_start_date

        new_target_work_prcess.actual_completion_date = actual_completion_date
        new_target_work_prcess.save

      end

      # 織機詳細変更した場合
      if order_params[:machine_assignments_attributes].present?
        # MachineAssignmentの更新
        machine_assignments_params = order_params[:machine_assignments_attributes]
        machine_id = machine_assignments_params[0][:machine_id]
        machine_status_id = machine_assignments_params[0][:machine_status_id]
        # フォームで送られた ID に基づき MachineAssignment を取得
        machine_ids = @order.work_processes.joins(:machine_assignments).pluck('machine_assignments.machine_id').uniq
        if machine_ids.any?
          @order.machine_assignments.each do |assignment|
            assignment.update!(
              machine_id: machine_id.present? ? machine_id : nil ,
              machine_status_id: machine_status_id.present? ? machine_status_id : nil
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
      # Orderの更新
      update_order = order_params.except(:machine_assignments_attributes, :work_processes_attributes)
      if update_order.present?
        @order.update!(update_order)
      end
      set_work_process_status_completed
      handle_machine_assignment_updates if machine_assignments_present?
    end
    redirect_to admin_order_path(@order), notice: "更新されました。"

  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    # トランザクション内でエラーが発生した場合はロールバックされる
    flash[:alert] = "更新に失敗しました: #{e.message}"
    render :edit
  end

  # 削除処理の開始し管理者削除を防ぐロジックはmodelで行う
  def destroy
    if @order.destroy
      # ココ(削除実行直前)でmodelに定義したコールバックが呼ばれる

      flash[:notice] = "発注が削除されました"
    else
      # バリデーションに失敗で@order.errors.full_messagesにエラーメッセージが配列として追加されます
      # .join(", "): 配列内の全てのエラーメッセージをカンマ区切り（, ）で連結
      flash[:alert] = @order.errors.full_messages.join(", ")
    end
    redirect_to admin_orders_path
  end

  private

  def create_order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      work_processes: [
        :id,
        :process_estimate_id,
        :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        :actual_completion_date,
        :start_date,
        process_estimate: [ :machine_type_id ],
        machine_assignments: [ :id, :machine_status_id ]
      ]
    )
  end

  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      machine_assignments_attributes: [:id, :machine_id, :machine_status_id],
      # process_estimate_attributes: [:machine_type_id],
      work_processes_attributes: [ # accepts_nested_attributes_forに対応
        :id,
        # :process_estimate_id,
        # :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        # :earliest_estimated_completion_date,
        # :latest_estimated_completion_date,
        :actual_completion_date,
        :start_date
      ]
    )
  end

  def set_order
    @order = Order.find(params[:id])
    unless @order
      flash[:alert] = "指定された注文が見つかりません。"
      redirect_to admin_orders_path
    end
  end

  def set_work_process
    @work_process = Task.find(params[:id])
  end

  def set_product_number
    @product_number = current_user.product_number
  end

  # 一般ユーザがアクセスした場合には一覧画面にリダイレクト
  def admin_user
    unless current_user&.admin?
      redirect_to orders_path, alert: "管理者以外アクセスできません"
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
    order_params[:machine_assignments_attributes].present?
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
      machine_id = order_params[:machine_assignments_attributes][0][:machine_id].to_i
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
  ## 遅延している作業工程のチェック (indexアクション用)
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
        ->(order) { edit_admin_order_path(order) },
        ->(order) { admin_order_path(order) }
      )
    end
  end

  ## 遅延している作業工程のチェック (showアクション用)
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

  ## 織機選択時のバリデーションを行うメソッド
  def validate_machine_selection
    machine_assignments_params = order_params[:machine_assignments_attributes]
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
