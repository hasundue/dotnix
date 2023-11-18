local cmd = vim.cmd
local g = vim.g
local keymap = vim.keymap
local opt = vim.opt
local wo = vim.wo

--
-- clipboard -------------------------------------
--
g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy,
    ['*'] = require('vim.ui.clipboard.osc52').copy,
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste,
    ['*'] = require('vim.ui.clipboard.osc52').paste,
  },
}
opt.clipboard = "unnamedplus"

--
-- UI -------------------------------------------
--
opt.number = true
opt.numberwidth = 2
wo.signcolumn = "yes"

opt.cursorline = true
opt.ruler = true

opt.wrap = false
opt.breakindent = true

opt.pumheight = 10

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
