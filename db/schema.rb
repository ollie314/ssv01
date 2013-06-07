# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130128165307) do

  create_table "addresses", :force => true do |t|
    t.string   "street_address1"
    t.string   "street_address2"
    t.string   "zip_code"
    t.string   "addressable_type"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "addressable_id"
    t.integer  "contact_info_kind_id"
    t.integer  "city_id"
    t.integer  "area_id"
    t.integer  "district_id"
    t.integer  "state_id"
    t.integer  "country_id"
  end

  create_table "admin_agencies", :force => true do |t|
    t.string   "name"
    t.string   "website"
    t.string   "mail"
    t.string   "logo"
    t.text     "info"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "phone"
  end

  create_table "admin_agency_users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.string   "firstname"
    t.string   "lastname"
    t.integer  "rights"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "agency_infos", :force => true do |t|
    t.string   "logo"
    t.text     "summary"
    t.text     "description"
    t.integer  "agency_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "agency_items", :force => true do |t|
    t.string   "name"
    t.integer  "standing_id"
    t.integer  "admin_agency_id"
    t.integer  "item_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "agency_languages", :force => true do |t|
    t.boolean  "is_default"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "agency_info_id"
    t.integer  "language_id"
  end

  create_table "areas", :force => true do |t|
    t.string   "name"
    t.integer  "district_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "carts", :force => true do |t|
    t.string   "name"
    t.float    "amount"
    t.boolean  "checked_out"
    t.integer  "client_id"
    t.datetime "checkout_date"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.string   "zipcode"
    t.integer  "area_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "contact_info_kinds", :force => true do |t|
    t.string   "name"
    t.string   "internal_name"
    t.text     "description"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "countries", :force => true do |t|
    t.string   "iso"
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "districts", :force => true do |t|
    t.string   "name"
    t.integer  "state_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "item_attachment_kinds", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "item_attachments", :force => true do |t|
    t.string   "name"
    t.string   "label"
    t.text     "description"
    t.string   "path"
    t.integer  "item_id"
    t.integer  "item_attachment_kind_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "item_groups", :force => true do |t|
    t.string   "name"
    t.string   "internal_name"
    t.text     "description"
    t.integer  "agency_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "item_groups_items", :force => true do |t|
    t.integer "item_group_id"
    t.integer "item_id"
  end

  create_table "item_kinds", :force => true do |t|
    t.string   "name"
    t.string   "internal_name"
    t.text     "description"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "item_properties", :force => true do |t|
    t.string   "name"
    t.integer  "agency_id"
    t.integer  "item_property_kind_id"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "item_properties_item_property_sets", :force => true do |t|
    t.integer "item_property_set_id"
    t.integer "item_property_id"
  end

  create_table "item_property_kinds", :force => true do |t|
    t.string   "name"
    t.string   "internal_name"
    t.text     "description"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "item_property_sets", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "agency_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "item_property_values", :force => true do |t|
    t.text     "value"
    t.integer  "item_property_id"
    t.integer  "item_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "items", :force => true do |t|
    t.string   "internal_name"
    t.integer  "standing_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "item_kind_id"
  end

  create_table "languages", :force => true do |t|
    t.string   "iso2"
    t.string   "iso3"
    t.string   "ietf"
    t.string   "name"
    t.string   "flag"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "standings", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "states", :force => true do |t|
    t.string   "name"
    t.integer  "country_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
