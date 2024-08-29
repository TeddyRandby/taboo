-- main module file
local module = require("taboo.module")
local components = require("taboo.components")

---@class TabooState
---@field bufnr integer
---@field nsnr integer
---@field selected integer
---@field config TabooConfig
local M = {
  nsnr = -1,
  bufnr = -1,
  selected = 1,
}

---@class TabooComponentSettings
---@field insert boolean

---@class TabooConfig
---@field components string[]
---@field icons table<string,string>
---@field settings table<string, TabooComponentSettings>
---@field launchers table<string, TabooLauncher>
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
  settings = {
    shell = { insert = true },
    dapui = { insert = true },
    lazygit = { insert = true },
  },
  launchers = {
    new = function(taboo, tabnr)
      module.append(taboo, {
        name = tostring(tabnr),
        icon = tostring(tabnr),
        tabnr = tabnr,
      })

      components.detatch(taboo, "new")

      module.select(taboo, components.find_tab(taboo, tabnr))
    end,
    dapui = function() require("dapui").open() end,
    shell = module.launcher(M, vim.o.shell, { term = true }),
    lazygit = module.launcher(M, "lazygit", { term = true }),
  },
}

M.config = config


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
---@param opts TabooSelect?
function M.next(skip, opts)
  module.next(M, skip, opts)
end

---Select the previous tab
---@param skip boolean?
---@param opts TabooSelect?
function M.prev(skip, opts)
  module.prev(M, skip, opts)
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

---Toggle the taboo ui window
function M.toggle()
  module.toggle(M)
end

---Build a launcher for the given command
---@param cmd string
---@param opts TabooLauncherOptions?
---@return TabooLauncher
function M.launcher(cmd, opts)
  return module.launcher(M, cmd, opts)
end

return M
