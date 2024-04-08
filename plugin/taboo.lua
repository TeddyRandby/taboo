vim.api.nvim_create_user_command("TabooOpen", require("taboo").open, {})

vim.api.nvim_create_user_command("TabooClose", require("taboo").close, {})

vim.api.nvim_create_user_command("TabooFocus", require("taboo").focus, {})

vim.api.nvim_create_user_command("TabooNext", function(args)
  require("taboo").next(args.fargs[1] == "skip")
end, { nargs = '?' })

vim.api.nvim_create_user_command("TabooPrev", function(args)
  require("taboo").prev(args.fargs[1] == "skip")
end, { nargs = '?' })

vim.api.nvim_create_user_command("TabooLaunch", function(args)
  require("taboo").launch(args.fargs[1])
end, { nargs = '?' })

vim.api.nvim_create_user_command("TabooRemove", function(args)
  require("taboo").remove(args.fargs[1])
end, { nargs = '?' })
