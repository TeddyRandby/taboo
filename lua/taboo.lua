-- main module file
local module = require("taboo.module")
local components = require("taboo.components")

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
  launchers = {
    new = function(taboo, tid)
      module.append(taboo, {
        name = tostring(tid),
        icon = tid,
        tabnr = tid,
      })
      components.detatch(taboo, "new")
    end,
    terminal = function()
      vim.fn.termopen(vim.o.shell, {
        on_exit = function()
          vim.api.nvim_command [[ tabclose ]]
        end,
        on_stderr = function(_, data)
          vim.notify_once(data, vim.log.levels.ERROR)
        end,
      })

      vim.cmd [[ startinsert ]]
    end,
    lazygit = function()
      vim.fn.termopen("lazygit", {
        on_exit = function()
          vim.api.nvim_command [[ tabclose ]]
        end,
        on_stderr = function(_, data)
          vim.notify_once(data, vim.log.levels.ERROR)
        end,
      })

      vim.cmd [[ startinsert ]]
    end
  },
}

---@class TabooState
---@field bufnr integer
---@field nsnr integer
---@field selected integer
---@field config TabooConfig
local M = {
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

  for _, v in ipairs(M.config.components) do
    components.append(M, { name = v })
  end
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

M.remove = function(target)
  module.remove(M, target)
end

return M
