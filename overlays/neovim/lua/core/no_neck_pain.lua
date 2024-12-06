vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  once = true,
  pattern = { "*" },
  callback = function()
    vim.cmd("NoNeckPain")
  end
})
