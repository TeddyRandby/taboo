---@class TabooTab
---@field cmp string?
---@field winnr integer?

---@class TabooUI
---@field tabs TabooTab[]
---@field bufremaps table[string, string]
---@field bufopts table[string, string]
---@field winopts table[string, string]
local M = {
  tabs = {},
  bufremaps = {
    q = "<cmd>TabooClose<CR>",
    j = "<CMD>TabooNext<CR>",
    k = "<CMD>TabooPrev<CR>",
    h = "",
    l = "",
    x = "<CMD>TabooRemove<CR>",
    ["<CR>"] = "<CMD>TabooLaunch<CR>",
  },
  bufopts = {
    buflisted = false,
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
}

---@param taboo TabooState
---@param bufnr integer?
---@return integer
function M.bufnr(taboo, bufnr)
  if not bufnr then
    return taboo.bufnr
  end

  taboo.bufnr = bufnr

  return bufnr
end

---Get the tab at the tabnr
---@param taboo TabooState
---@param tabnr integer
---@param tab TabooTab?
---@return TabooTab
---@diagnostic disable-next-line: unused-local
function M.tab(taboo, tabnr, tab)
  if not tab then
    return M.tabs[tabnr] or {}
  end

  M.tabs[tabnr] = tab

  return tab
end

---@param taboo TabooState
---@param tabnr integer
---@param winnr integer?
---@return integer
function M.winnr(taboo, tabnr, winnr)
  if tabnr == 0 then
    tabnr = vim.api.nvim_get_current_tabpage()
  end

  if not winnr then
    local tab = M.tab(taboo, tabnr)

    if not tab then
      return -1
    end

    return tab.winnr
  end

  local tid = vim.api.nvim_get_current_tabpage()

  local tab = M.tab(taboo, tid)
  tab.winnr = winnr
  M.tab(taboo, tid, tab)

  return winnr
end

--- Return true if Taboo has a valid buffer
---@param taboo TabooState
---@return boolean
function M.hasbufnr(taboo)
  return vim.api.nvim_buf_is_valid(taboo.bufnr)
end

---Return true if Taboo has a valid window for the current tab
---@param taboo TabooState
---@param tabnr integer?
---@return boolean
function M.haswinnr(taboo, tabnr)
  tabnr = tabnr or 0

  if tabnr == 0 then
    tabnr = vim.api.nvim_get_current_tabpage()
  end

  if not M.hastabnr(taboo, tabnr) then
    return false
  end

  local tab = M.tab(taboo, tabnr)

  if not tab.winnr then
    return false
  end

  return vim.api.nvim_win_is_valid(tab.winnr)
end

---Return true if Taboo has a valid namespace
---@param taboo TabooState
---@return boolean
function M.hasnsnr(taboo)
  return taboo.nsnr ~= -1
end

---Check if we have a tab for the given tabnr
---@param taboo TabooState
---@param tabnr integer?
---@return boolean
function M.hastabnr(taboo, tabnr)
  tabnr = tabnr or 0

  if tabnr == 0 then
    tabnr = vim.api.nvim_get_current_tabpage()
  end

  if not vim.api.nvim_tabpage_is_valid(tabnr) then
    return false
  end

  local tab = M.tab(taboo, tabnr)

  return not not tab
end

-- What is the best way to do these highlights?

---Setup the hl namespace at nsnr
---@param taboo TabooState
---@param nsnr number
---@diagnostic disable-next-line: unused-local
function M.nssetup(taboo, nsnr)
  vim.api.nvim_set_hl(nsnr, 'TabooIcon', {})
  vim.api.nvim_set_hl(nsnr, 'TabooActive', { link = "Float" })
  vim.api.nvim_set_hl(nsnr, 'TabooInactive', { link = "Comment" })
end

---Setup the window at 'winnr' as a Taboo window
---@param taboo TabooState
---@param bufnr number
---@param winnr number
function M.winsetup(taboo, winnr, bufnr)
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
function M.togglecursor(target)
  local hl = vim.api.nvim_get_hl(0, { name = "Cursor" })
  local next_blend = target == 'on' and 0 or 100
  hl.blend = next_blend
  vim.api.nvim_set_hl(0, 'Cursor', hl)
end

---Setup the buffer at 'bufnr' as a Taboo buffer
---@param taboo TabooState
---@param bufnr number
---@diagnostic disable-next-line: unused-local
function M.bufsetup(taboo, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_set_name(bufnr, "taboo" .. tostring(bufnr))

  for k, v in pairs(M.bufopts) do
    vim.api.nvim_buf_set_option(bufnr, k, v)
  end

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

return M
