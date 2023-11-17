"
" hook_source {{{
"
call ddc#custom#patch_global(#{
  \   autoCompleteEvents: [
  \     'InsertEnter',
  \     'TextChangedI',
  \     'TextChangedP',
  \   ],
  \   backspaceCompletion: v:true,
  \   sources: [
  \     'nvim-lsp',
  \   ],
  \   ui: 'pum',
  \ })

call ddc#custom#patch_global('keywordPattern', '(\k*)|(:\w*)')

call ddc#custom#patch_global('sourceOptions', #{
  \   _: #{
  \     maxItems: 10,
  \     minAutoCompleteLength: 1,
  \     matchers: ['matcher_fuzzy'],
  \     sorters: ['sorter_fuzzy'],
  \     converters: ['converter_fuzzy'],
  \   },
  \   nvim-lsp: #{
  \     mark: 'L',
  \     forceCompletionPattern: '\S[\.\[\(\{]\S*'
  \   },
  \ })

call ddc#custom#patch_global('sourceParams', #{
  \   nvim-lsp: #{
  \     lspEngine: 'lspoints',
  \   },
  \ })

call ddc#custom#patch_global('filterParams', {
  \   'matcher_fuzzy': {
  \     'splitMode': 'word'
  \   }
  \ })

call ddc#enable()

" }}}

"
" hook_add {{{
"
inoremap <expr> <C-n> pum#visible()
  \ ? pum#map#insert_relative(+1)
  \ : ddc#map#manual_complete()

inoremap <expr> <C-p> pum#map#insert_relative(-1)

inoremap <expr> <TAB> pum#visible()
  \ ? '<C-n>'
  \ : getline('.')[0:col('.')] =~# '[\s\\]*' 
  \   ? '<TAB>' 
  \   : ddc#map#manual_complete()

inoremap <expr> <S-Tab> pum#visible()
  \ ? pum#map#insert_relative(-1)
  \ : '<C-h>'

inoremap <expr> <C-y> pum#map#confirm()
inoremap <expr> <C-e> pum#map#cancel()

" }}}
