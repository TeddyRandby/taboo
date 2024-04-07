local components = require("taboo.components")
local ui = require("taboo.ui")

---@class TabooStateInternal
---@field width integer
local M = {
  width = 6,
}

---Render the taboo ui into its' buffer
---@param taboo TabooState
function M.render(taboo)
  if not ui.haswinnr(taboo) or not ui.hasbufnr(taboo) then
    return
  end

  vim.api.nvim_win_set_width(ui.winnr(taboo, 0), M.width)

  vim.api.nvim_buf_clear_namespace(ui.bufnr(taboo), taboo.nsnr, 0, -1)

  vim.api.nvim_buf_set_lines(ui.bufnr(taboo), 0, -1, false, {})

  for i, _ in ipairs(components.components) do
    components.render(taboo, i)
  end
end

---Open the taboo ui window
---@param taboo TabooState
function M.open(taboo)
  if not ui.hasnsnr(taboo) then
    local nsid = vim.api.nvim_create_namespace("taboo")
    assert(nsid ~= 0, "Failed to create namespace")
    taboo.nsnr = nsid

    ui.nssetup(taboo, taboo.nsnr)
  end

  if not ui.hasbufnr(taboo) then
    local bid = vim.api.nvim_create_buf(false, true)
    assert(bid ~= 0, "Failed to create buffer")

    ui.bufnr(taboo, bid)
    ui.bufsetup(taboo, ui.bufnr(taboo))
  end

  if not ui.haswinnr(taboo) then
    vim.api.nvim_command [[vsp]]
    vim.api.nvim_command [[wincmd H]]
    local wid = vim.api.nvim_get_current_win()
    assert(wid ~= 0, "Failed to create window")

    ui.winnr(taboo, 0, wid)
    ui.winsetup(taboo, ui.winnr(taboo, 0), ui.bufnr(taboo))
  end

  vim.api.nvim_command [[stopinsert]]
  M.select(taboo, taboo.selected)
end

---Close the taboo ui window
---@param taboo TabooState
function M.close(taboo)
  if ui.haswinnr(taboo) then
    vim.api.nvim_win_close(ui.winnr(taboo, 0), true)
    ui.winnr(taboo, 0, -1)
  end
end

---Launch the target component
---@param taboo TabooState
---@param target number | string | nil
function M.launch(taboo, target)
  local cmpnr = target or taboo.selected

  if type(target) == "string" then
    cmpnr = components.find(taboo, target)

    if cmpnr == -1 then
      vim.notify_once("Component not found: " .. target, vim.log.levels.ERROR)
      return
    end
  end

  assert(type(cmpnr) == "number", "Invalid target: Expected number, not " .. vim.inspect(cmpnr))

  components.launch(taboo, cmpnr)

  M.open(taboo)

  vim.api.nvim_command [[ wincmd l ]]
end

---Select the component at index 'i'
---This is 1-based, and will clamp to within the bounds of the component table.
---@param taboo TabooState
---@param cmpnr integer
---@param preview boolean?
function M.select(taboo, cmpnr, preview)
  taboo.selected = cmpnr

  if taboo.selected > #components.components then
    taboo.selected = 1
  end

  if taboo.selected < 1 then
    taboo.selected = #components.components
  end

  if ui.haswinnr(taboo) then
    local row = taboo.selected * 3 - 1
    local col = 4
    vim.api.nvim_win_set_cursor(ui.winnr(taboo, 0), { row, col })
  end

  M.render(taboo)

  if preview and components.hastabnr(taboo, 0) then
    components.launch(taboo, 0)
  end
end

---Select the next component
---@param taboo TabooState
function M.next(taboo)
  M.select(taboo, taboo.selected + 1, true)
end

---Select the previous component
---@param taboo TabooState
function M.prev(taboo)
  M.select(taboo, taboo.selected - 1, true)
end

---Append a component to the list.
---If successful, re-render the ui.
---@param cmp TabooAppend
function M.append(taboo, cmp)
  if components.append(taboo, cmp) then
    M.render(taboo)
  end
end

---Remove a component from the list.
---If successful, select the previous component.
---@param cmp string | number | nil
function M.remove(taboo, cmp)
  local result = components.remove(taboo, cmp)
  if result then
    if #taboo.config.components == 0 then
      M.close(taboo)
    end

    if result == taboo.selected then
      M.prev(taboo)
    end
  end
end

return M
