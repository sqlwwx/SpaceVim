"=============================================================================
" javascript.vim --- SpaceVim lang#javascript layer
" Copyright (c) 2016-2022 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg@outlook.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

""
" @section lang#javascript, layers-lang-javascript
" @parentsection layers
" This layer is for JavaScript development, includes syntax lint, code
" completion etc. To enable this layer:
" >
"   [[layers]]
"     name = "lang#javascript"
" <
" The code linter is eslint, install eslint via:
" >
"   npm install -g eslint-cli
" <
" @subsection layer option
"
" 1. auto_fix: If this option is true, --fix will be added to neomake eslint
" maker.
" >
"   [[layers]]
"     name = "lang#javascript"
"     auto_fix = true
" <
" @subsection Key bindings
" >
"   Key             Function
"   -----------------------------
"   SPC l r         run current file
"   SPC b f         format current buffer
" <
"
" This layer also provides REPL support for javascript, the key bindings are:
" >
"   Key             Function
"   ---------------------------------------------
"   SPC l s i       Start a inferior REPL process
"   SPC l s b       send whole buffer
"   SPC l s l       send current line
"   SPC l s s       send selection text
" <
" If the lsp layer is enabled for javascript, the following key
" bindings can be used:
" >
"   key binding     Description
"   g D             jump to type definition
"   SPC l e         rename symbol
"   SPC l x         show references
"   SPC l h         show line diagnostics
"   SPC l d         show document
"   K               show document
"   SPC l w l       list workspace folder
"   SPC l w a       add workspace folder
"   SPC l w r       remove workspace folder
" <
"

let s:format_on_save = 0

function! SpaceVim#layers#lang#javascript#plugins() abort
  let plugins = [
        \ ['Galooshi/vim-import-js', {
          \ 'on_ft': 'javascript', 'build' : 'npm install -g import-js' }],
          \ ['heavenshell/vim-jsdoc', { 'on_cmd': 'JsDoc' }],
          \ ['maksimr/vim-jsbeautify', { 'on_ft': 'javascript' }],
          \ ['mmalecki/vim-node.js', { 'on_ft': 'javascript' }],
          \ ['moll/vim-node', { 'on_ft': 'javascript' }],
          \ ['neoclide/vim-jsx-improve', { 'on_ft': 'javascript' }],
          \ ['othree/es.next.syntax.vim', { 'on_ft': 'javascript' }],
          \ ['othree/javascript-libraries-syntax.vim', {
            \ 'on_ft': ['javascript', 'coffee', 'ls', 'typescript'] }],
            \ ]

  if s:enable_flow_syntax
    call add(plugins, ['flowtype/vim-flow', { 'on_ft': 'javascript' }])
    let g:flow#enable = 0
  else
    call add(plugins, ['othree/yajs.vim', { 'on_ft': 'javascript' }])
  endif

  if !SpaceVim#layers#lsp#check_filetype('javascript')
    call add(plugins, ['ternjs/tern_for_vim', {
          \ 'on_ft': 'javascript', 'build' : 'npm install' }])
    call add(plugins, ['carlitux/deoplete-ternjs', { 'on_ft': [
          \ 'javascript'], 'if': has('nvim') }])
  endif

  return plugins
endfunction

let s:auto_fix = 0
let s:enable_flow_syntax = 0

function! SpaceVim#layers#lang#javascript#set_variable(var) abort
  let s:auto_fix = get(a:var, 'auto_fix', 0)
  let s:enable_flow_syntax = get(a:var, 'enable_flow_syntax', 0)
  let s:format_on_save = get(a:var,
        \ 'format_on_save',
        \ s:format_on_save)
endfunction

function! SpaceVim#layers#lang#javascript#config() abort
  let g:javascript_plugin_jsdoc = 1
  let g:javascript_plugin_flow = 1

  call add(g:spacevim_project_rooter_patterns, 'package.json')

  call SpaceVim#plugins#runner#reg_runner('javascript', 'node %s')

  call SpaceVim#mapping#space#regesit_lang_mappings('javascript',
        \ function('s:language_mappings'))

  if SpaceVim#layers#lsp#check_filetype('javascript')
    call SpaceVim#mapping#gd#add('javascript',
          \ function('SpaceVim#lsp#go_to_def'))
  else
    call SpaceVim#mapping#gd#add('javascript', function('s:tern_go_to_def'))
  endif

  let g:neomake_javascript_enabled_makers = ['eslint']
  let g:neomake_javascript_eslint_maker =  {
        \ 'args': ['--format=compact'],
        \ 'errorformat': '%E%f: line %l\, col %c\, Error - %m,' .
        \   '%W%f: line %l\, col %c\, Warning - %m,%-G,%-G%*\d problems%#',
        \ 'cwd': '%:p:h',
        \ 'output_stream': 'stdout',
        \ }

  if s:auto_fix
    " Use the fix option of eslint
    let g:neomake_javascript_eslint_args = ['-f', 'compact', '--fix']
  endif
  " Only use eslint

  augroup SpaceVim_lang_javascript
    autocmd!
    autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
    autocmd FileType javascript set comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,://
    if s:auto_fix
      autocmd User NeomakeFinished call <SID>checktime_if_javascript()
      autocmd FocusGained * call <SID>checktime_if_javascript()
    endif
  augroup END
  " just add a note here, when using `node -`, the Buffered stdout will not
  " be flushed by sender.
  " Use node -i will show the output of repl command.
  call SpaceVim#plugins#repl#reg('javascript', ['node', '-i'])

  " Format on save
  if s:format_on_save
    call SpaceVim#layers#format#add_filetype({
          \ 'filetype' : 'javascript',
          \ 'enable' : 1,
          \ })
  endif
