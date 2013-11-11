" GUARD:
if !exists('g:smalls_debug')
  let g:smalls_debug = 0
endif

if exists('g:loaded_smalls')
  " finish
endif
let g:loaded_smalls = 1
let s:old_cpo = &cpo
set cpo&vim
" }}}

" Main: 
"====== 

let s:color = {
      \ 'SmallsCandidate': [ ['NONE',      'NONE',    'cyan',   ], [ 'bold',           'NONE',    '#66D9EF']],
      \ 'SmallsJumpTarget':[ ['NONE',      'NONE',    'yellow', ], [ 'bold',           '#223322', 'yellow']],
      \ 'SmallsCurrent':   [ ['NONE',      'magenta', 'white',  ], [ 'NONE',           '#f92672', '#ffffff']],
      \ 'SmallsCursor':    [ ['underline', 'magenta', 'white',  ], [ 'bold,underline', '#f92672', '#ffffff']],
      \ 'SmallsShade':     [ ['NONE',      'NONE',    'grey',   ], [ 'NONE',           'NONE',    '#777777']],
      \ }

function! s:clear_hl() "{{{1
  for color in keys(s:color)
    exe 'highlight' color 'none'
  endfor
endfunction

function! s:setupcolor()
  let s = 'highlight! %s cterm=%s ctermbg=%s ctermfg=%s gui=%s guibg=%s guifg=%s'
  for [k, v] in items(s:color)
    let [c, g] = v
    let arg = [s] + [k] + c + g
    exe call(function('printf'), arg)
  endfor
endfunction

function! s:setup_hl() "{{{1
  call s:clear_hl()
  call s:setupcolor()
  highlight! SmallsCursorHide none
endfunction "}}}

call s:setup_hl()

augroup Smalls
  autocmd!
  autocmd ColorScheme * call s:setup_hl()
augroup END

nnoremap <silent> <Plug>(smalls-forward)  :<C-u>call smalls#start("forward")<CR>
nnoremap <silent> <Plug>(smalls-backward) :<C-u>call smalls#start("backward")<CR>
nnoremap <silent> <Plug>(smalls-all)      :<C-u>call smalls#start("all")<CR>
nnoremap <silent> <Plug>(smalls-debug)    :<C-u>call smalls#debug()<CR>

command! -nargs=1 -complete=customlist,s:dir Smalls call smalls#start(<q-args>)
function! s:dir(a,l,p)
  return ['forward', 'backward', 'all']
endfunction
" }}}
" FINISH: "{{{1
let &cpo = s:old_cpo
"}}}
" vim: foldmethod=marker
