-- main module file
local module = require("taboo.module")

---@class TabooConfig
local config = {
  components = {
    "new",
    "lazygit",
    "terminal",
  },
  icons = {
    new      = "+",
    lazygit  = "",
    terminal = "$",
  },
  expanders = {
    tabs = function()
    end,
  },
  launchers = {
    terminal = function()
      local jid = vim.fn.termopen("sh", {
        on_exit = function()
          vim.api.nvim_command [[ tabclose ]]
        end,
        on_stderr = function(_, data)
          vim.notify_once(data, vim.log.levels.ERROR)
        end,
      })
      assert(jid ~= 0, "Failed to open job")

      vim.cmd [[ startinsert ]]
    end,
    lazygit = function()
      local jid = vim.fn.termopen("lazygit", {
        on_exit = function()
          vim.api.nvim_command [[ tabclose ]]
        end,
        on_stderr = function(_, data)
          vim.notify_once(data, vim.log.levels.ERROR)
        end,
      })
      assert(jid ~= 0, "Failed to open job")

      vim.cmd [[ startinsert ]]
    end
  },
}

---@class TabooState
---@field tabs { winnr: integer, cmp: string }[]
---@field bufnr integer
---@field nsnr integer
---@field selected integer
---@field components table[string]
---@field icons table[string, string]
---@field config TabooConfig
local M = {
  tabs = {},
  nsnr = -1,
  bufnr = -1,
  selected = 1,
  config = config,
}

---@param args TabooConfig?
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

M.next = function()
  module.next(M)
end

M.prev = function()
  module.prev(M)
end

M.launch = function(target)
  module.launch(M, target)
end

return M
