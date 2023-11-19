"
" hook_add {{{
"
let g:copilot_filetypes = #{
  \   ddu-ff-filter: v:false,
  \ }

let g:copilot_no_tab_map = v:true

imap <silent><script><expr> <CR> copilot#Accept("\<CR>")
imap <silent><script><expr> <C-f> copilot#Accept()

" }}}
