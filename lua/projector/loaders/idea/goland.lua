local Task = require("projector.task")
local common = require("projector.loaders.idea.common")

local M = {}

function M.convert_config(idea_config)
  -- working directory
  local cwd = common.get_attribute(idea_config, "working_directory", "value")

  -- environment
  local env = common.get_attribute_pairs(idea_config, "envs.env", "name", "value")

  -- arguments
  local arguments = common.get_attribute(idea_config, "parameters", "value")
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
  local file = common.get_attribute(idea_config, "filePath", "value")
  local package = common.get_attribute(idea_config, "package", "value")
  local directory = common.get_attribute(idea_config, "directory", "value")
  local pattern = common.get_attribute(idea_config, "pattern", "value")

  -- kind of run option
  local kind = common.get_attribute(idea_config, "kind", "value")
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

return M
