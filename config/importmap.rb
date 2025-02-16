# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "gantt-fix", to: "frappe-gantt.es.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap 4のJavaScript（bundle版）
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"

# jQuery
pin "jquery", to: "https://code.jquery.com/jquery-3.6.4.min.js"
