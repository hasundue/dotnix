local M = {}

---Register callback function on LspAttach
---@param name string|nil If nil, global
---@param callback fun(client: vim.lsp.Client, bufnr: integer)
function M.on_attach(name, callback)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (name == nil or client.name == name) then
        callback(client, bufnr)
      end
    end,
  })
end

-- Default keybindings for all clients
M.on_attach(nil, function(client, bufnr)
  local function map(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, buffer = bufnr })
  end

  map('n', '<M-k>', vim.diagnostic.open_float)
  map('n', '<M-n>', vim.diagnostic.goto_next)
  map('n', '<M-p>', vim.diagnostic.goto_prev)

  if client.name == "copilot" then
    return
  end

  if client.supports_method("hover") then
    map('n', 'K', vim.lsp.buf.hover)
  end

  if client.supports_method("rename") then
    map('n', '<M-r>', vim.lsp.buf.rename)
  end

  if client.supports_method("inlay_hint") then
    map('n', "<M-i>", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
    end)
    vim.cmd('highlight link LspInlayHint NonText')
  end

  if client.supports_method("format") then
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      group = vim.api.nvim_create_augroup("LspFormat", { clear = true }),
      callback = function()
        vim.lsp.buf.format({ async = false, bufnr = bufnr })
      end,
    })
  end
end)

-- ref: https://github.com/oxalica/nil/blob/main/dev/nvim-lsp.nix
local capabilities = vim.tbl_deep_extend("force",
  vim.lsp.protocol.make_client_capabilities(),
  require("cmp_nvim_lsp").default_capabilities(),
  { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }
)

---Setup a language server
---@param server string
---@param config table
function M.setup(server, config)
  require("lspconfig")[server].setup(
    vim.tbl_deep_extend("keep", config, {
      autostart = true,
      capabilities = capabilities,
    })
  )
end

return M
