local cmp = require("cmp")

-- True if we are in the beginning of the line, ignoring whitespaces and tabs.
---@return boolean
local function has_text_before()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

---@return boolean
local function copilot_visible()
  local status, copilot = pcall(require, "copilot.suggestion")
  if status then
    return copilot.is_visible()
  else
    return false
  end
end

local sources = cmp.config.sources({
  { name = "nvim_lsp" },
  { name = "snippy" },
}, {
  { name = "buffer" },
}, {
  { name = "emoji" },
})

cmp.setup({
  mapping = {
    ['<CR>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if copilot_visible() then
          require("copilot.suggestion").dismiss()
        end
        cmp.confirm({ select = true })
      else
        fallback()
      end
    end),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if copilot_visible() then
        require("copilot.suggestion").accept()
      elseif cmp.visible() then
        cmp.select_next_item()
      elseif has_text_before() then
        cmp.complete()
      else
        fallback()
      end
    end),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
  },
  snippet = {
    expand = function(args)
      require("snippy").expand_snippet(args.body)
    end
  },
  sources = sources,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "skkeleton-enable-post",
  group = vim.api.nvim_create_augroup("skkeleton-enable-post", { clear = true }),
  callback = function()
    cmp.setup.buffer({
      sources = cmp.config.sources({ { name = "skkeleton" } }),
    })
  end
})

vim.api.nvim_create_autocmd("User", {
  pattern = "skkeleton-disable-post",
  group = vim.api.nvim_create_augroup("skkeleton-disable-post", { clear = true }),
  callback = function()
    cmp.setup.buffer({ sources = sources })
  end
})

cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" }
  }, {
    { name = "cmdline" }
  })
})
