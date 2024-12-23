module FlashHelper
  # フラッシュアラート用の構造化データを生成
  def build_flash_alert_message(title, orders, edit_path_helper, detail_path_helper)
    {
      title: title,
      messages: orders.map do |order|
        {
          company_name: order&.company&.name,
          order_id: order&.id,
          edit_path: edit_path_helper.call(order),
          detail_path: detail_path_helper.call(order)
        }
      end
    }
  end

  # フラッシュ通知用の構造化データを生成
  def build_flash_notice_message(message)
    {
      title: "通知",
      messages: [
        { content: message }
      ]
    }
  end

  # 管理者マシンのフラッシュメッセージ用
  def build_flash_machine_status_message(title, machines, detail_path_helper = nil, edit_path_helper = nil)
    {
      title: title,
      messages: machines.map do |machine|
        message = {
          machine_name: machine&.name,
          company_name: machine&.company&.name,
          machine_status: machine&.latest_machine_status&.name || 'ー',
        }
        message[:detail_path] = detail_path_helper.call(machine) if detail_path_helper
        message[:edit_path] = edit_path_helper.call(machine) if edit_path_helper
        message
      end
    }
  end
end
