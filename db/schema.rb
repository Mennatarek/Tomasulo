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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141217160219) do

  create_table "activities", force: true do |t|
    t.integer  "instruction_memory_id"
    t.string   "instruction_memory_value"
    t.integer  "fetched"
    t.integer  "issued"
    t.integer  "executed"
    t.integer  "written"
    t.integer  "commited"
    t.integer  "cycle_id"
    t.integer  "number"
    t.boolean  "flushed",                    default: false
    t.integer  "reservation_station_number"
    t.integer  "rob_number"
    t.integer  "waiting"
    t.boolean  "started_writing"
    t.boolean  "started_reading"
    t.boolean  "finished_writing"
    t.boolean  "finished_reading"
    t.integer  "data_cache_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cache_levels", force: true do |t|
    t.integer  "number"
    t.integer  "size"
    t.integer  "line_size"
    t.integer  "associativity"
    t.integer  "offset_bits"
    t.integer  "tag_bits"
    t.integer  "index_bits"
    t.integer  "sets"
    t.string   "policy"
    t.integer  "number_of_cycles_to_access_data"
    t.integer  "program_id"
    t.string   "cache_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "common_data_buses", force: true do |t|
    t.integer  "cycle_id"
    t.integer  "activity_number"
    t.string   "register_name"
    t.string   "address"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cycles", force: true do |t|
    t.integer  "program_id"
    t.integer  "cycle_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_caches", force: true do |t|
    t.integer  "cache_level_id"
    t.string   "address"
    t.string   "value"
    t.integer  "cycle_id"
    t.boolean  "dirty_bit"
    t.boolean  "hit"
    t.boolean  "is_changed"
    t.string   "offset"
    t.string   "tag"
    t.string   "index"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_memories", force: true do |t|
    t.string   "address"
    t.string   "value"
    t.integer  "cycle_id"
    t.boolean  "is_changed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instruction_buffers", force: true do |t|
    t.integer  "instruction_memory_id"
    t.integer  "cycle_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "instruction_memories", force: true do |t|
    t.string   "instruction_type"
    t.string   "name"
    t.string   "rs_name"
    t.string   "rt_name"
    t.string   "rd_name"
    t.string   "imm_value"
    t.integer  "number_of_cycles"
    t.integer  "program_id"
    t.string   "address"
    t.string   "value"
    t.boolean  "is_changed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mem_accesses", force: true do |t|
    t.integer  "cycle_id"
    t.integer  "cache_level_id"
    t.string   "mem_type"
    t.boolean  "is_read"
    t.boolean  "is_write"
    t.boolean  "hit"
    t.integer  "program_id"
    t.integer  "data_memory_id"
    t.integer  "instruction_memory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "programs", force: true do |t|
    t.text     "labels"
    t.string   "counter"
    t.string   "name"
    t.text     "code"
    t.text     "data"
    t.integer  "main_memory_access_time"
    t.integer  "memory_capacity"
    t.integer  "starting_address"
    t.integer  "pipeline_width"
    t.integer  "size_of_instruction_buffer"
    t.integer  "number_of_rob_enteries"
    t.integer  "_activity_counter",              default: 0
    t.text     "number_of_reservation_stations"
    t.text     "number_of_cycles_needed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "register_files", force: true do |t|
    t.integer  "cycle_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registers", force: true do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "register_file_id"
    t.boolean  "is_changed"
    t.integer  "status",           default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reservation_stations", force: true do |t|
    t.integer  "remaining_cycles"
    t.string   "station_type"
    t.string   "name"
    t.boolean  "busy",             default: false
    t.string   "operation"
    t.string   "vk"
    t.string   "vj"
    t.integer  "qj"
    t.integer  "qk"
    t.integer  "destination"
    t.string   "address"
    t.integer  "cycle_id"
    t.integer  "number"
    t.boolean  "flushed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "robs", force: true do |t|
    t.integer  "number"
    t.string   "instruction_type"
    t.string   "destination_register_name"
    t.string   "value"
    t.boolean  "ready"
    t.boolean  "tail"
    t.boolean  "head"
    t.integer  "cycle_id"
    t.boolean  "flushed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
