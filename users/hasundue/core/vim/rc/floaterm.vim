function! FloatermOpen(name, cmd)
  const dir = expand('%:p:h')
  const root = floaterm#path#get_root(dir)
  const bufname = a:name . ':///' . root
  const bufnr = floaterm#terminal#get_bufnr(bufname)
  if bufnr < 0
    execute 'FloatermNew --cwd=' . root . ' --name=' . bufname a:cmd
  else
    execute 'FloatermShow' bufname
  endif
endfunction

nnoremap <silent> <leader>g :call FloatermOpen('gitui', 'gitui')<CR>

for i in range(1..9)
  execute 'nnoremap <silent> <leader>' . i . ' :FloatermToggle term-' . i . '<CR>'
endfor

nnoremap <silent> <C-[> :FloatermHide<CR>
