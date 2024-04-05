-- main module file
local module = require("taboo.module")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class TabooState
---@field buffer integer | nil
---@field window integer | nil
local M = {
  buffer = nil,
  window = nil,
}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.open = function()
  module.open(M)
end

M.close = function()
  module.close(M)
end

return M
