require 'rails_helper'

RSpec.describe "Home Page", type: :system do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:machine) { create(:machine, company: company) }
  let(:order) { create(:order, company: company) }
  let(:work_process) { create(:work_process, order: order) }

  before do
    driven_by(:selenium_chrome_headless) # Chromeのヘッドレスモードを使用

    # ログイン画面にアクセスしてログインする
    visit "/login"  # 実際のログインパスに置き換えてください
    fill_in "session_email", with: user.email
    fill_in "session_password", with: "password123"
    click_button "ログイン"

    # 必要なデータを準備
    machine.work_processes << work_process
    visit root_path
  end

  it "作業開始ボタンを押して正常に更新される" do
    expect(page).to have_content("作業開始")

    # ボタンを押す
    click_button "作業開始"

    # フラッシュメッセージが表示されるか確認
    expect(page).to have_content("ステータスが正常に更新されました。")

    # ページの情報が更新されたか確認（必要に応じて表示されるデータを検証）
    expect(page).to have_content("作業終了")
  end
end
