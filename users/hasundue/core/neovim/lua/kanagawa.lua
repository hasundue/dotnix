vim.opt.termguicolors = true

require('kanagawa').setup({
    colors = {
      theme = { all = { ui = { bg_gutter = 'none' } } },
    },
    compile = true,              -- enable compiling the colorscheme
    undercurl = true,            -- enable undercurls
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = true,          -- do not set background color
    dimInactive = true,          -- dim inactive window `:h hl-NormalNC`
    terminalColors = true,       -- define vim.g.terminal_color_{0,17}
})

vim.cmd("colorscheme kanagawa")
