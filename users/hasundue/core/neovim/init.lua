-- enable experimental lua loader
vim.loader.enable()

-- disable default plugins
require("rc.builtin")

-- base configuration, independent of plugins (keymaps, etc)
require("base")

-- load plugins with dpp.vim
vim.cmd("source " .. vim.fn.stdpath("config") .. "/rc/dpp/init.vim")
