" A function to add a plugin to runtimepath.
" Plugins are installed as nix flakes under the xdg data directory.
" (e.g. ~/.local/share/nvim/plugins)
" If a directory with the same name exists in the home directory,
" it is added to runtimepath.
function s:add(plugin_name)
  let local = expand('~/' .. a:plugin_name)
  if local->isdirectory()
    execute 'set runtimepath^=' .. local
  else
    execute 'set runtimepath^=' .. stdpath('data') .. '/plugins/' .. a:plugin_name
  endif
endfunction

const s:dpp_base = '~/.cache/dpp'->expand()
const s:dpp_state = s:dpp_base .. '/nvim/state.vim'

" Add dpp and ext-lazy to runtimepath (required)
call s:add('dpp')
call s:add('dpp-ext-lazy')

" Define augroup for dpp
augroup dpprc
  autocmd!
augroup END

" Try loading the latest state
if dpp#min#load_state(s:dpp_base)
  " The state file doesn't exist. Create one from scratch.
  echo '[dpp] Creating ' .. s:dpp_state .. ' ...'

  " Add denops and to runtimepath (required)
  call s:add('denops')

  autocmd dpprc User DenopsReady
    \ call dpp#make_state(s:dpp_base, stdpath('config') .. '/rc/dpp/config.ts')

  autocmd dpprc User Dpp:makeStatePost
    \ echo '[dpp] Created ' .. s:dpp_state
else
  " Found an existing state. Check if it is up-to-date.
  call dpp#check_files()

  autocmd dpprc User Dpp:makeStatePost
    \ echo '[dpp] Updated ' .. s:dpp_state
endif
