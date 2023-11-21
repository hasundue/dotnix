-- initialize lspoints
vim.call(
  "lspoints#load_extensions",
  {
    "config",
    "format",
    "nvim_diagnostics",
    "hover",
    -- "rename",
  }
)

---@param command string
---@param options (string | table)?
---@return function
local function callback_execute(command, options)
  return function()
    vim.call(
      "denops#request",
      "lspoints",
      "executeCommand",
      { command, "execute", options }
    )
  end
end

-- a map of lsp servers to lspoints extensions
local servers = {
  typescript = "denols",
  lua = "luals",
  nix = "nil",
}

-- attach lsp servers
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(servers),
  group = vim.api.nvim_create_augroup("lspoints_filetype", {}),
  callback = function(args)
    if (not vim.startswith(args.file, "ddu-")) then
      vim.call("lspoints#attach", servers[args.match])
    end
  end,
})

-- configure lspoints for an attached buffer
vim.api.nvim_create_autocmd("User", {
  pattern = "LspointsAttach:*",
  group = vim.api.nvim_create_augroup("lspoints_attach", {}),

  callback = function(args)
    --
    -- keymappings ------------------------------------------------
    --
    local function map(mode, from, to)
      vim.keymap.set(mode, from, to, { buffer = args.buf, noremap = true })
    end

    -- neovim built-in
    map('n', "<M-k>", vim.diagnostic.open_float)
    map('n', "<M-n>", vim.diagnostic.goto_next)
    map('n', "<M-p>", vim.diagnostic.goto_prev)

    -- lspoints
    map('n', 'K', callback_execute("hover", { border = "none" }))
    map('n', "<M-r>", callback_execute("rename"))

    --
    -- autocmds ---------------------------------------------------
    --
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = args.buf,
      group = vim.api.nvim_create_augroup("lspoints_write", {}),
      callback = callback_execute("format", args.buf),
    })
  end,
})
