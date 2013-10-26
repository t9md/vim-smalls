" GUARD:
"============={{{
if !exists('g:smal_s_debug')
  let g:smal_s_debug = 0
endif

if exists('g:loaded_smal_s')
  " finish
endif
let g:loaded_smal_s = 1
let s:old_cpo = &cpo
set cpo&vim
" }}}

" Main: 
"====== {{{
" hi! SmallsCandidate gui=underline cterm=underline term=underline "{{{
" highlight! link SmallSCurrent VisualNOS

highlight  SmallsCandidate   none
highlight  SmallsCurrent     none
highlight  SmallsCursor      none
highlight  SmallsInput       none

" highlight! SmallsCandidate term=bold,underline cterm=bold,underline gui=bold,underline guibg=#
" highlight! SmallsCandidate ctermfg=7 ctermbg=5 gui=bold guifg=#ffffff guibg=#0070e0 

" highlight! SmallsCandidate term=reverse cterm=reverse gui=reverse
" highlight! SmallsCursor gui=bold guibg=#ffffff guifg=#f92672
" highlight! SmallsCursor gui=reverse "}}}

highlight! SmallsCandidate term=bold,underline cterm=bold,underline gui=bold,underline guibg=#403D3D
highlight! SmallsCurrent guifg=#ffffff guibg=#f92672
highlight! SmallsCursor gui=bold,underline guifg=#ffffff guibg=#f92672

" highlight! SmallsInput gui=reverse guifg=#a6e22e
highlight! SmallsInput guifg=#a6e22e
highlight! SmallsCursorHide none

" highlight! SmallsInput guifg=#a6e22e


" highlight! SmallsInput gui=bold,underline guifg=#ffffff guibg=#f92672

nnoremap <silent> <Plug>(smalls-forward)       :<C-u>call smalls#spot(0)<CR>
nnoremap <silent> <Plug>(smalls-backward)       :<C-u>call smalls#spot(1)<CR>
nnoremap <silent> <Plug>(smalls-debug) :<C-u>call smalls#debug()<CR>
" }}}
" FINISH:
"============={{{
let &cpo = s:old_cpo
"}}}
" vim: foldmethod=marker
