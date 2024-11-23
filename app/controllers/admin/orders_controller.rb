class Admin::OrdersController < ApplicationController
before_action :order_params, only: [:create,  :update]
before_action :work_processes_params, only: [:update_work_processes]
before_action :set_order, only: [:edit, :show, :update, :destroy, :edit_work_processes, :update_work_processes]
before_action :admin_user

  def index
    @orders = Order.includes(work_processes: [:work_process_definition, :work_process_status, :process_estimate])
  end

  def new
    @order = Order.new
  end

  def create
    # orderテーブル以外を除外してorderインスタンス作成
    @order = Order.new(order_params.except(:factory_estimated_completion_date, :start_date))
    # orderの子オブジェクトのworkProcessインスタンス作成
    @order.work_processes.build(
      # 一括作成したレコードを呼び出して初期値を入れる
      WorkProcess.initial_processes_list(order_params[:start_date])
    )

    # order、work_processes保存
    if @order.save
      # work_processes更新
      @order.work_processes.each do |process|
        process.update(
        factory_estimated_completion_date: order_params[:factory_estimated_completion_date])
      end
      redirect_to admin_orders_path, notice: "注文が作成されました"
    else
      flash.now[:alert] = @order.errors.full_messages.join(", ")
      render :new
    end
  end

  def show
    @order
  end

  def edit
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
      raise "注文が見つかりません"
    end
  end

  def update
    if @order.update(order_params)
      # 国際化（i18n）
      # ja.yml に定義したフラッシュメッセージに翻訳
      # binding.irb
      flash[:notice] = "発注が更新されました"


      redirect_to admin_order_path(@order)
    else
      flash.now[:alert] = @order.errors.full_messages.join(", ") # エラーメッセージを追加
      render :edit
    end
  end

  # 作業工程の編集
  def edit_work_processes
    # 必要なデータを渡す
    @work_processes = @order.work_processes
  end

  # 作業工程の更新
  def update_work_processes
    # strongparameterで許可されたフォームのname属性値を取得
    permitted_params = work_processes_params.to_h
    # フォームデータからIDを取得
    work_process_ids = permitted_params.keys
    # IDを指定してDBからデータ取得
    @work_processes = WorkProcess.where(id: work_process_ids)

    # success = true # フラグ初期化
    @work_processes.each do |work_process|
      # フォームデータからこのレコードに対応するパラメータを取得、idを文字列に変換
      update_record = permitted_params[work_process.id.to_s]

      # 更新処理を実行
      unless work_process.update(update_record)

        flash.now[:alert] = "作業工程の更新に失敗しました。"
        render :edit_work_processes and return
      end

    end
    binding.irb
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
  # フォームの入力値のみ許可
  def order_params
    params.require(:order).permit(
      :company_id,
      :product_number_id,
      :color_number_id,
      :roll_count,
      :quantity,
      # :start_date, # 重複のためorderテーブルのstart_dateを削除
      :factory_estimated_completion_date,
      :earliest_estimated_completion_date,
      :latest_estimated_completion_date,
      :actual_completion_date,
      :start_date,
    )
  end

  def work_processes_params
    permitted = {}
    params[:work_processes].keys.each do |key|
      permitted[key] = [
        :id,
        :work_process_status_id,
        :start_date,
        :earliest_estimated_completion_date,
        :latest_estimated_completion_date,
        :factory_estimated_completion_date,
        :actual_completion_date
      ]
    end
    params.require(:work_processes).permit(permitted)
  end


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
