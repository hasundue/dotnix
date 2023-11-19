"
" hook_add {{{
"
nnoremap <silent> <leader>f <Cmd>Ddu file_external
  \ -name=file -ui=ff -resume<CR>

nnoremap <silent> <leader>m <Cmd>Ddu mr
  \ -name=mr -ui=ff<CR>

nnoremap <silent> <leader>b <Cmd>Ddu buffer
  \ -name=buffer -ui=ff<CR>

nnoremap <silent> <leader>c <Cmd>Ddu file_external
  \ -name=rc -ui=ff -resume
  \ -source-option-file_external-path='`expand('~/neovim')`'<CR>

nnoremap <silent> <leader>r <Cmd>Ddu rg
  \ -name=grep -ui=ff -resume<CR>

nnoremap <silent> <leader>d <Cmd>Ddu help
  \ -name=help -ui=ff -resume<CR>

nnoremap <silent> <leader>i <Cmd>Ddu github_repo_issue
  \ -name=gh-issue -ui=ff -resume<CR>

nnoremap <silent> <leader>p <Cmd>Ddu github_repo_pull
  \ -name=gh-pr -ui=ff -resume<CR>

" }}}

"
" ddu-ff {{{
"
nnoremap <buffer><silent> <CR> 
  \ <Cmd>call ddu#ui#do_action('itemAction')<CR>

nnoremap <buffer><silent> i
  \ <Cmd>call ddu#ui#do_action('openFilterWindow')<CR>

" }}}

"
" ddu-ff-filter {{{
"
inoremap <buffer><silent> <CR>
  \ <Esc><Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>

nnoremap <buffer><silent> <CR>
  \ <Cmd>call ddu#ui#do_action('closeFilterWindow')<CR>

nnoremap <buffer><silent> <C-[>
  \ <Cmd>call ddu#ui#do_action('quit')<CR>

" }}}
