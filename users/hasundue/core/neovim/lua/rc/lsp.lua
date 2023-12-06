local lspconfig = require("lspconfig")

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local function map(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { noremap = true, buffer = ev.buf })
    end

    map('n', '<M-k>', function() vim.diagnostic.open_float { float = { header = false } } end)
    map('n', '<M-n>', function() vim.diagnostic.goto_next { float = { header = false } } end)
    map('n', '<M-p>', function() vim.diagnostic.goto_prev { float = { header = false } } end)

    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if client.supports_method("hover") then
      map('n', 'K', vim.lsp.buf.hover)
    end

    if client.supports_method("rename") then
      map('n', '<M-r>', vim.lsp.buf.rename)
    end

    if client.supports_method("inlay_hint") then
      vim.cmd('highlight link LspInlayHint Comment')
      vim.lsp.inlay_hint.enable(ev.buf)
    end

    if client.supports_method("format") then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = ev.buf,
        group = vim.api.nvim_create_augroup("LspFormat", {}),
        callback = function()
          vim.cmd('silent! lua vim.lsp.buf.format({ async = false })')
        end,
      })
    end

    require("lsp_signature").on_attach(
      {
        bind = true,
        doc_lines = 0,
        floating_window = true,
        floating_window_off_y = 0,
        handler_opts = {
          border = "none",
        },
        hint_enable = false,
        padding = ' ',
        transparency = 30,
      },
      ev.buf
    )
  end
})

local servers = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
  denols = {
    cmd = { "deno", "lsp", "--unstable" },
    single_file_support = true,
    root_dir = lspconfig.util.root_pattern(
      "denops",
      "deno.json",
      "deno.jsonc"
    ),
    settings = {
      deno = {
        enable = true,
        suggest = {
          completeFunctionCalls = true,
          names = true,
          paths = true,
          autoImports = true,
          imports = {
            autoDiscover = true,
            hosts = {
              ["https://deno.land"] = true,
            },
          },
        },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = true },
          enabled = "on",
        },
        unstable = true,
      },
    },
  },
}

for server, config in pairs(servers) do
  lspconfig[server].setup(config)
end
