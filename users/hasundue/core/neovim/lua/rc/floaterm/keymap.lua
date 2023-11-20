---@param mode string
---@param keys string
---@param func function
local function map(mode, keys, func)
  vim.keymap.set(mode, keys, func, { noremap = true, silent = true })
end

---@param name string
---@param cmd string
local function callback_open(name, cmd)
  return function()
    local dir = vim.fn.expand('%:p:h')
    local root = vim.call('floaterm#path#get_root', dir)
    local bufname = name .. ':///' .. root
    local bufnr = vim.call('floaterm#terminal#get_bufnr', bufname)
    if (bufnr < 0) then
      vim.cmd('FloatermNew --cwd=' .. root .. ' --name=' .. bufname .. ' ' .. cmd)
    else
      vim.cmd('FloatermShow ' .. bufname)
    end
  end
end

-- gitui
map('n', '<leader>g', callback_open('gitui', 'gitui'))

---@param cmd string
local function callback_cmd(cmd)
  return function()
    vim.cmd(cmd)
  end
end

-- map `<leader>{n}` for n = 1..9 to open a corresponding terminal
for i = 1, 9 do
  map('n', '<leader>' .. i, callback_cmd('FloatermToggle term-' .. i))
end

-- hide the terminal
map('n', '<C-[>', callback_cmd('FloatermHide'))