endfunction

function! s:language_mappings() abort
  nnoremap <silent><buffer> <F4> :ImportJSWord<CR>
  nnoremap <silent><buffer> <Leader>ji :ImportJSWord<CR>
  nnoremap <silent><buffer> <Leader>jf :ImportJSFix<CR>
  nnoremap <silent><buffer> <Leader>jg :ImportJSGoto<CR>

  inoremap <silent><buffer> <F4> <Esc>:ImportJSWord<CR>a
  inoremap <silent><buffer> <C-j>i <Esc>:ImportJSWord<CR>a
  inoremap <silent><buffer> <C-j>f <Esc>:ImportJSFix<CR>a
  inoremap <silent><buffer> <C-j>g <Esc>:ImportJSGoto<CR>a


  " Allow prompt for interactive input.
  let g:jsdoc_allow_input_prompt = 1

  " Prompt for a function description
  let g:jsdoc_input_description = 1

  " Set value to 1 to turn on detecting underscore starting functions as private convention
  let g:jsdoc_underscore_private = 1

  " Enable to use ECMAScript6's Shorthand function, Arrow function.
  let g:jsdoc_enable_es6 = 1


  if SpaceVim#layers#lsp#check_filetype('javascript')
        \ || SpaceVim#layers#lsp#check_server('tssserver')
    nnoremap <silent><buffer> K :call SpaceVim#lsp#show_doc()<CR>
    nnoremap <silent><buffer> gD :<C-u>call SpaceVim#lsp#go_to_typedef()<Cr>

    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'd'],
          \ 'call SpaceVim#lsp#show_doc()', 'show-document', 1)
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'x'],
          \ 'call SpaceVim#lsp#references()', 'show-references', 1)
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'e'],
          \ 'call SpaceVim#lsp#rename()', 'rename-symbol', 1)
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'h'],
          \ 'call SpaceVim#lsp#show_line_diagnostics()', 'show-line-diagnostics', 1)
    let g:_spacevim_mappings_space.l.w = {'name' : '+Workspace'}
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'w', 'l'],
          \ 'call SpaceVim#lsp#list_workspace_folder()', 'list-workspace-folder', 1)
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'w', 'a'],
          \ 'call SpaceVim#lsp#add_workspace_folder()', 'add-workspace-folder', 1)
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'w', 'r'],
          \ 'call SpaceVim#lsp#remove_workspace_folder()', 'remove-workspace-folder', 1)
  else
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'd'], 'TernDoc',
          \ 'show document', 1)
    call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'e'], 'TernRename',
          \ 'rename symbol', 1)
  endif

  let g:_spacevim_mappings_space.l.g = {'name' : '+Generate'}

  call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'g', 'd'], 'JsDoc',
        \ 'generate JSDoc', 1)

  call SpaceVim#mapping#space#langSPC('nnoremap', ['l', 'r'],
        \ 'call SpaceVim#plugins#runner#open()', 'execute current file', 1)

  let g:_spacevim_mappings_space.l.s = {'name' : '+Send'}
  call SpaceVim#mapping#space#langSPC('nmap', ['l','s', 'i'],
        \ 'call SpaceVim#plugins#repl#start("javascript")',
        \ 'start REPL process', 1)
  call SpaceVim#mapping#space#langSPC('nmap', ['l','s', 'l'],
        \ 'call SpaceVim#plugins#repl#send("line")',
        \ 'send line and keep code buffer focused', 1)
  call SpaceVim#mapping#space#langSPC('nmap', ['l','s', 'b'],
        \ 'call SpaceVim#plugins#repl#send("buffer")',
        \ 'send buffer and keep code buffer focused', 1)
  call SpaceVim#mapping#space#langSPC('nmap', ['l','s', 's'],
        \ 'call SpaceVim#plugins#repl#send("selection")',
        \ 'send selection and keep code buffer focused', 1)
endfunction

function! s:tern_go_to_def() abort
  if exists(':TernDef')
    TernDef
  endif
endfunction

function! s:checktime_if_javascript() abort
  if (&filetype =~# '^javascript')
    checktime
  endif
endfunction

" vi: et sw=2 cc=80


function! SpaceVim#layers#lang#javascript#health() abort
  call SpaceVim#layers#lang#javascript#plugins()
  call SpaceVim#layers#lang#javascript#config()
  return 1
endfunction
