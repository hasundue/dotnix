-- enable experimental lua loader
vim.loader.enable()

-- base configuration, independent of plugins (keymaps, etc)
require("base")

-- load plugins with dpp.vim
vim.cmd("source ~/.config/nvim/rc/dpp.vim")

-- configure colorscheme
require("colorscheme")
