require("noice").setup({
  lsp = {
    -- override markdown rendering so that cmp and other plugins use Treesitter
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  routes = {
    {
      filter = {
        event = "msg_show",
        kind = {
          "search_count",
          "", -- including file editing messages
        },
      },
      opts = { skip = true },
    },
  },
  popupmenu = {
    backend = "cmp", -- use nvim-cmp for popupmenu
  },
  presets = {
    command_palette = true,       -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    lsp_doc_border = true,        -- add a border to hover docs and signature help
  },
  views = {
    mini = {
      win_options = {
        winblend = 0, -- no transparency
      },
    },
  }
})
