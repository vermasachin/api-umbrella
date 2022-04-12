local read_config = require "api-umbrella.cli.read_config"
local config = read_config({ write = true })

local setenv = require("posix.stdlib").setenv
setenv("API_UMBRELLA_RUNTIME_CONFIG", config["_api_umbrella_config_runtime_file"])

local etlua_render = require("etlua").render
local file = require "pl.file"
local path = require "pl.path"
local pg_utils = require "api-umbrella.utils.pg_utils"
local xpcall_error_handler = require "api-umbrella.utils.xpcall_error_handler"

return function()
  local database = pg_utils.db_config["database"]

  pg_utils.db_config["database"] = "postgres"
  pg_utils.db_config["user"] = os.getenv("DB_USERNAME")
  pg_utils.db_config["password"] = os.getenv("DB_PASSWORD")

  local result = pg_utils.query("SELECT 1 FROM pg_catalog.pg_database WHERE datname = :database", { database = database }, { verbose = true, fatal = true })
  if not result[1] then
    pg_utils.query("CREATE DATABASE :database", { database = pg_utils.identifier(database) }, { verbose = true, fatal = true })
  end

  pg_utils.db_config["database"] = database

  local setup_sql_path = path.join(os.getenv("API_UMBRELLA_SRC_ROOT"), "db/setup.sql.etlua")
  local setup_sql = file.read(setup_sql_path, true)
  local render_ok, render_err
  render_ok, setup_sql, render_err = xpcall(etlua_render, xpcall_error_handler, setup_sql, { config = config })
  if not render_ok or render_err then
    ngx.log(ngx.ERR, "template compile error in " .. path ..": " .. (render_err or setup_sql))
    os.exit(1)
  end
  pg_utils.query(setup_sql, nil, { verbose = true, fatal = true })

  local schema_sql_path = path.join(os.getenv("API_UMBRELLA_SRC_ROOT"), "db/schema.sql")
  local schema_sql = file.read(schema_sql_path, true)
  pg_utils.query(schema_sql, nil, { verbose = true, fatal = true })

  local grants_sql_path = path.join(os.getenv("API_UMBRELLA_SRC_ROOT"), "db/grants.sql")
  local grants_sql = file.read(grants_sql_path, true)
  pg_utils.query(grants_sql, nil, { verbose = true, fatal = true })
end