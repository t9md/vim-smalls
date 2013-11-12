" GUARD:
if exists('g:loaded_smalls')
  " finish
endif
let g:loaded_smalls = 1
let s:old_cpo = &cpo
set cpo&vim

" Main:
let options = {
      \ 'g:smalls_shade' : 1,
      \ 'g:smalls_jump_keys': ';ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      \ 'g:smalls_highlight': {},
      \ }

let s:color = {
      \ 'SmallsCandidate': [ ['NONE',      'NONE',    'cyan',   ], [ 'bold',           'NONE',    '#66D9EF']],
      \ 'SmallsJumpTarget':[ ['NONE',      'NONE',    'yellow', ], [ 'bold',           '#223322', 'yellow']],
      \ 'SmallsCurrent':   [ ['NONE',      'magenta', 'white',  ], [ 'NONE',           '#f92672', '#ffffff']],
      \ 'SmallsCursor':    [ ['underline', 'magenta', 'white',  ], [ 'bold,underline', '#f92672', '#ffffff']],
      \ 'SmallsShade':     [ ['NONE',      'NONE',    'grey',   ], [ 'NONE',           'NONE',    '#777777']],
      \ }

function! s:set_options(options) "{{{
  for [varname, value] in items(a:options)
    if !exists(varname)
      let {varname} = value
    endif
    unlet value
  endfor
endfunction "}}}
function! s:clear_highlight(color) "{{{1
  for color in keys(a:color)
    exe 'highlight' color 'none'
  endfor
endfunction

function! s:set_color(colors) "{{{1
  let s = 'highlight! %s cterm=%s ctermbg=%s ctermfg=%s gui=%s guibg=%s guifg=%s'
  for [k, v] in items(a:colors)
    let [c, g] = v
    let arg = [s] + [k] + c + g
    exe call(function('printf'), arg)
  endfor
endfunction

function! s:set_highlight() "{{{1
  call s:clear_highlight(s:color)
  call s:set_color(s:color)
  highlight! SmallsCursorHide none
endfunction "}}}

call s:set_options(options)
call extend(s:color, g:smalls_highlight)
call s:set_highlight()

" AutoCmd:
augroup Smalls
  autocmd!
  autocmd ColorScheme * call s:set_highlight()
augroup END

" KeyMap:
nnoremap <silent> <Plug>(smalls-forward)  :<C-u>call smalls#start("forward")<CR>
nnoremap <silent> <Plug>(smalls-backward) :<C-u>call smalls#start("backward")<CR>
nnoremap <silent> <Plug>(smalls-all)      :<C-u>call smalls#start("all")<CR>
nnoremap <silent> <Plug>(smalls)          :<C-u>call smalls#start("all")<CR>
nnoremap <silent> <Plug>(smalls-debug)    :<C-u>call smalls#debug()<CR>

" Command:
command! -nargs=1 -complete=customlist,s:dir Smalls call smalls#start(<q-args>)
function! s:dir(a,l,p)
  return ['forward', 'backward', 'all']
endfunction

" Finish:
let &cpo = s:old_cpo
" vim: foldmethod=marker
