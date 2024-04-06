local M = {
 width = 6,
  bufremaps = {
    q = "<cmd>TabooClose<cr>",
    j = "<CMD>TabooNext<CR>",
    k = "<CMD>TabooPrev<CR>",
    h = "",
    l = "",
    ["<CR>"] = "<CMD>TabooLaunch<CR>",
  },
  winopts = {
    relativenumber = false,
    number = false,
    list = false,
    foldenable = false,
    winfixwidth = true,
    winfixheight = true,
    spell = false,
    signcolumn = "no",
    foldmethod = "manual",
    foldcolumn = "0",
    cursorcolumn = false,
    cursorline = false,
    cursorlineopt = "both",
    colorcolumn = "0",
    wrap = false,
  },
  tabpages = {}
}

--- Render an icon with a rounded border
---@param taboo TabooState
---@param cmpnr number
local function renderComponent(taboo, cmpnr)
  local line = cmpnr - 1

  local start = (line * 3) + 1
  local finish = (start) + 3

  local selected = taboo.selected == cmpnr

  local spacer = selected and " " or " "
  local group = selected and "TabooActive" or "TabooInactive"

  local icon = taboo.config.icons[taboo.config.components[cmpnr]]

  local lines = {
    "╭───╮",
    "│" .. spacer .. icon .. spacer .. "│",
    "╰───╯",
  }

  vim.api.nvim_buf_set_lines(M.bufnr(taboo), start, finish, false, lines)

  for i = 0, 2 do
    vim.api.nvim_buf_add_highlight(M.bufnr(taboo), taboo.nsnr, group, start + i, 0, -1)
  end

  vim.api.nvim_buf_add_highlight(M.bufnr(taboo), taboo.nsnr, "TabooIcon", start + 1, 4, 5)
end

---Get the tabpage corresponding to the component cmpnr
---@param taboo TabooState
---@param cmp string
---@return integer
---@diagnostic disable-next-line: unused-local
local function tabpageComponent(taboo, cmp)
  local tid = M.tabpages[cmp]
  return tid or -1
end

---Launch the component at the given cmpnr
---@param taboo TabooState
---@param cmp string
local function launchComponent(taboo, cmp)
  local tid = tabpageComponent(taboo, cmp)

  local launcher = taboo.config.launchers[cmp]

  assert(launcher, "No launcher found for " .. cmp)

  if not vim.api.nvim_tabpage_is_valid(tid) then
    vim.api.nvim_command [[ tabnew ]]
    local wid = vim.api.nvim_get_current_win()

    tid = vim.api.nvim_get_current_tabpage()
    assert(tid ~= 0, "Failed to create tabpage")

    local nrs = taboo.tabs[tid] or {}
    nrs.cmp = cmp
    taboo.tabs[tid] = nrs

    M.tabpages[cmp] = tid

    -- Open taboo in the new tabpage
    M.open(taboo)

    vim.api.nvim_set_current_win(wid)
    vim.api.nvim_win_set_cursor(0, { 1, 1 })

    launcher()
  end

  vim.api.nvim_set_current_tabpage(tid)
end

---@param taboo TabooState
---@param bufnr integer?
---@return integer
M.bufnr = function(taboo, bufnr)
  if not bufnr then
    return taboo.bufnr
  end

  taboo.bufnr = bufnr

  return bufnr
end

---@param taboo TabooState
---@param winnr integer?
---@return integer
M.winnr = function(taboo, winnr)
  if not winnr then
    local nrs = taboo.tabs[vim.api.nvim_get_current_tabpage()]
    if not nrs then
      return -1
    end

    return nrs.winnr
  end

  local tid = vim.api.nvim_get_current_tabpage()

  local nrs = taboo.tabs[tid] or {}
  nrs.winnr = winnr
  taboo.tabs[tid] = nrs

  return winnr
end

M.hasbufnr = function(taboo)
  return vim.api.nvim_buf_is_valid(taboo.bufnr)
end

M.haswinnr = function(taboo)
  if not M.hastab(taboo) then
    return false
  end

  local tid = vim.api.nvim_get_current_tabpage()

  local nrs = taboo.tabs[tid]

  if not nrs.winnr then
    return false
  end

  return vim.api.nvim_win_is_valid(nrs.winnr)
end

---Check if we have a tab for the given tabnr
---@param taboo TabooState
---@param tabnr integer?
---@return boolean
M.hastab = function(taboo, tabnr)
  tabnr = tabnr or vim.api.nvim_get_current_tabpage()

  if not vim.api.nvim_tabpage_is_valid(tabnr) then
    return false
  end

  local tab = taboo.tabs[tabnr]

  return not not tab
end

---@param taboo TabooState
M.render = function(taboo)
  if not M.haswinnr(taboo) or not M.hasbufnr(taboo) then
    return
  end

  vim.api.nvim_win_set_width(M.winnr(taboo), M.width)

  vim.api.nvim_buf_clear_namespace(M.bufnr(taboo), taboo.nsnr, 0, -1)

  for i, _ in pairs(taboo.config.components) do
    renderComponent(taboo, i)
  end

  local tabs = vim.api.nvim_list_tabpages()

  for i, tid in pairs(tabs) do
    renderComponent(taboo, i)
  end
