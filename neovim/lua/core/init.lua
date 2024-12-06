-- enable experimental lua loader
vim.loader.enable()

for _, v in ipairs {
  "opt",
  "cmp",
  "floaterm",
  "incline",
  "kanagawa",
  "lsp",
  "lualine",
  "noice",
  "no_neck_pain",
  "oil",
  "telescope",
  "terminal",
  "treesitter",
} do
  require("core." .. v)
end

require("gitsigns").setup()
