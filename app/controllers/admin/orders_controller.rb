class Admin::OrdersController < ApplicationController
  # 定義された関数の使用
  include ApplicationHelper
  include FlashHelper

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
        # 現在のwork_processから工程を検索
        if params[:work_process_definition_id].present?
          is_match = order.current_work_process.work_process_definition_id == params[:work_process_definition_id].to_i
          @current_work_processes[order.id] = is_match ? order.current_work_process : nil
        else
          @current_work_processes[order.id] = order.current_work_process
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
        @current_work_processes[order.id] = order.current_work_process
      else
        @current_work_processes[order.id] = nil
      end
    end
    # 遅延している作業工程のチェック（必要に応じて）
    check_overdue_work_processes_index(@orders)
  end

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
    unless @order.validate_machine_selection(update_order_params[:machine_assignments_attributes], flash)
      # 条件に合わず更新できない場合はここで処理を終了
      flash.now[:alert] = "織機を選択してください"
      render :edit and return
    end

    ActiveRecord::Base.transaction do
      # WorkProcessの更新
      @order.apply_work_process_updates(update_order_params)

      machine_assignments_params = update_order_params[:machine_assignments_attributes]
      # 織機割当を更新（整理加工は織機更新処理をスキップ）
      unless @order.skip_machine_assignment_validation?

        unless @order.update_machine_assignment(machine_assignments_params)
          flash.now[:alert] = "織機割当が不正です"
          render :edit and return
        end
      end

      # Orderの更新
      @order.update_order_details(update_order_params)

      @order.set_work_process_status_completed

      @order.handle_machine_assignment_updates(machine_assignments_params) if machine_assignments_present?
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

    # 会社を選択
    def ma_select_company
      @companies = Company.all
    end

    #
    def ma_index
      @current_company = Company.find(params[:company_id])

      @orders = @current_company.orders
      .includes(work_processes: [:work_process_definition, :work_process_status, process_estimate: :machine_type])
      .incomplete
      .order(:id)


      @machine_names = @current_company.machines.pluck(:name)

      @assigned_orders = {}
      @unassigned_orders = []
      @orders.each do |order|
        # 織機割り当て済の場合
        if order.latest_machine_assignment.present?
          machine = order.latest_machine_assignment.machine
          machine_name = machine.name
          # machine_id = order.latest_machine_assignment.machine.id
          @assigned_orders[machine_name] = @assigned_orders[machine_name] || []
          @assigned_orders[machine_name] << order
        else
          # 未割当の商品の場合
          @unassigned_orders << order
        end
      end

      @no_orders_message = "現在受注している商品はありません" unless @orders.any?

      # 各注文に対して現在作業中の作業工程を取得
      @current_work_processes = {}
      @orders.each do |order|

        work_process = WorkProcess.find_by(order_id: order.id)
        @current_work_processes[order.id] = work_process
      # order.id をキーとして、対応する WorkProcess を格納
      # @current_work_processes[order.id] = current_work_process
      # current_process = @current_work_processes[:id]
        if order.work_processes.any?
          # 現在のwork_processから工程を検索
          if params[:work_process_definition_id].present?
            is_match = order.current_work_process.work_process_definition_id == params[:work_process_definition_id].to_i
            @current_work_processes[order.id] = is_match ? order.current_work_process : nil
          else
            @current_work_processes[order.id] = order.current_work_process

          end
        else
          @current_work_processes[order.id] = nil
        end

      end
    end

    # ガントチャート
    def gant_index
      # 発注情報の取得
      @orders = Order.includes(:work_processes, :company, work_processes: [:work_process_definition, :work_process_status, process_estimate: :machine_type])

      # 過去の発注に関連付けられていない機械を取得
      @machines = Machine.not_in_past_orders

      # 受注中のみ表示
      @orders = @orders.select do |order|
        order.work_processes.any? do |process|
          if process.machine_assignments.empty?
            true # 織機割り当てのない発注も表示
          else
            # machine_assignments が存在する場合は、assignment の machine_id が @machines の中に含まれているかを確認
            process.machine_assignments.any? do |assignment|
              @machines.map { |machine| machine.id }.include?(assignment.machine_id)
            end
          end
        end
      end

      # JSON フォーマット用のマッピング処理
      @orders = @orders.map do |order|
        order.work_processes.map do |process|
          # 作業状態に基づいてカスタムクラスを決定
          custom_class = case process.work_process_status.name
                         when '作業前'
                           'status-pending'
                         when '作業中'
                           'status-in-progress'
                         when '作業完了'
                           'status-completed'
                         when '確認中'
                           'status-under-review'
                         else
                           'status-default'
                         end

          {
            product_number: order.product_number.number,
            company: order.company.name,
            machine: machine_names(order), # 単一の織機を取得
            id: process.id.to_s,
            name: process.work_process_definition.name,
            work_process_status: process.work_process_status.name,
            end: process&.earliest_estimated_completion_date&.strftime("%Y-%m-%d"),
            start: process&.start_date&.strftime("%Y-%m-%d"),
            progress: 100,
            custom_index: order.id,
            custom_class: custom_class
          }
        end
      end.compact.flatten.to_json
    end


  private

  # WorkProcess の更新を担当（管理画面用）
  def apply_work_process_updates
    # ネストされた作業工程パラメータを抽出
    order_work_processes = update_order_params.except(:machine_assignments_attributes)
    workprocesses_params = order_work_processes[:work_processes_attributes]&.values || []

    # 織機タイプを決定
    if update_order_params[:machine_assignments_attributes].present?
      machine = Machine.find_by(id: update_order_params[:machine_assignments_attributes][0][:machine_id])
      machine_type_id = machine&.machine_type_id
    else
      machine_type_id = @order.work_processes.first&.process_estimate&.machine_type_id if @order.work_processes.any?
    end

    all_work_processes = @order.work_processes

    # 自動開始日調整を含む一括更新
    WorkProcess.update_work_processes(workprocesses_params, all_work_processes, machine_type_id)
  end

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

  def update_order_params
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

  # def set_product_number
  #   @product_number = current_user.product_number
  # end

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
    update_order_params[:machine_assignments_attributes].present?
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


  # # 工程ステータスを完了にすると、現工程以前のステータスも完了に更新し、日付も自動入力、または入力値を反映させる
  # def set_work_process_status_completed
  #   completed_id = WorkProcessStatus.find_by!(name: "作業完了").id

  #   @order.work_processes.each do |work_process|
  #     status_completed   = (work_process.work_process_status_id == completed_id) # ステータスを完了に変更した場合
  #     date_inputed = work_process.actual_completion_date if work_process.actual_completion_date.present? # 完了日付を入力した場合

  #     next unless status_completed || date_inputed
  #     update_date = date_inputed ? work_process.actual_completion_date : Date.current
  #     work_process.unify_previous_completion(update_date, completed_id)
  #     end
  # end



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

    if overdue_work_processes.exists? # flashメッセージを追加
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

  # ## 織機選択時のバリデーションを行うメソッド
  # def validate_machine_selection
  #   # 整理加工はvalidation不要
  #   return true if @order.skip_machine_assignment_validation?

  #   machine_assignments_params = update_order_params[:machine_assignments_attributes]

  #   # 織機が未指定の場合はバリデーションエラー
  #   if machine_assignments_params.blank? || machine_assignments_params[0][:machine_id].blank?
  #     flash.now[:alert] = "織機を選択してください。"
  #     return false
  #   end

  #   selected_machine_id = machine_assignments_params[0][:machine_id].to_i
  #   selected_machine = Machine.find_by(id: selected_machine_id)

  #   # 存在しない織機の場合は特にチェックしない（別エラーになるはず）
  #   return true unless selected_machine

  #   order_machine_type_name = @order&.work_processes&.first&.process_estimate&.machine_type&.name
  #   selected_machine_type_name = selected_machine.machine_type.name

  #   # 1. 織機タイプのチェック
  #   if order_machine_type_name.present? && order_machine_type_name != selected_machine_type_name
  #     # 新しいmachine_typeが一致する場合は変更を許可
  #     return true if permit_change_machine_type_same_time(selected_machine_type_name)

  #     flash.now[:alert] = "織機のタイプが異なります。別の織機を選択してください。"
  #     return false
  #   end

  #   # 2. 既に割り当てられているかチェック
  #   # 他の未完了の受注に同じ織機が割り当てられていないかを確認
  #   # 未完了の作業工程がある受注で同じ織機を使用している場合はエラー
  #   incomplete_orders_using_machine = Order
  #     .incomplete
  #     .joins(:machine_assignments)
  #     .where(machine_assignments: { machine_id: selected_machine_id })
  #     .where.not(id: @order.id) # 自分自身は除外
  #   if incomplete_orders_using_machine.exists?
  #     flash.now[:alert] = "選択した織機は既に他の未完了の受注で使用されています。別の織機を選択してください。"
  #     return false
  #   end

  #   # 条件3: machine_status_idが4（使用できない状態）の場合
  #   current_assignment = selected_machine.machine_assignments.order(created_at: :desc).first
  #   current_machine_status_id = current_assignment&.machine_status_id
  #   # binding.irb
  #   # current_machine_status_idが4ならエラーメッセージを表示する例
  #   if current_machine_stunless @order.validate_machine_selectiontus_id == 4
  #     flunless @order.validate_machine_selectionsh.now[:alert] = "選択した織機は現在故障中です。別の織機を選択してください。"
  #     return false
  #   end

  #   true # 呼び出し元の処理を続ける
  # end



  # # 同時にmachine_typeが変更される場合は許可
  # def permit_change_machine_type_same_time(selected_machine_type_name)
  #   return false unless params[:machine_type_id].present?

  #   new_machine_type = MachineType.find_by(id: params[:machine_type_id])
  #   return false unless new_machine_type && new_machine_type.name == selected_machine_type_name

  #   @order.work_processes.each do |work_process|
  #     process_estimate = ProcessEstimate.find_by(
  #       work_process_definition_id: work_process.work_process_definition_id,
  #       machine_type_id: new_machine_type.id
  #     )
  #     work_process.update!(process_estimate: process_estimate)
  #   end

  #   true # 呼び出し元の処理を続ける
  # end



end
