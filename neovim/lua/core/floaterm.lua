-- set the floaterm window size
vim.g.floaterm_width = 0.8
vim.g.floaterm_height = 0.8

local function map(mode, lhs, rhs)
  vim.keymap.set(mode, lhs, rhs, { noremap = true })
end

local function maplocal(mode, lhs, rhs)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = true })
end

local function open(name, cmd)
  return function()
    local dir = vim.fn.expand("%:p:h")
    local root = vim.call("floaterm#path#get_root", dir)
    local bufname = name .. ":///" .. root
    local bufnr = vim.call("floaterm#terminal#get_bufnr", bufname)
    if (bufnr < 0) then
      vim.cmd("FloatermNew --cwd=" .. root .. " --name=" .. bufname .. " " .. cmd)
    else
      vim.cmd("FloatermShow " .. bufname)
    end
  end
end

local function exec(cmd)
  return function()
    vim.cmd(cmd)
  end
end

-- lazygit
map("n", "<leader>g", open("lazygit", "lazygit"))

-- map `<leader>{n}` for n = 1..9 to open a corresponding terminal
for i = 1, 9 do
  map("n", "<leader>" .. i, exec("FloatermToggle term-" .. i))
end

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  pattern = { "*" },
  callback = function()
    maplocal("t", "<Esc>", "<C-\\><C-n>")
    maplocal("n", "<C-[>", exec("FloatermHide"))
  end
})
