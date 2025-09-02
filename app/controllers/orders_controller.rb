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


  def update
    machine_assignments_params = update_order_params[:machine_assignments_attributes]
    selected_machine_type_id = update_order_params[:machine_type_id] # 現在の織機の種類に変更がある場合値が入る

    # ここで織機の選択条件を検証
    unless @order.validate_machine_selection(machine_assignments_params, new_machine_type_id: selected_machine_type_id)
      flash.now[:alert] = "織機の種類と織機が一致しません"
      return render :edit
    end

    # 現在の工程が整理加工の場合
    skip_ma = @order.skip_machine_assignment_validation?

    ActiveRecord::Base.transaction do
      # WorkProcessの更新
      @order.apply_work_process_updates(update_order_params)

      # 織機割当を更新（整理加工は織機更新処理をスキップ）
      unless skip_ma
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
    redirect_to order_path(@order), notice: "更新されました。"

  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    # トランザクション内でエラーが発生した場合はロールバックされる
    flash[:alert] = "更新に失敗しました: #{e.message}"
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
      :machine_type_id, # allow machine type under order
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

  # WorkProcess の更新を担当（一般画面用）
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
end
