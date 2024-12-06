local g = vim.g
local opt = vim.opt

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
