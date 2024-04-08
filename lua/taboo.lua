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
    new     = "",
    shell   = "",
    dapui   = "",
    lazygit = "",
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

---Setup the plugin
---@param args TabooConfig?
function M.setup(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  for _, v in ipairs(M.config.components) do
    components.append(M, { name = v })
  end
end

---Open the taboo ui
function M.open()
  module.open(M)
end

---Close the taboo ui
function M.close()
  module.close(M)
end

---Select the next tab
---@param skip boolean?
function M.next(skip)
  module.next(M, skip)
end

---Select the previous tab
---@param skip boolean?
function M.prev(skip)
  module.prev(M, skip)
end

---Launch the component at target, or the selected one
---@param target string | integer | nil
function M.launch(target)
  module.launch(M, target)
end

---Remove the component at target, or the selected one
---@param target string | integer | nil
function M.remove(target)
  module.remove(M, target)
end

---Focus the taboo ui window
function M.focus()
  module.focus(M)
end

---Build a launcher for the given command
---@param cmd string
---@param opts TabooLauncherOptions?
---@return TabooLauncher
function M.launcher(cmd, opts)
  return module.launcher(cmd, opts)
end

return M
