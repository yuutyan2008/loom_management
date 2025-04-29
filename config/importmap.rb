# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "gantt-fix", to: "frappe-gantt.es.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "orderform_no_react"
pin "jquery", to: "https://code.jquery.com/jquery-3.6.4.min.js"
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"
