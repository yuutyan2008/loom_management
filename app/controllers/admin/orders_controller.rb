class Admin::OrdersController < ApplicationController
  # 定義された関数の使用
  include ApplicationHelper
before_action :order_params, only: [:create,  :update]
before_action :set_order, only: [:edit, :show, :update, :destroy]
# before_action :work_process_params, only: [:create, :update]
before_action :admin_user

  def index
    @orders = Order.includes(work_processes: [:work_process_definition, :work_process_status, process_estimate: :machine_type])

    # 各注文に対して現在作業中の作業工程を取得
    @current_work_processes = {}
    @orders.each do |order|
      if order.work_processes.any?
        @current_work_processes[order.id] = order.work_processes.current_work_process
      else
        @current_work_processes[order.id] = nil
      end
    end
  end

  def new
    @order = Order.new
    @work_process = WorkProcess.new
  end

  def create
    # orderテーブル以外を除外してorderインスタンス作成
    # マージしてOrderに保存
    # start_date = params[:work_process][:start_date]
    # @order = Order.new(order_params.merge(start_date: start_date))
    # @order = Order.new(order_params)

    @order = Order.new(order_params.except(:work_processes))

    # work_processesのパラメータ取得
    # ハッシュの値部分のみを配列として取得
    work_processes = order_params[:work_processes].values.first

    # ハッシュのキー"start_date"を引数にパラメータを取得
    start_date = work_processes["start_date"]
    machine_type_id = work_processes["process_estimate"]["machine_type_id"].to_i

    # # earliest_estimated_completion_dateの値を定義
    # # earliest_estimated_completion_date = start_date + "日数を返す関数"

    # # 5個のwork_processインスタンスを作成
    # workprocesses = WorkProcess.initial_processes_list(start_date)

    # # インスタンスの更新
    # # process_estimate_idを入れる

    # # インスタンスの更新
    # # 完了見込日時を入れる
    # updated_workprocesses = WorkProcess.update_deadline(workprocesses, machine_type_id, start_date)
    # # 関連付け
    # @order.work_processes.build(updated_workprocesses)
    # # binding.irb
    # @order.save

    # redirect_to admin_orders_path, notice: "注文が作成されました"
      # 5個のwork_processハッシュからなる配列を作成
      workprocesses = WorkProcess.initial_processes_list(start_date)
      # インスタンスの更新
      # process_estimate_idを入れる
      estimate_workprocesses = WorkProcess.decide_machine_type(workprocesses, machine_type_id)
      # インスタンスの更新
      # 完了見込日時を入れる
      update_workprocesses = WorkProcess.update_deadline(estimate_workprocesses, start_date)
      # ５個のハッシュとorderの関連付け
      update_workprocesses.each do |work_process_data|
        @order.work_processes.build(work_process_data)
      end
      @order.save
      redirect_to admin_orders_path, notice: "注文が作成されました"
  end

  def show
    @work_process = @order.work_processes.ordered

    # 織機データを取得
    @machines = Machine.joins(work_processes: :order)
                       .where(work_processes: { order_id: @order.id })
                       .distinct
  end

  def edit
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
    end
    @work_processes = @order.work_processes.ordered
    @machine_statuses = machine_statuses_for_order(@order)
  end

  def update

    @order.update(order_params.except(:work_processes_attributes))
    binding.irb
    # strongparameterで許可されたフォームのname属性値を取得
    work_processes_params = order_params[:work_processes_attributes]
    work_processes_id = work_processes_params["id"].to_i
      binding.irb
    # フォームから取得したIDでDBからデータ取得
      work_process = WorkProcess.find(work_processes_id)
    binding.irb

      # machine_assignments の処理
      machine_assignments_params = order_params[:work_processes][:machine_assignments]
      binding.irb
      if machine_assignments_params[:machine_assignments].present?
        # machine_assignments_params[:machine_assignments].each do |assignment_params|
        machine_assignments_id = machine_assignments_params["id"].to_i
        binding.irb
        machine_assignments = work_process.machine_assignments.find(machine_assignments_id)
        binding.irb
          unless machine_assignments.update(machine_status_id: machine_assignments_params[:work_processes][:machine_assignments][:machine_status_id])
            flash[:alert] = "機械割り当ての更新に失敗しました"
            redirect_to edit_admin_order_path(@order) and return
          end
        # machine_assignmentsを削除して残りのWorkProcess属性を更新
        work_process_params.delete(:machine_assignments)
        binding.irb
      end

      # WorkProcessの更新
      unless work_process.update(work_process_params.except(:machine_assignments))
        flash[:alert] = "作業工程の更新に失敗しました"
        binding.irb
        redirect_to edit_admin_order_path(@order) and return
      end

    # 更新後に並び替えを行う
    @work_processes = @work_processes.joins(:work_process_definition)
    .order("work_process_definitions.sequence ASC")

    redirect_to admin_order_path(@order), notice: "作業工程が更新されました。"
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

  # def order_params
  #   params.require(:order).permit(
  #     :company_id,
  #     :product_number_id,
  #     :color_number_id,
  #     :roll_count,
  #     :quantity,
  #     work_processes: [
  #       :id,
  #       :process_estimate_id,
  #       :work_process_definition_id,
  #       :work_process_status_id,
  #       :factory_estimated_completion_date,
  #       :actual_completion_date,
  #       :start_date,
  #       process_estimate: [:machine_type_id],
  #       machine_assignments: [:id, :machine_status_id]
  #     ]
  #   )
  # end

  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      work_processes_attributes: [ # accepts_nested_attributes_forに対応
        :id,
        :process_estimate_id,
        :work_process_definition_id,
        :work_process_status_id,
        :factory_estimated_completion_date,
        :actual_completion_date,
        :start_date,
        process_estimate: [:machine_type_id],
        machine_assignments_attributes: [ # accepts_nested_attributes_forに対応
          :id,
          :machine_status_id,
          :machine_id, # 必要に応じて追加
        ]
      ]
    )
  end


  # def update_work_processes
  #   # パラメータから work_processes を取得
  #   work_processes_params = params[:work_processes] || {}

  #   work_processes_params.each do |id, attributes|
  #     work_process = WorkProcess.find(id)

  #     # 子モデルを更新
  #     work_process.update(
  #       status_id: attributes[:status_id],
  #       start_date: attributes[:start_date]
  #     )
  #   end
  # end

  def set_order
    @order = Order.find(params[:id])
  end

  # 一般ユーザがアクセスした場合には一覧画面にリダイレクト
  def admin_user
    unless current_user&.admin?
      redirect_to orders_path, alert: "管理者以外アクセスできません"
    end
  end
end
