" A function to add a plugin to runtimepath.
" Plugins are installed as nix flakes under the xdg data directory.
" (e.g. ~/.local/share/nvim/plugins)
function s:add(plugin_name)
  execute 'set runtimepath^=' .. stdpath('data') .. '/plugins/' .. a:plugin_name
endfunction

const s:dpp_base = '~/.cache/dpp'->expand()

" Add dpp and ext-lazy to runtimepath (required)
call s:add('dpp')
call s:add('dpp-ext-lazy')

if dpp#min#load_state(s:dpp_base)
  " Add denops and other dpp plugins to runtimepath (required)
  call s:add('denops')
  call s:add('dpp-ext-local')

  " Need to load denops manually
  runtime! plugin/denops

  autocmd User DenopsReady
    \ call dpp#make_state(s:dpp_base, '~/.config/nvim/rc/dpp.ts'->expand())
else
  autocmd BufWritePost */nvim/rc/*
    \ call dpp#check_files()
endif
