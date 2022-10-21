local Loader = require("projector.contract.loader")
local utils = require("projector.utils")
local xml2lua = require("xml2lua")
local xml2lua_handler = require("xmlhandler.tree")
local common = require("projector.loaders.idea.common")
local goland = require("projector.loaders.idea.goland")

---@type Loader
local IdeaLoader = Loader:new()

---@return Task[]|nil
function IdeaLoader:load()
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

  -- map with Task objects
  local tasks = {}

  if vim.tbl_isempty(idea_configs) then
    return
  end

  for _, config in pairs(idea_configs) do
    local idea_type = common.get_attribute(config, "", "type")
    local task
    if idea_type == "GoApplicationRunConfiguration" or idea_type == "GoTestRunConfiguration" then
      task = goland.convert_config(config)
    end
    if task then
      table.insert(tasks, task)
    end
  end

  return tasks
end

-- We can use already configured variable expansion
---@param configuration Configuration
---@return Configuration
function IdeaLoader:expand_variables(configuration)
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

  return vim.tbl_map(expand_config_variables, configuration)
end

return IdeaLoader
