{
  for file in \
    app/assets/config/manifest.js \
    app/assets/stylesheets/application.css \
    app/controllers/admin/machines_controller.rb \
    app/controllers/admin/orders_controller.rb \
    app/controllers/home_controller.rb \
    app/controllers/machines_controller.rb \
    app/controllers/orders_controller.rb \
    app/javascript/application.js \
    app/javascript/components/DragDropApp.js \
    app/javascript/components/DroppableZone.js \
    app/javascript/components/OrderRow.js \
    app/javascript/components/OrderTable.js \
    app/javascript/machine_assignment.js \
    app/javascript/orderform_no_react.js \
    app/javascript/packs/orderform.js \
    app/models/order.rb \
    app/models/work_process.rb \
    app/views/admin/home/index.html.erb \
    app/views/admin/orders/_gant_chart.html.erb \
    app/views/admin/orders/edit.html_back.erb \
    app/views/admin/orders/gant_index.html.erb \
    app/views/admin/orders/ma_index.html.bk.erb \
    app/views/admin/orders/ma_index.html.erb \
    app/views/admin/orders/ma_index_org.html.erb \
    app/views/admin/orders/ma_select_company.html.erb \
    app/views/admin/orders/new.html.erb \
    app/views/admin/orders/new.html_bk.erb \
    "app/views/home/index.html copy.erb" \
    app/views/home/index.html_react.erb \
    app/views/layouts/application.html.erb \
    app/views/machines/edit.html.erb \
    app/views/machines/new.html.erb \
    app/views/sessions/new.html.erb \
    config/environments/production.rb \
    config/importmap.rb \
    config/routes.rb; do
    echo -e "\n\n========================================================="
    echo -e "ファイル: $file"
    echo -e "=========================================================\n"
    git diff --color=always --ignore-space-change main feature-107y1 -- "$file" 2>/dev/null || echo "ファイルの差分を取得できませんでした"
  done
} > all_differences.txt
