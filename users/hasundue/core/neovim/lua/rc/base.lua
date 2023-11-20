local g = vim.g
local opt = vim.opt

--
-- clipboard -------------------------------------
--
local osc52 = require('vim.ui.clipboard.osc52')

g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = osc52.copy('+'),
    ['*'] = osc52.copy('*'),
  },
  paste = {
    ['+'] = osc52.paste('+'),
    ['*'] = osc52.paste('*'),
  },
}
opt.clipboard = "unnamedplus"

--
-- UI -------------------------------------------
--
opt.number = true

opt.cursorline = true
opt.ruler = true

opt.wrap = false
opt.breakindent = true

opt.pumheight = 10

opt.pumblend = 15
opt.winblend = 15

--
-- commands -------------------------------------
--
g.mapleader = " "
opt.splitright = true
opt.updatetime = 100

--
-- editing --------------------------------------
--
opt.expandtab = true
opt.smarttab = true

opt.shiftwidth = 2
opt.tabstop = 2

opt.autoindent = true
opt.smartindent = true
