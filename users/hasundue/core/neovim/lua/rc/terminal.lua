vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })

local function config_term()
  vim.opt_local.termguicolors = true
  vim.opt_local.number = false
  vim.opt_local.signcolumn = 'no'
  vim.opt_local.relativenumber = false
end

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  pattern = { "*" },
  callback = config_term,
})
