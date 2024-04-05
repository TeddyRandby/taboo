vim.api.nvim_create_user_command("TabooOpen", require("taboo").open, {})
vim.api.nvim_create_user_command("TabooClose", require("taboo").close, {})
