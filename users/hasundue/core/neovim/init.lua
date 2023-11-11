local opt = vim.opt
local cmd = vim.cmd
local g = vim.g

opt.termguicolors = true

require('kanagawa').setup({
    compile = true,              -- enable compiling the colorscheme
    undercurl = true,            -- enable undercurls
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = true,          -- do not set background color
    dimInactive = true,          -- dim inactive window `:h hl-NormalNC`
    terminalColors = true,       -- define vim.g.terminal_color_{0,17}
})

cmd("colorscheme kanagawa")

g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.clipboard.osc52').copy,
    ['*'] = require('vim.clipboard.osc52').copy,
  },
  paste = {
    ['+'] = require('vim.clipboard.osc52').paste,
    ['*'] = require('vim.clipboard.osc52').paste,
  },
}

opt.clipboard = "unnamedplus"

opt.smartindent = true
