local common = require("projector.loaders.idea.common")

local M = {}

function M.convert_config(config)
  -- working directory
  local cwd = common.get_attribute(config, "working_directory", "value")

  -- environment
  local env = common.get_attribute_pairs(config, "envs.env", "name", "value")

  -- arguments
  local arguments = common.get_attribute(config, "parameters", "value")
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
  local file = common.get_attribute(config, "filePath", "value")
  local package = common.get_attribute(config, "package", "value")
  local directory = common.get_attribute(config, "directory", "value")
  local pattern = common.get_attribute(config, "pattern", "value")

  -- kind of run option
  local kind = common.get_attribute(config, "kind", "value")
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
  if config._attr.type == "GoApplicationRunConfiguration" then
    command = "go run " .. param
  elseif config._attr.type == "GoTestRunConfiguration" then
    command = "go test -v '" .. param .. "'"
    if pattern then
      command = command .. " -run '" .. pattern .. "'"
    end
  end

  -- translate field names
  return {
    name = config._attr.name,
    env = env,
    cwd = cwd,
    args = args,
    command = command,
    scope = "project",
    group = "go",
  }
end

return M
