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

" let s:target_hl_defaults = {
      " \ 'gui'     : [guibg='NONE', guifg='#ff0000' , gui='bold'],
      " \ 'cterm256': ['NONE', '196'     , 'bold'],
      " \ 'cterm'   : ['NONE', 'red'     , 'bold'],
      " \ }

let s:shade_hl_defaults = {
      \ 'gui':      { 'guibg': 'NONE', 'guifg': '#777777', 'gui': 'NONE' },
      \ 'cterm256': { 'guibg': 'NONE', 'guifg': '242',     'gui': 'NONE' },
      \ 'cterm':    { 'guibg': 'NONE', 'guifg': 'grey',    'gui': 'NONE' },
      \ }

" printf('guibg=%s guifg=%s gui=%s', gui[0], gui[1], gui[2])
" printf('ctermbg=%s ctermfg=%s cterm=%s',    cterm[0], cterm[1],       cterm[2])
" printf('ctermbg=%s ctermfg=%s cterm=%s', cterm256[0], cterm256[1], cterm256[2])

" Main: 
"====== 
" hi! SmallsCandidate gui=underline cterm=underline term=underline "{{{
" highlight! link SmallSCurrent VisualNOS

function! s:clear_hl() "{{{1
  highlight SmallsShade     none
  highlight SmallsCandidate none
  highlight SmallsCurrent   none
  highlight SmallsCursor    none
  highlight SmallsInput     none
endfunction "}}}
" call s:clear_hl()

" highlight! SmallsCandidate term=bold,underline cterm=bold,underline gui=bold,underline guibg=#
" highlight! SmallsCandidate ctermfg=7 ctermbg=5 gui=bold guifg=#ffffff guibg=#0070e0 

" highlight! SmallsCandidate term=reverse cterm=reverse gui=reverse
" highlight! SmallsCursor gui=bold guibg=#ffffff guifg=#f92672
" {'fg': '#888888', 'guifg': '#888888', 'name': 'Comment'}
" highlight! SmallsCursor gui=reverse 

function! s:setup_hl()
  call s:clear_hl()
  " abcdefghijklmnopqrstuvwxyzA
" abcdefghijklmnopqrstuvwxyzA
" QuickhlManual0 xxx ctermfg=16 ctermbg=153 gui=bold guifg=#ffffff guibg=#0a7383
" QuickhlManual1 xxx ctermfg=7 ctermbg=1 gui=bold guifg=#ffffff guibg=#a07040
" QuickhlManual2 xxx ctermfg=7 ctermbg=2 gui=bold guifg=#ffffff guibg=#4070a0
" QuickhlManual3 xxx ctermfg=7 ctermbg=3 gui=bold guifg=#ffffff guibg=#40a070
" QuickhlManual4 xxx ctermfg=7 ctermbg=4 gui=bold guifg=#ffffff guibg=#70a040
" QuickhlManual5 xxx ctermfg=7 ctermbg=5 gui=bold guifg=#ffffff guibg=#0070e0
" QuickhlManual6 xxx ctermfg=7 ctermbg=6 gui=bold guifg=#ffffff guibg=#007020
" QuickhlManual7 xxx ctermfg=7 ctermbg=21 gui=bold guifg=#ffffff guibg=#d4a00d
" QuickhlManual8 xxx ctermfg=7 ctermbg=22 gui=bold guifg=#ffffff guibg=#06287e
" QuickhlManual9 xxx ctermfg=7 ctermbg=45 gui=bold guifg=#ffffff guibg=#5b3674
" QuickhlManual10 xxx ctermfg=7 ctermbg=16 gui=bold guifg=#ffffff guibg=#4c8f2f
" QuickhlManual11 xxx ctermfg=7 ctermbg=50 gui=bold guifg=#ffffff guibg=#1060a0
" QuickhlManual12 xxx ctermfg=7 ctermbg=56 gui=bold guifg=black guibg=#a0b0c0  
"
  " highlight! SmallsCandidate  guifg=NONE gui=bold,underline guibg=#403D3D
  " highlight! SmallsCandidate guibg=NONE  guibg=#403D3D  gui=NONE,bold,underline   
  " highlight! SmallsCandidate guibg=NONE  guifg=#ff0000 gui=bold
  highlight! SmallsCandidate  guibg=bg  guifg=#66D9EF gui=bold
  " highlight! SmallsJumpTarget guibg=#1060a0 guifg=#ffffff gui=bold
  highlight! SmallsJumpTarget guibg=#223322 guifg=yellow gui=bold
  " highlight! SmallsJumpTarget guibg=NONE guifg=red gui=bold
  " highlight! SmallsJumpTarget guibg=NONE guifg=green gui=bold,italic
  " highlight! SmallsJumpTarget guibg=NONE guifg=red gui=NONE
  " highlight! link SmallsJumpTarget  Statement
  " highlight! link SmallsJumpTarget  PreProc
  " {'fg': '#A6E22E', 'guifg': '#a6e22e', 'name': 'PreProc'}
  " {'fg': '#F92672', 'guifg': '#f92672', 'name': 'Statement'}
  " {'fg': '#E6DB74', 'guifg': '#e6db74', 'name': 'String'}
  " highlight! SmallsJumpTarget guibg=red guifg=#ffffff gui=bold
  " highlight! SmallsJumpTarget guibg=NONE guifg=#777777 gui=NONE
  highlight! SmallsCurrent   guifg=#ffffff       guibg=#f92672
  highlight! SmallsCursor    gui=bold,underline  guifg=#ffffff guibg=#f92672
  " highlight! SmallsCursor    gui=bold,underline  guifg=NONE guibg=NONE
  highlight! SmallsShade     guibg=NONE guifg=#777777 gui=NONE
  " highlight! SmallsInput gui=reverse guifg=#a6e22e
  highlight! SmallsInput guifg=#a6e22e
  highlight! SmallsCursorHide none
endfunction
" let g:EasyMotion_hl_group_target = 'EasyMotionTarget'
call s:setup_hl()

augroup Smalls
  autocmd!
  autocmd ColorScheme * call s:setup_hl()
augroup END


" highlight! SmallsInput gui=bold,underline guifg=#ffffff guibg=#f92672

nnoremap <silent> <Plug>(smalls-forward)  :<C-u>call smalls#start("forward")<CR>
nnoremap <silent> <Plug>(smalls-backward) :<C-u>call smalls#start("backward")<CR>
nnoremap <silent> <Plug>(smalls-right)    :<C-u>call smalls#start("right")<CR>
nnoremap <silent> <Plug>(smalls-left)     :<C-u>call smalls#start("left")<CR>
nnoremap <silent> <Plug>(smalls-debug)    :<C-u>call smalls#debug()<CR>
" }}}
" FINISH:
"============={{{
let &cpo = s:old_cpo
"}}}
" vim: foldmethod=marker
