-- Lua wrapper for lspoints' excuteCommand
local function create_execute(command, option)
  function()
    vim.call(
      "denops#request",
      "lspoints",
      "executeCommand",
      { command, "execute", option },
    )
  end
end

-- initialize lspoints when denops loads the plugin
vim.api.nvim_create_autocmd("User", {
  pattern = "DenopsPluginPost:lspoints",
  callback = function()
    vim.call(
      "lspoints#load_extensions",
      {
        "config",
        "format",
        "nvim_diagnostics",
        "hover",
        "rename",
      },
    )
  end,
})

-- a map of lsp servers to lspoints extensions
local servers = {
  typescript = "denols",
  lua = "luals",
  nix = "nil",
}

-- attach lsp servers
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(servers),
  group = vim.api.nvim_create_augroup("lspoints-attach", {}),
  callback = function(ev)
    vim.call("lspoints#attach", servers[ev.match])
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LspointsAttach:*",
  group = vim.api.nvim_create_augroup("lspoints-attach", {}),

  callback = function(ev)

    -- keymappings ------------------------------------------------
    
    local function map(mode, from, to)
      vim.keymap.set(mode, from, to, { buffer = ev.buf, noremap = true })
    end

    -- neovim built-in
    map('n', "<M-k>", vim.diagnostic.open_float)
    map('n', "<M-n>", vim.diagnostic.goto_next)
    map('n', "<M-p>", vim.diagnostic.goto_prev)

    -- lspoints
    map('n', 'K', create_execute("hover", { border = "none" }))
    map('n', "<M-r>", create_execute("rename"))
    
    -- autocmds ---------------------------------------------------
    
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = ev.buf,
      group = vim.api.nvim_create_augroup("lspoints-format", {}),
      callback = create_execute("format", ev.buf),
    })
  end,
})
