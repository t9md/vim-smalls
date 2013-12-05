" GUARD:
if exists('g:loaded_smalls')
  " finish
endif
let g:loaded_smalls = 1
let s:old_cpo = &cpo
set cpo&vim

" Main:
let s:options = {
      \ 'g:smalls_shade' : 1,
      \ 'g:smalls_jump_keys': ';ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      \ 'g:smalls_highlight': {},
      \ 'g:smalls_jump_keys_auto_show': 0,
      \ 'g:smalls_jump_keys_auto_show_timeout': 0.5,
      \ 'g:smalls_jump_keys_auto_show_min_input_length': 3,
      \ 'g:smalls_operator_motion_inclusive': 0,
      \ 'g:smalls_blink_on_notfound': 1,
      \ 'g:smalls_current_mode': '',
      \ 'g:smalls_auto_excursion_min_input_length': 1,
      \ 'g:smalls_auto_set': 0,
      \ 'g:smalls_auto_set_min_input_lenght': 3,
      \ 'g:smalls_auto_set_blink': 1,
      \ }
      " \ 'g:smalls_auto_set_exceed_chars': 0,

      " Color format
      " { "Color1": [[cterm, ctermbg, cterfg],[gui, guibg, guifg], ... }
let s:color = {
      \ 'SmallsCandidate':  [['NONE',      'NONE',    'cyan',  ], [ 'bold',           '#403D3D', '#66D9EF']],
      \ 'SmallsCurrent':    [['NONE',      'magenta', 'white', ], [ 'NONE',           '#f92672', '#ffffff']],
      \ 'SmallsJumpTarget': [['NONE',      'NONE',    'red',   ], [ 'bold',           'NONE',    '#f92672']],
      \ 'SmallsPos':        [['underline', 'magenta', 'white', ], [ 'bold,underline', 'LawnGreen', 'Black']],
      \ 'SmallsShade':      [['NONE',      'NONE',    'grey',  ], [ 'NONE',           'NONE',    '#777777']],
      \ 'SmallsCli':        [['NONE',      'NONE',    'grey',  ], [ 'NONE',           'NONE',    '#a6e22e']],
      \ 'SmallsCliCursor':  [['NONE',      'NONE',    'grey',  ], [ 'underline',      'NONE',    '#a6e22e']],
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
  highlight link SmallsRegion Visual
endfunction "}}}

call s:set_options(s:options)
call extend(s:color, g:smalls_highlight)
call s:set_highlight()

" AutoCmd:
augroup Smalls
  autocmd!
  autocmd ColorScheme * call s:set_highlight()
augroup END

" KeyMap:
nnoremap <silent> <Plug>(smalls)           :<C-u>call smalls#start('n')<CR>
xnoremap <silent> <Plug>(smalls)           :<C-u>call smalls#start(visualmode())<CR>
onoremap <silent> <Plug>(smalls)           :<C-u>call smalls#start('o')<CR>

nnoremap <silent> <Plug>(smalls-excursion) :<C-u>call smalls#start('n', 1)<CR>
xnoremap <silent> <Plug>(smalls-excursion) :<C-u>call smalls#start(visualmode(), 1)<CR>
onoremap <silent> <Plug>(smalls-excursion) :<C-u>call smalls#start('o', 1)<CR>

" nnoremap <silent> <Plug>(smalls-debug)    :<C-u>call smalls#debug(1)<CR>

" Command:
command! Smalls call smalls#start('n')
command! SmallsWin call smalls#win_start('n')

" Finish:
let &cpo = s:old_cpo
" vim: foldmethod=marker
