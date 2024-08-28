-- main module file
local module = require("taboo.module")
local components = require("taboo.components")
local ui = require("taboo.ui")

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
---@field keep_on_close boolean

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
    new = { keep_on_close = true },
    shell = { keep_on_close = true, insert = true },
    dapui = { keep_on_close = true, insert = true },
    lazygit = { keep_on_close = true, insert = true },
  },
  launchers = {
    new = function(taboo, tid)
      module.append(taboo, {
        name = tostring(tid),
        icon = tostring(tid),
        tabnr = tid,
      })

      components.detatch(taboo, "new")
    end,
    dapui = function() require("dapui").open() end,
    shell = module.launcher(M, vim.o.shell, { term = true }),
    lazygit = module.launcher(M, "lazygit", { term = true }),
  },
}

M.config = config

local autocmds = {
  {
    "WinClosed",
    function()
      local numwins = #vim.api.nvim_tabpage_list_wins(0)
      local tabpage = vim.api.nvim_get_current_tabpage()
      if numwins == 2 and ui.haswinnr(M) and tabpage > 1 then
        vim.api.nvim_command [[ tabclose ]]
      end
    end,
  },
  {
    "TabClosed",
    function()
      local tabnr = tonumber(vim.fn.expand("<afile>"))
      local cmpnr = module.find_tab(M, tabnr)
      module.detatch(M, cmpnr)
      if not components.setting(M, "keep_on_close", cmpnr) then
        module.remove(M, cmpnr)
      end
    end,
  },
}


---Setup the plugin
---@param args TabooConfig?
function M.setup(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  for _, v in ipairs(M.config.components) do
    components.append(M, { name = v })
  end

  for _, v in ipairs(autocmds) do
    vim.api.nvim_create_autocmd(v[1], {
      callback = v[2],
    })
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
