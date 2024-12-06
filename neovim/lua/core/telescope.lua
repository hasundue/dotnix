local builtin = require("telescope.builtin")

local function map(key, picker)
  vim.keymap.set("n", "<leader>" .. key, builtin[picker], {})
end

for picker, key in pairs {
  find_files = "a",
  buffers = "b",
  git_files = "f",
  help_tags = "h",
  live_grep = "l",
  resume = "r",
  grep_string = "s",
} do
  map(key, picker)
end

require("telescope").setup({
  pickers = {
    find_files = {
      find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--strip-cwd-prefix" }
    },
    git_files = {
      recurse_submodules = true,
    },
  }
})
