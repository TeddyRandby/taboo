vim.api.nvim_create_user_command("TabooOpen", require("taboo").open, {})

vim.api.nvim_create_user_command("TabooClose", require("taboo").close, {})

vim.api.nvim_create_user_command("TabooFocus", require("taboo").focus, {})

local function table_from_flags(list)
  local result = {}
  for _, v in ipairs(list) do
    result[v] = true
  end

  return result
end

vim.api.nvim_create_user_command("TabooNext", function(args)
  local opts = table_from_flags(args.fargs)
  require("taboo").next(opts.skip, opts)
end, { nargs = '*' })

vim.api.nvim_create_user_command("TabooPrev", function(args)
  local opts = table_from_flags(args.fargs)
  require("taboo").prev(opts.skip, opts)
end, { nargs = '*' })

vim.api.nvim_create_user_command("TabooLaunch", function(args)
  require("taboo").launch(args.fargs[1])
end, { nargs = '?' })

vim.api.nvim_create_user_command("TabooRemove", function(args)
  require("taboo").remove(args.fargs[1])
end, { nargs = '?' })
