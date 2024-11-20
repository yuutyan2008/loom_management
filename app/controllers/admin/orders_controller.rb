class Admin::OrdersController < ApplicationController

  # after_action :create_work_process, only: %i[create]
  after_action :order_params, only: %i[update destroy]


  def index
    @work_processes=WorkProcess.all
  end

  def new
    @work_processes = WorkProcess.new
  end

  def create

    # 他モデルを除外して
    @order = Order.new(order_params.except(:work_processes_attributes))
    @order.work_processes.build(
      WorkProcess.initial_processes_list
    )

    # 保存処理
    # binding.irb
    if @order.save
      if params[:order][:work_process_definition_id].present?
        @order.work_processes.create(
          work_process_definition_id: params[:order][:work_process_definition_id]
        )
      end

      redirect_to admin_orders_path, notice: "注文が作成されました"
    else
      flash.now[:alert] = @order.errors.full_messages.join(", ")
      render :new
    end
  end

  def show
    @order = Order.find(params[:id])
  end
  def edit
    @order = Order.find_by(id: params[:id])
    if @order.nil?
      Rails.logger.debug "注文が見つかりません"
      # もしくは以下のコードで例外を投げる
      raise "注文が見つかりません"
    end
  end

  def update
    @order = Order.find(params[:id])

    if @order.update(order_params)
      # 国際化（i18n）
      # ja.yml に定義したフラッシュメッセージに翻訳
      # binding.irb
      flash[:notice] = t("flash.admin.updated")


      redirect_to admin_orders_path
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ") # エラーメッセージを追加
      render :edit
    end
  end

  # 削除処理の開始し管理者削除を防ぐロジックはmodelで行う
  def destroy

    @order = Order.find(params[:id])
    if @order.destroy
      # ココ(削除実行直前)でmodelに定義したコールバックが呼ばれる

      flash[:notice] = t("flash.admin.destroyed")
    else
      # バリデーションに失敗で@user.errors.full_messagesにエラーメッセージが配列として追加されます
      # .join(", "): 配列内の全てのエラーメッセージをカンマ区切り（, ）で連結
      flash[:alert] = @order.errors.full_messages.join(", ")
    end
    redirect_to admin_orders_path
  end

  private
  # フォームの入力値のみ許可
  def work_processes_params
    params.require(:work_processes).permit(
      :order_id,
      :process_estimate_id,
      :work_process_status_id,
      :work_process_definition_id,
      :start_date,
      :earliest_estimated_completion_date,
      :latest_estimated_completion_date,
      :factory_estimated_completion_date,
      :actual_completion_date,
      order_attributes: [
        :company_id,
        :product_number_id,
        :color_number_id,
        :roll_count,
        :quantity,
        :start_date
      ],

    )
  end


  # def order_params
  #   params.require(:order).permit(
  #     :company_id,
  #     :product_number_id,
  #     :color_number_id,
  #     :roll_count,
  #     :quantity,
  #     :start_date,
  #     work_processes_attributes: [
  #       :work_process_definition_id,
  #       :work_process_status_id,
  #       :factory_estimated_completion_date,
  #       :id, # 更新時に必要
  #       :_destroy # 削除時に必要
  #     ]
  #   )



  # work_process_definition_idを登録
  # def create_work_process
  #   work_process_definition_id = params[:order][:work_process_definition_id]
  #   return unless work_process_definition_id.present?

  #   # 新しい作業工程を作成
  #   @order.work_processes.create(work_process_definition_id: work_process_definition_id)
  # end



end
