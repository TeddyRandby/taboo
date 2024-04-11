local components = require("taboo.components")
local ui = require("taboo.ui")

---@class TabooStateInternal
---@field width integer
local M = {
  width = 5,
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
    vim.api.nvim_command(M.width .. "vsp")
    vim.api.nvim_command "wincmd H"

    local wid = vim.api.nvim_get_current_win()

    ui.winnr(taboo, 0, wid)
    ui.winsetup(taboo, wid, ui.bufnr(taboo))
  end

  vim.api.nvim_set_current_win(ui.winnr(taboo, 0))
  vim.api.nvim_command "stopinsert"
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
---@param target string | integer | nil
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

  components.launch(taboo, cmpnr, true)
end

---@class TabooSelect
---@field preview boolean?
---@field enter boolean?

---Select the component at index 'i'
---This is 1-based, and will clamp to within the bounds of the component table.
---@param taboo TabooState
---@param cmpnr integer
---@param opts TabooSelect?
function M.select(taboo, cmpnr, opts)
  opts = opts or {}

  taboo.selected = cmpnr

  if taboo.selected > #components.components then
    taboo.selected = 1
  end

  if taboo.selected < 1 then
    taboo.selected = #components.components
  end

  local tid = components.tabnr(taboo, 0)
  local wid = ui.winnr(taboo, tid)

  M.render(taboo)

  if ui.haswinnr(taboo, tid) then
    local row = taboo.selected * 3 - 1
    local col = 4
    vim.api.nvim_win_set_cursor(wid, { row, col })
  end

  local show = opts.enter or (opts.preview and ui.haswinnr(taboo, tid))

  if show and components.hastabnr(taboo, 0) then
    components.launch(taboo, 0, opts.enter)
    M.render(taboo)
  end
end

---Select the next component
---@param taboo TabooState
---@param skip boolean?
---@param opts TabooSelect?
function M.next(taboo, skip, opts)
  M.select(taboo, taboo.selected + 1, opts)

  if skip then
    local starting_point = taboo.selected

    while not components.hastabnr(taboo, 0) do
      M.select(taboo, taboo.selected + 1, opts)

      if taboo.selected == starting_point then
        break
      end
    end
  end
end

---Select the previous component
---@param taboo TabooState
---@param skip boolean?
---@param opts TabooSelect?
function M.prev(taboo, skip, opts)
  M.select(taboo, taboo.selected - 1, opts)

  if skip then
    local starting_point = taboo.selected

    while not components.hastabnr(taboo, 0) do
      M.select(taboo, taboo.selected - 1, opts)

      if taboo.selected == starting_point then
        break
      end
    end
  end
end

---Focus the taboo ui
---@param taboo TabooState
function M.focus(taboo)
  if ui.haswinnr(taboo, 0) then
    vim.api.nvim_set_current_win(ui.winnr(taboo, 0))
  end
end

---Append a component to the list.
---If successful, re-render the ui.
---@param cmp TabooAppend
function M.append(taboo, cmp)
  if components.append(taboo, cmp) then
    M.render(taboo)
  end
end

---Detatch a component from it's tab.
---@param cmp string | integer | nil
function M.detatch(taboo, cmp)
  components.detatch(taboo, cmp)
end

---Remove a component from the list.
---If successful, select the previous component.
---@param cmp string | integer | nil
function M.remove(taboo, cmp)
  local result = components.remove(taboo, cmp)
  if result then
    if #components.components == 0 then
      M.close(taboo)
    end

    if result == taboo.selected then
      M.prev(taboo, true, { enter = true })
    end
  end
end

---@class TabooLauncherOptions
---@field insert boolean?
---@field term boolean?

---@alias TabooLauncher function

---Create a launcher for the given command
---@param taboo TabooState
---@param cmd string | function
---@param opts TabooLauncherOptions?
---@return TabooLauncher
function M.launcher(taboo, cmd, opts)
  opts = opts or {}

  return function()
    if type(cmd) == "function" then
      cmd()
    end

    if type(cmd) == "string" then
      if opts.term then
        vim.api.nvim_command [[
          set signcolumn=no
          set number=no
        ]]

        vim.fn.termopen(cmd, {
          on_exit = function()
            components.detatch(taboo, 0)

            vim.api.nvim_command [[
              bdelete
              tabclose
            ]]
          end,
          on_stderr = function(_, data)
            vim.notify_once(data, vim.log.levels.ERROR)
          end,
        })
      end

      if not opts.term then
        vim.api.nvim_command(cmd)
      end
    end

    if opts.insert then
      vim.api.nvim_command [[ wincmd l]]
      vim.api.nvim_command [[ startinsert ]]
    end
  end
end

return M
