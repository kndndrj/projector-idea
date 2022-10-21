local M = {}

---@param obj table
---@param attribute string atribute that you want to extract
---@param key string field name of the attribute
---@return string[]|string|nil
function M.get_attribute(obj, attribute, key)
  -- get the nested field
  for s in attribute:gmatch("[^.]+") do
    obj = obj[s]
    if not obj then
      return
    end
  end
  return obj._attr[key]
end

function M.get_attribute_pairs(obj, attribute, key, value)
  -- get the nested field
  local attr = obj
  for s in attribute:gmatch("[^.]+") do
    attr = attr[s]
    if not attr then
      return
    end
  end

  if #attr < 1 then
    attr = { attr }
  end
  local ret = {}
  for _, a in pairs(attr) do
    if a._attr then
      ret[a._attr[key]] = a._attr[value] or {}
    end
  end
  return ret
end

return M
