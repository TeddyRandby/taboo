# T A B O O

Taboo is a neovim plugin for managing tabs. It is *very* experimental.
The interface consists of a left-aligned column of icons, which is navigable like a buffer. It also allows
for custom components, which can do fancy things like:
- Launch `lazygit`
- Provide a terminal
- Launch a debugger interface with `nvim-dap-ui`

## Bugs
There are some glaring bugs preventing this plugin from being completely usable.
- Windows spawned with the 'new' component have the same win-opts as the 
