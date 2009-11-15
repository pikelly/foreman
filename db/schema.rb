# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090820162618) do

  create_table "architectures", :force => true do |t|
    t.string   "name",       :limit => 10, :default => "x86_64", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "domains", :force => true do |t|
    t.string   "name",                     :default => "", :null => false
    t.string   "dnsserver"
    t.string   "gateway",    :limit => 40
    t.string   "fullname",   :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "environments", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "environments_puppetclasses", :id => false, :force => true do |t|
    t.integer "puppetclass_id", :null => false
    t.integer "environment_id", :null => false
  end

  create_table "fact_names", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "fact_names", ["id"], :name => "index_fact_names_on_id"
  add_index "fact_names", ["name"], :name => "index_fact_names_on_name"

  create_table "fact_values", :force => true do |t|
    t.text     "value",        :null => false
    t.integer  "fact_name_id", :null => false
    t.integer  "host_id",      :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "fact_values", ["fact_name_id"], :name => "index_fact_values_on_fact_name_id"
  add_index "fact_values", ["host_id"], :name => "index_fact_values_on_host_id"
  add_index "fact_values", ["id"], :name => "index_fact_values_on_id"

  create_table "hostgroups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hostgroups_puppetclasses", :id => false, :force => true do |t|
    t.integer "hostgroup_id",   :null => false
    t.integer "puppetclass_id", :null => false
  end

  create_table "hosts", :force => true do |t|
    t.string   "name",                                                :null => false
    t.string   "ip"
    t.datetime "last_compile"
    t.datetime "last_freshcheck"
    t.datetime "last_report"
    t.datetime "updated_at"
    t.integer  "source_file_id"
    t.datetime "created_at"
    t.string   "mac",             :limit => 17, :default => ""
    t.string   "sp_mac",          :limit => 17, :default => ""
    t.string   "sp_ip",           :limit => 15, :default => ""
    t.string   "sp_name",                       :default => ""
    t.string   "root_pass",       :limit => 64
    t.string   "serial",          :limit => 12
    t.string   "puppetmaster"
    t.integer  "puppet_status",                 :default => 0,    :null => false
    t.integer  "domain_id"
    t.integer  "environment_id"
    t.integer  "subnet_id"
    t.integer  "sp_subnet_id"
    t.integer  "ptable_id"
    t.integer  "media_id"
    t.boolean  "build",                         :default => true
    t.text     "comment"
    t.text     "disk"
    t.datetime "installed_at"
    t.integer  "model_id"
    t.integer  "mux_id"
  end

  add_index "hosts", ["id"], :name => "index_hosts_on_id"
  add_index "hosts", ["name"], :name => "index_hosts_on_name"
  add_index "hosts", ["operatingsystem_id"], :name => "host_os_id_ix"
  add_index "hosts", ["puppet_status"], :name => "index_hosts_on_puppet_status"
  add_index "hosts", ["source_file_id"], :name => "index_hosts_on_source_file_id"

  create_table "medias", :force => true do |t|
    t.string   "name",               :limit => 50,  :default => "", :null => false
    t.string   "path",               :limit => 100, :default => "", :null => false
    t.integer  "operatingsystem_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "models", :force => true do |t|
    t.string   "name",       :limit => 64, :null => false
    t.text     "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "muxes", :force => true do |t|
    t.integer  "operatingsystem_id", :null => false
    t.integer  "architecture_id",    :null => false
    t.integer  "puppetclass_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "netdbs", :force => true do |t|
    t.string   "name",          :limit => 32, :null => false
    t.string   "address",       :limit => 32, :null => false
    t.integer  "servertype_id",               :null => false
    t.integer  "vendor_id",                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operatingsystems", :force => true do |t|
    t.string   "major",         :limit => 5,  :default => "", :null => false
    t.string   "name",          :limit => 64
    t.string   "minor",         :limit => 16
    t.string   "nameindicator", :limit => 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operatingsystems_ptables", :id => false, :force => true do |t|
    t.integer "ptable_id",          :null => false
    t.integer "operatingsystem_id", :null => false
  end

  create_table "param_names", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "param_names", ["id"], :name => "index_param_names_on_id"
  add_index "param_names", ["name"], :name => "index_param_names_on_name"

  create_table "param_values", :force => true do |t|
    t.text     "value",         :null => false
    t.integer  "param_name_id", :null => false
    t.integer  "line"
    t.integer  "resource_id"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "param_values", ["id"], :name => "index_param_values_on_id"
  add_index "param_values", ["param_name_id"], :name => "index_param_values_on_param_name_id"
  add_index "param_values", ["resource_id"], :name => "index_param_values_on_resource_id"

  create_table "parameters", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.integer  "host_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hostgroup_id"
    t.string   "type"
    t.integer  "domain_id"
  end

  add_index "parameters", ["domain_id", "type"], :name => "index_parameters_on_domain_id_and_type"
  add_index "parameters", ["host_id", "type"], :name => "index_parameters_on_host_id_and_type"
  add_index "parameters", ["hostgroup_id", "type"], :name => "index_parameters_on_hostgroup_id_and_type"
  add_index "parameters", ["type"], :name => "index_parameters_on_type"

  create_table "ptables", :force => true do |t|
    t.string   "name",               :limit => 64,   :null => false
    t.string   "layout",             :limit => 4096, :null => false
    t.integer  "operatingsystem_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "puppet_tags", :force => true do |t|
    t.string   "name"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "puppet_tags", ["id"], :name => "index_puppet_tags_on_id"

  create_table "puppetclasses", :force => true do |t|
    t.string   "name"
    t.string   "nameindicator"
    t.integer  "operatingsystem_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", :force => true do |t|
    t.integer  "host_id",     :null => false
    t.text     "log"
    t.datetime "reported_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reports", ["reported_at", "host_id"], :name => "index_reports_on_reported_at_and_host_id"

  create_table "resource_tags", :force => true do |t|
    t.integer  "resource_id"
    t.integer  "puppet_tag_id"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "resource_tags", ["id"], :name => "index_resource_tags_on_id"
  add_index "resource_tags", ["puppet_tag_id"], :name => "index_resource_tags_on_puppet_tag_id"
  add_index "resource_tags", ["resource_id"], :name => "index_resource_tags_on_resource_id"

  create_table "resources", :force => true do |t|
    t.text     "title",          :null => false
    t.string   "restype",        :null => false
    t.integer  "host_id"
    t.integer  "source_file_id"
    t.boolean  "exported"
    t.integer  "line"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "resources", ["host_id"], :name => "index_resources_on_host_id"
  add_index "resources", ["id"], :name => "index_resources_on_id"
  add_index "resources", ["source_file_id"], :name => "index_resources_on_source_file_id"
  add_index "resources", ["title", "restype"], :name => "index_resources_on_title_and_restype"

  create_table "source_files", :force => true do |t|
    t.string   "filename"
    t.string   "path"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "source_files", ["filename"], :name => "index_source_files_on_filename"
  add_index "source_files", ["id"], :name => "index_source_files_on_id"

  create_table "subnets", :force => true do |t|
    t.string   "number",     :limit => 15
    t.string   "mask",       :limit => 15
    t.integer  "domain_id"
    t.integer  "priority"
    t.string   "ranges",     :limit => 512
    t.text     "name"
    t.string   "vlanid",     :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
