local M = {}

---@param obj table
---@param attribute string atribute that you want to extract
---@param key string field name of the attribute used for key in response
---@param value? string field name of the attribute used for value in response
---@return string[]|string|nil
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
  if not value then
    ret = vim.tbl_keys(ret)
    if #ret == 1 then
      for _, r in pairs(ret) do
        ret = r
      end
    end
  end
  return ret
end

return M
