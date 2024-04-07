-- main module file
local module = require("taboo.module")
local components = require("taboo.components")

---@class TabooConfig
local config = {
  components = {
    "new",
    "lazygit",
    "shell",
    "dapui",
  },
  icons = {
    new     = "+",
    shell   = "$",
    dapui   = "",
    lazygit = "",
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
    dapui = function() require("dapui").open() end,
    shell = module.launcher(vim.o.shell, { insert = true, term = true }),
    lazygit = module.launcher("lazygit", { insert = true, term = true }),
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
function M.setup(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  for _, v in ipairs(M.config.components) do
    components.append(M, { name = v })
  end
end

function M.open()
  module.open(M)
end

function M.close()
  module.close(M)
end

function M.next()
  module.next(M)
end

function M.prev()
  module.prev(M)
end

function M.launch(target)
  module.launch(M, target)
end

function M.remove(target)
  module.remove(M, target)
end

function M.focus()
  module.focus(M)
end

return M
