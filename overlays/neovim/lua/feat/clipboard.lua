local osc52 = require('vim.ui.clipboard.osc52')

local function vim_paste()
  return vim.split(vim.fn.getreg('"'), '\n')
end

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = osc52.copy('+'),
    ['*'] = osc52.copy('*'),
  },
  paste = {
    ['+'] = vim_paste,
    ['*'] = vim_paste,
  },
}

vim.opt.clipboard = "unnamedplus"
