require("core.lsp").setup("lua_ls", {
  settings = {
    Lua = {
      hint = {
        enable = false,
      },
      workspace = {
        checkThirdParty = false,
        library = vim.list_extend(vim.api.nvim_get_runtime_file("lua", true), {
          "${3rd}/luv/library",
          -- "${3rd}/busted/library",
          -- "${3rd}/luassert/library",
        }),
      },
    },
  },
})
