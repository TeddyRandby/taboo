---@class Taboo
local M = {}

local WIDTH = 9

local OPTIONS = { "first", "second", "third" }

local ICONS = {
  first = "1",
  second = "2",
  third = "3",
}

--- Render an icon with a rounded border
---@param icon string
---@return table[string]
local function renderIcon(icon)
  --- Return three lines of text for the icon and rounded border
  return {
    "╭───╮",
    "│ " .. icon .. " │",
    "╰───╯",
  }
end

local WINOPTS = {
  relativenumber = false,
  number = false,
  list = false,
  foldenable = false,
  winfixwidth = true,
  winfixheight = true,
  spell = false,
  signcolumn = "yes",
  foldmethod = "manual",
  foldcolumn = "0",
  cursorcolumn = false,
  cursorline = false,
  cursorlineopt = "both",
  colorcolumn = "0",
  wrap = false,
}

---@return string
M.my_first_function = function(greeting)
  return greeting
end

---@param taboo TabooState
M.render = function(taboo)
  if taboo.buffer == nil then
    return
  end

  for i = 0, 2 do
    local start = i * 3
    local finish = start + 2
    local icon = renderIcon(ICONS[OPTIONS[i + 1]])
    vim.api.nvim_buf_set_lines(taboo.buffer, start, finish, false, icon)
  end
end

---@param taboo TabooState
M.resize = function(taboo)
  if taboo.window == nil or taboo.window == nil then
    return
  end

  local lines = {}

  for _ = 0, vim.o.lines do
    table.insert(lines, "")
  end

  vim.api.nvim_buf_set_lines(taboo.buffer, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(taboo.buffer, 0, 0, false, lines)

  vim.api.nvim_win_set_width(taboo.window, WIDTH)

  for k, v in pairs(WINOPTS) do
    vim.api.nvim_win_set_option(taboo.window, k, v)
  end

  vim.api.nvim_win_set_buf(taboo.window, taboo.buffer)
end

---@param taboo TabooState
M.open = function(taboo)
  if taboo.buffer == nil then
    local bid = vim.api.nvim_create_buf(false, true)
    assert(bid ~= 0, "Failed to create buffer")
    vim.api.nvim_buf_set_name(bid, "taboo")

    taboo.buffer = bid
  end

  if taboo.window == nil then
    vim.api.nvim_command [[vsp]]
    vim.api.nvim_command [[wincmd H]]
    local wid = vim.api.nvim_get_current_win()
    assert(wid ~= 0, "Failed to create window")
    taboo.window = wid
  end

  M.resize(taboo)

  M.render(taboo)
end

---@param taboo TabooState
M.close = function(taboo)
  if taboo.window ~= nil then
    vim.api.nvim_win_close(taboo.window, true)
    taboo.window = nil
  end
end

return M
