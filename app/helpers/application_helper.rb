module ApplicationHelper
  # 現在作業中の作業工程を取得するヘルパーメソッド
  def find_current_work_process(work_processes)
    # 「作業完了」ステータスの最新の作業工程を取得
    latest_completed_wp = work_processes.joins(:work_process_status)
                                        .where(work_process_statuses: { name: '作業完了' })
                                        .order(start_date: :desc)
                                        .first
    if latest_completed_wp
      # 最新の「作業完了」より後の作業工程を取得
      next_process = work_processes.where('start_date > ?', latest_completed_wp.start_date).order(:start_date).first
      next_process
    else
      # 「作業完了」がない場合、最も古い作業工程を取得
      work_processes.order(:start_date).first
    end
  end
end
