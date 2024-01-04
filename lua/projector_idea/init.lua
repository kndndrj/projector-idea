local xml2lua = require("xml2lua")
local xml2lua_handler = require("xmlhandler.tree")
local common = require("projector_idea.common")
local goland = require("projector_idea.goland")

local M = {}

---@class IdeaLoader: Loader
---@field private get_path fun():string function that returns a path to launch.json file
M.Loader = {}

---@param opts? { path: string|fun():(string), }
---@return IdeaLoader
function M.Loader:new(opts)
  opts = opts or {}

  local path_getter
  if type(opts.path) == "string" then
    path_getter = function()
      return opts.path
    end
  elseif type(opts.path) == "function" then
    path_getter = function()
      return opts.path() or vim.fn.getcwd() .. "/.idea/workspace.xml"
    end
  end

  local o = {
    get_path = path_getter or function()
      return vim.fn.getcwd() .. "/.idea/workspace.xml"
    end,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

---@return string
function M.Loader:name()
  return ".idea"
end

---@return task_configuration[]?
function M.Loader:load()
  if not vim.loop.fs_stat(self.get_path()) then
    return
  end

  local xml = xml2lua.loadFile(self.get_path())

  local parser = xml2lua.parser(xml2lua_handler)
  local ok = pcall(function()
    parser:parse(xml)
  end)
  if not ok then
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

  if vim.tbl_isempty(idea_configs) then
    return
  end

  local configs = {}

  for _, config in pairs(idea_configs) do
    local idea_type = common.get_attribute(config, "", "type")
    local projector_config
    if idea_type == "GoApplicationRunConfiguration" or idea_type == "GoTestRunConfiguration" then
      projector_config = goland.convert_config(config)
    end
    if projector_config then
      table.insert(configs, projector_config)
    end
  end

  return configs
end

---@param configuration task_configuration
---@return task_configuration
function M.Loader:expand(configuration)
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

return M
