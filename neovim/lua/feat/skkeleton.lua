vim.api.nvim_create_autocmd("User", {
  pattern = "skkeleton-initialize-pre",
  group = vim.api.nvim_create_augroup("skkeleton-initialize-pre", { clear = true }),
  callback = function()
    vim.call("skkeleton#config", {
      eggLikeNewline = true,
      -- FIXME: Replace with a Nix store path
      globalDictionaries = { "~/.cache/skkeleton/SKK-JISYO.L" },
    })
  end,
})

vim.keymap.set({ 'i', 'c', 't' }, '<C-j>', "<Plug>(skkeleton-toggle)")
