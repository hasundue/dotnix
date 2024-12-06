vim.opt.termguicolors = true

require('kanagawa').setup({
  colors = {
    -- Remove gutter background
    theme = { all = { ui = { bg_gutter = 'none' } } },
  },
  compile = false,     -- enable compiling the colorscheme
  dimInactive = false, -- dim inactive window `:h hl-NormalNC`
  overrides = function(colors)
    local ui = colors.theme.ui
    return {
      -- floating windows
      NormalFloat = { bg = "none" },
      FloatBorder = { bg = "none" },
      FloatTitle = { bg = "none" },

      -- noice.nvim
      NoiceMini = { fg = ui.fg_dim, bg = "none" },
      NoiceLspProgressTitle = { fg = ui.fg_dim },

      -- telescope.nvim
      TelescopeBorder = { bg = "none" },

      -- make floaterm consistent with telescope
      Floaterm = { link = "TelescopeResultsNormal" },
      FloatermBorder = { link = "TelescopeBorder" },

      -- completion menu
      Pmenu = { fg = ui.shade0, bg = ui.bg_p1 },
      PmenuSel = { fg = "none", bg = ui.bg_p2 },
      PmenuSbar = { bg = ui.bg_m1 },
      PmenuThumb = { bg = ui.bg_p2 },
    }
  end,
  terminalColors = true, -- define vim.g.terminal_color_{0,17}
  transparent = true,    -- do not set background color
  undercurl = true,      -- enable undercurls
})

vim.cmd('colorscheme kanagawa')
