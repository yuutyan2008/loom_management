# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "gantt-fix", to: "frappe-gantt.es.js"
pin "orderform_no_react"
pin "gantt_global"

pin "@rails/request.js", to: "request.js", preload: true
