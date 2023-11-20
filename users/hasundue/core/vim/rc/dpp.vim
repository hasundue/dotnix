const s:dpp_base = expand('~/.cache') .. '/dpp'
const s:plugin_base = expand('~/.local/share/vim/plugins')

function s:add(plugin_name)
  execute 'set runtimepath^=' .. s:plugin_base .. '/' .. a:plugin_name
endfunction

call s:add('dpp.vim')
call s:add('dpp-ext-lazy')

const s:dpp_state = s:dpp_base .. '/vim/state.vim'

if dpp#min#load_state(s:dpp_base)
  call s:add('denops.vim')
  runtime! plugin/denops.vim " need this when `--noplugin`

  autocmd User DenopsReady
    \ call dpp#make_state(s:dpp_base, '~/.vim/rc/dpp/config.ts')

  autocmd User Dpp:makeStatePost
    \ echomsg '[dpp] Created ' .. s:dpp_state
else
  autocmd User Dpp:makeStatePost
    \ echomsg '[dpp] Updated ' .. s:dpp_state
endif

