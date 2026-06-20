local utils = {}

---comment
---@param name string
---@return string
function utils.greet(name)
  return "Hello, " .. name .. "!"
end

---comment
---@param a integer
---@param b integer
---@return integer
function utils.add(a, b)
  return a + b
end

return utils
