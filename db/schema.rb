# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_12_26_101814) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "color_numbers", force: :cascade do |t|
    t.string "color_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machine_assignments", force: :cascade do |t|
    t.bigint "work_process_id"
    t.bigint "machine_id"
    t.bigint "machine_status_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_id"], name: "index_machine_assignments_on_machine_id"
    t.index ["machine_status_id"], name: "index_machine_assignments_on_machine_status_id"
    t.index ["work_process_id"], name: "index_machine_assignments_on_work_process_id"
  end

  create_table "machine_statuses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machine_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "machines", force: :cascade do |t|
    t.bigint "machine_type_id"
    t.bigint "company_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_machines_on_company_id"
    t.index ["machine_type_id"], name: "index_machines_on_machine_type_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "company_id"
    t.bigint "product_number_id"
    t.bigint "color_number_id"
    t.integer "roll_count"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color_number_id"], name: "index_orders_on_color_number_id"
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["product_number_id"], name: "index_orders_on_product_number_id"
  end

  create_table "process_estimates", force: :cascade do |t|
    t.bigint "work_process_definition_id"
    t.bigint "machine_type_id"
    t.integer "earliest_completion_estimate"
    t.integer "latest_completion_estimate"
    t.date "update_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_type_id"], name: "index_process_estimates_on_machine_type_id"
    t.index ["work_process_definition_id"], name: "index_process_estimates_on_work_process_definition_id"
  end

  create_table "product_numbers", force: :cascade do |t|
    t.string "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.bigint "company_id"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.index ["company_id"], name: "index_users_on_company_id"
  end

  create_table "work_process_definitions", force: :cascade do |t|
    t.string "name"
    t.integer "sequence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_process_statuses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_processes", force: :cascade do |t|
    t.bigint "order_id"
    t.bigint "process_estimate_id"
    t.bigint "work_process_status_id"
    t.bigint "work_process_definition_id"
    t.date "start_date"
    t.date "earliest_estimated_completion_date"
    t.date "latest_estimated_completion_date"
    t.date "factory_estimated_completion_date"
    t.date "actual_completion_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_work_processes_on_order_id"
    t.index ["process_estimate_id"], name: "index_work_processes_on_process_estimate_id"
    t.index ["work_process_definition_id"], name: "index_work_processes_on_work_process_definition_id"
    t.index ["work_process_status_id"], name: "index_work_processes_on_work_process_status_id"
  end
end