end

---Setup the hl namespace at nsnr
---@param taboo TabooState
---@param nsnr number
---@diagnostic disable-next-line: unused-local
M.nssetup = function(taboo, nsnr)
  vim.api.nvim_set_hl(nsnr, 'TabooIcon', {})
  vim.api.nvim_set_hl(nsnr, 'TabooActive', { fg = "Orange" })
  vim.api.nvim_set_hl(nsnr, 'TabooInactive', { fg = "Cyan", blend = 50 })
end

---Setup the window at 'winnr' as a Taboo window
---@param taboo TabooState
---@param bufnr number
---@param winnr number
M.winsetup = function(taboo, winnr, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if not vim.api.nvim_win_is_valid(winnr) then
    return
  end

  for k, v in pairs(M.winopts) do
    vim.api.nvim_win_set_option(winnr, k, v)
  end

  vim.api.nvim_win_set_hl_ns(winnr, taboo.nsnr)
  vim.api.nvim_win_set_buf(winnr, bufnr)
end

---Toggle the cursor on and off. Requires "guicursor=a:Cursor/lCursor"
---@param target "on" | "off"
M.togglecursor = function(target)
  local hl = vim.api.nvim_get_hl(0, { name = "Cursor" })
  local next_blend = target == 'on' and 0 or 100
  hl.blend = next_blend
  vim.api.nvim_set_hl(0, 'Cursor', hl)
end

---Setup the buffer at 'bufnr' as a Taboo buffer
---@param taboo TabooState
---@param bufnr number
---@diagnostic disable-next-line: unused-local
M.bufsetup = function(taboo, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_set_name(bufnr, "taboo" .. tostring(bufnr))

  for k, v in pairs(M.bufremaps) do
    vim.api.nvim_buf_set_keymap(bufnr, "n", k, v, { noremap = true })
  end

  local lines = {}

  for _ = 1, vim.o.lines do
    table.insert(lines, "")
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    buffer = bufnr,
    callback = function()
      M.togglecursor("on")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    buffer = bufnr,
    callback = function()
      M.togglecursor("off")
    end,
  })
end

---@param taboo TabooState
M.open = function(taboo)
  if taboo.nsnr == -1 then
    local nsid = vim.api.nvim_create_namespace("taboo")
    assert(nsid ~= 0, "Failed to create namespace")
    taboo.nsnr = nsid

    M.nssetup(taboo, taboo.nsnr)
  end

  if not M.hasbufnr(taboo) then
    local bid = vim.api.nvim_create_buf(false, true)
    assert(bid ~= 0, "Failed to create buffer")

    M.bufnr(taboo, bid)
    M.bufsetup(taboo, M.bufnr(taboo))
  end

  if not M.haswinnr(taboo) then
    vim.api.nvim_command [[vsp]]
    vim.api.nvim_command [[wincmd H]]
    local wid = vim.api.nvim_get_current_win()
    assert(wid ~= 0, "Failed to create window")

    M.winnr(taboo, wid)
    M.winsetup(taboo, M.winnr(taboo), M.bufnr(taboo))
  end

  M.select(taboo, taboo.selected)
end

---@param taboo TabooState
M.close = function(taboo)
  if vim.api.nvim_win_is_valid(M.winnr(taboo)) then
    vim.api.nvim_win_close(M.winnr(taboo), true)
    M.winnr(taboo, -1)
  end
end

---Launch the target component
---@param taboo TabooState
---@param target number | string
M.launch = function(taboo, target)
  local cmpnr = target or taboo.selected

  if type(target) == "string" then
    for i, k in pairs(taboo.config.components) do
      if k == target then
        cmpnr = i
        break
      end
    end
  end

  assert(type(cmpnr) == "number", "Invalid target: Expected number, not " .. vim.inspect(cmpnr))
  assert(cmpnr > 0 and cmpnr <= #taboo.config.components, "Invalid target: Out of bounds. " .. vim.inspect(cmpnr))

  launchComponent(taboo, taboo.config.components[cmpnr])
end

---Select the component at index 'i'
---This is 1-based, and will clamp to within the bounds of the component table.
---@param taboo TabooState
M.select = function(taboo, i)
  taboo.selected = i

  if taboo.selected > #taboo.config.components then
    taboo.selected = 1
  end

  if taboo.selected < 1 then
    taboo.selected = #taboo.config.components
  end

  if M.haswinnr(taboo) then
    local row = taboo.selected * 3 - 1
    local col = 4
    vim.api.nvim_win_set_cursor(M.winnr(taboo), { row, col })
  end

  M.render(taboo)
end

---Select the next component
---@param taboo TabooState
M.next = function(taboo)
  M.select(taboo, taboo.selected + 1)
end

---Select the previous component
---@param taboo TabooState
M.prev = function(taboo)
  M.select(taboo, taboo.selected - 1)
end

return M
