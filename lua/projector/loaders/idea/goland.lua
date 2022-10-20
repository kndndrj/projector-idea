local Task = require("projector.task")
local Loader = require("projector.contract.loader")
local utils = require("projector.utils")
local xml2lua = require("xml2lua")
local xml2lua_handler = require("xmlhandler.tree")
local common = require("projector.loaders.idea.common")

---@type Loader
local GoLandLoader = Loader:new()

---@return Task[]|nil
function GoLandLoader:load()
  ---@type { path: string }
  local opts = self.user_opts

  local path = opts.path or (vim.fn.getcwd() .. "/.idea/workspace.xml")
  if type(path) ~= "string" then
    utils.log("error", 'Got: "' .. type(path) .. '", want "string".', "Idea Loader")
    return
  end

  if not vim.loop.fs_stat(path) then
    return
  end

  local xml = xml2lua.loadFile(path)

  local parser = xml2lua.parser(xml2lua_handler)
  local ok = pcall(function()
    parser:parse(xml)
  end)
  if not ok then
    utils.log("error", 'Could not parse json file: "' .. path .. '".', "Builtin Loader")
    return
  end

  -- Funny xml parser behaviour
  local project = xml2lua_handler.root.project
  if vim.tbl_islist(project) then
    project = xml2lua_handler.root.project[1]
  end

  local idea_configs = {}
  for _, v in pairs(project.component) do
    if v.configuration then
      idea_configs = vim.tbl_extend("keep", idea_configs, v.configuration)
    end
  end

  local function convert_config(idea_config)
    -- working directory
    local cwd = common.get_attribute_pairs(idea_config, "working_directory", "value")

    -- environment
    local env = common.get_attribute_pairs(idea_config, "envs.env", "name", "value")

    -- arguments
    local arguments = common.get_attribute_pairs(idea_config, "parameters", "value")
    local args
    if arguments then
      args = {}
      arguments = arguments:gsub("'", "")
      arguments = arguments:gsub('"', "")
      for word in arguments:gmatch("%S+") do
        table.insert(args, word)
      end
    end

    -- file/package/directory/pattern to run
    local file = common.get_attribute_pairs(idea_config, "filePath", "value")
    local package = common.get_attribute_pairs(idea_config, "package", "value")
    local directory = common.get_attribute_pairs(idea_config, "directory", "value")
    local pattern = common.get_attribute_pairs(idea_config, "pattern", "value")

    -- kind of run option
    local kind = common.get_attribute_pairs(idea_config, "kind", "value")
    if not kind then
      return
    end

    -- command
    local param
    if kind == "FILE" then
      param = file
    elseif kind == "PACKAGE" then
      param = package
    elseif kind == "DIRECTORY" then
      param = directory
    end
    local command
    if idea_config._attr.type == "GoApplicationRunConfiguration" then
      command = "go run " .. param
    elseif idea_config._attr.type == "GoTestRunConfiguration" then
      command = "go test -v '" .. param .. "'"
      if pattern then
        command = command .. " -run '" .. pattern .. "'"
      end
    end

    -- translate field names
    local c = {
      name = idea_config._attr.name,
      env = env,
      cwd = cwd,
      args = args,
      command = command,
    }

    return Task:new(c, { scope = "project", group = "go" })
  end

  -- map with Task objects
  local tasks = {}

  if not vim.tbl_isempty(idea_configs) then
    for _, config in pairs(idea_configs) do
      local task = convert_config(config)
      table.insert(tasks, task)
    end
  end

  return tasks
end

-- We can use already configured variable expansion
---@param configuration Configuration
---@return Configuration
function GoLandLoader:expand_variables(configuration)
  local function expand_config_variables(option)
    if type(option) == "table" then
      return vim.tbl_map(expand_config_variables, option)
    end
    if type(option) ~= "string" then
      return option
    end
    local variables = {
      PROJECT_DIR = vim.fn.getcwd(),
    }
    local ret = option
    for key, val in pairs(variables) do
      ret = ret:gsub("%$" .. key .. "%$", val)
    end
    return ret
  end

  local cfg = vim.tbl_map(expand_config_variables, configuration)
  return cfg
end

return GoLandLoader
