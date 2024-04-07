local ui = require("taboo.ui")

---@class TabooComponents
---@field tabpages integer[]
---@field components string[]
local M = {
  tabpages = {},
  components = {},
}

--- Render an icon with a rounded border
---@param taboo TabooState
---@param cmpnr number
function M.render(taboo, cmpnr)
  local line = cmpnr - 1

  local start = (line * 3) + 1
  local finish = (start) + 3

  local selected = taboo.selected == cmpnr

  local spacer = selected and " " or " "
  local group = selected and "TabooActive" or "TabooInactive"

  local icon = taboo.config.icons[M.components[cmpnr]]

  local lines = {
    "╭───╮",
    "│" .. spacer .. icon .. spacer .. "│",
    "╰───╯",
  }

  vim.api.nvim_buf_set_lines(ui.bufnr(taboo), start, finish, false, lines)

  for i = 0, 2 do
    vim.api.nvim_buf_add_highlight(ui.bufnr(taboo), taboo.nsnr, group, start + i, 0, -1)
  end

  vim.api.nvim_buf_add_highlight(ui.bufnr(taboo), taboo.nsnr, "TabooIcon", start + 1, 4, 5)
end

---Find the cmpnr of the given component
---@param taboo TabooState
---@param target string
---@return integer
function M.find(taboo, target)
  for i, k in pairs(M.components) do
    if k == target then
      return i
    end
  end

  return -1
end

---Get the tabpage corresponding to the component cmpnr
---@param taboo TabooState
---@param cmpnr string | integer
---@param tabnr? integer
---@return integer
function M.tabnr(taboo, cmpnr, tabnr)
  if type(cmpnr) == "string" then
    cmpnr = M.find(taboo, cmpnr)
  end

  if cmpnr == 0 then
    cmpnr = taboo.selected
  end

  assert(cmpnr > 0 and cmpnr <= #M.components, "No component found")

  if not tabnr then
    local tid = M.tabpages[cmpnr]

    return tid or -1
  end

  M.tabpages[cmpnr] = tabnr

  return tabnr
end

---Return true if the given component has an associated active tab
---@param taboo TabooState
---@param cmpnr string | integer
---@return boolean
function M.hastabnr(taboo, cmpnr)
  return vim.api.nvim_tabpage_is_valid(M.tabnr(taboo, cmpnr))
end

---Detatch a component from its tab, but leave the tab open
---@param taboo TabooState
---@param cmpnr string | integer
function M.detatch(taboo, cmpnr)
  if type(cmpnr) == "string" then
    cmpnr = M.find(taboo, cmpnr)
  end

  M.tabpages[cmpnr] = nil
end

---Launch the component at the given cmpnr
---@param taboo TabooState
---@param cmpnr integer
function M.launch(taboo, cmpnr)
  if cmpnr == 0 then
    cmpnr = taboo.selected
  end

  assert(cmpnr >= 0 and cmpnr <= #M.components, "Invalid target: Out of bounds. " .. vim.inspect(cmpnr))

  local cmp = M.components[cmpnr]

  local tid = M.tabnr(taboo, cmp)

  if not M.hastabnr(taboo, cmp) then
    local launcher = taboo.config.launchers[cmp]
    assert(launcher, "No launcher found for " .. cmp)

    vim.api.nvim_command [[ tabnew ]]

    tid = vim.api.nvim_get_current_tabpage()

    local tab = ui.tab(taboo, tid) or {}
    tab.cmp = cmp
    ui.tab(taboo, tid, tab)

    M.tabpages[cmpnr] = tid

    launcher(taboo, tid)
  end

  vim.api.nvim_set_current_tabpage(tid)
end

---Remove a component. This closes the associated tab, if it exists.
---@param taboo TabooState
---@param cmpnr string | number | nil
---@return integer | false
function M.remove(taboo, cmpnr)
  if type(cmpnr) == "string" then
    cmpnr = M.find(taboo, cmpnr)

    if cmpnr == -1 then
      return false
    end
  end

  if not cmpnr or cmpnr == 0 then
    cmpnr = taboo.selected
  end

  assert(type(cmpnr) == "number", "Invalid target: Expected number, not " .. vim.inspect(cmpnr))
  assert(cmpnr > 0 and cmpnr <= #M.components, "Invalid target: Out of bounds. " .. vim.inspect(cmpnr))

  if M.hastabnr(taboo, cmpnr) then
    local tid = M.tabnr(taboo, cmpnr)
    ui.tab(taboo, tid, {})

    vim.api.nvim_command("tabclose " .. vim.api.nvim_tabpage_get_number(tid))
    M.tabnr(taboo, cmpnr, -1)
  end

  table.remove(M.tabpages, cmpnr)
  table.remove(M.components, cmpnr)

  return cmpnr
end

---@class TabooAppend
---@field name string
---@field launcher? function
---@field tabnr? number
---@field icon? string

---Append a new component
---@param taboo TabooState
---@param cmp TabooAppend
---@return boolean
function M.append(taboo, cmp)
  local cmpnr = M.find(taboo, cmp.name)

  if cmpnr > 0 then
    return false
  end

  if cmp.icon and not taboo.config.icons[cmp.name] then
    taboo.config.icons[cmp.name] = cmp.icon
  end

  if cmp.launcher and not taboo.config.launchers[cmp.name] then
    taboo.config.launchers[cmp.name] = cmp.launcher
  end

  table.insert(M.components, cmp.name)
  cmpnr = #M.components

  if cmp.tabnr then
    M.tabnr(taboo, cmpnr, cmp.tabnr)
  end

  return true
end

return M
