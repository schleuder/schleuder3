# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_01_18_170110) do

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email", limit: 255
    t.string "fingerprint", limit: 255
    t.string "log_level", limit: 255, default: "warn"
    t.string "subject_prefix", limit: 255, default: ""
    t.string "subject_prefix_in", limit: 255, default: ""
    t.string "subject_prefix_out", limit: 255, default: ""
    t.string "openpgp_header_preference", limit: 255, default: "signencrypt"
    t.text "public_footer", default: ""
    t.text "headers_to_meta", default: "[\"from\", \"to\", \"cc\", \"date\", \"sig\", \"enc\"]"
    t.text "bounces_drop_on_headers", default: "{\"x-spam-flag\":\"yes\"}"
    t.text "keywords_admin_only", default: "[\"subscribe\", \"unsubscribe\", \"delete-key\"]"
    t.text "keywords_admin_notify", default: "[\"add-key\"]"
    t.boolean "send_encrypted_only", default: true
    t.boolean "receive_encrypted_only", default: false
    t.boolean "receive_signed_only", default: false
    t.boolean "receive_authenticated_only", default: false
    t.boolean "receive_from_subscribed_emailaddresses_only", default: false
    t.boolean "receive_admin_only", default: false
    t.boolean "keep_msgid", default: true
    t.boolean "bounces_drop_all", default: false
    t.boolean "bounces_notify_admins", default: true
    t.boolean "include_list_headers", default: true
    t.boolean "include_openpgp_header", default: true
    t.integer "max_message_size_kb", default: 10240
    t.string "language", limit: 255, default: "en"
    t.boolean "forward_all_incoming_to_admins", default: false
    t.integer "logfiles_to_keep", default: 2
    t.text "internal_footer", default: ""
    t.boolean "deliver_selfsent", default: true
    t.boolean "include_autocrypt_header", default: true
    t.boolean "set_reply_to_to_sender", default: false
    t.boolean "munge_from", default: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "list_id"
    t.string "email", limit: 255
    t.string "fingerprint", limit: 255
    t.boolean "admin", default: false
    t.boolean "delivery_enabled", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email", "list_id"], name: "index_subscriptions_on_email_and_list_id", unique: true
    t.index ["list_id"], name: "index_subscriptions_on_list_id"
  end

end
