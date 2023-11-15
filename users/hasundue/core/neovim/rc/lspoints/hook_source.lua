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
