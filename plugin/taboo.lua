vim.api.nvim_create_user_command("TabooOpen", require("taboo").open, {})

vim.api.nvim_create_user_command("TabooClose", require("taboo").close, {})

vim.api.nvim_create_user_command("TabooNext", require("taboo").next, {})

vim.api.nvim_create_user_command("TabooPrev", require("taboo").prev, {})

vim.api.nvim_create_user_command("TabooFocus", require("taboo").focus, {})

vim.api.nvim_create_user_command("TabooLaunch", function(args)
  require("taboo").launch(args.fargs[1])
end, { nargs = '?' })

vim.api.nvim_create_user_command("TabooRemove", function(args)
  require("taboo").remove(args.fargs[1])
end, { nargs = '?' })
