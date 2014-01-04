map <SID>xx <SID>xx
let s:sid = maparg("<SID>xx")
unmap <SID>xx
let s:sid = substitute(s:sid, 'xx', '', '')

function! s:msg(message) "{{{1
  echohl PreProc
  echon 'Smalls: '
  echohl None
  echon a:message
endfunction

function! s:error(expr, err) "{{{1
  if a:expr
    throw a:err
  endif
endfunction

function! s:ensure(expr, err) "{{{1
  if ! a:expr
    throw a:err
  endif
endfunction

function! s:prompt(msg) "{{{1
  echohl Question
  echo a:msg . ': '
  echohl None
endfunction

function! s:getchar() "{{{1
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfunction

" function! s:col_cmp(col1, col2) "{{{1
  " return a:col1 - a:col2
" endfunction

function! s:getchar_timeout(timeout) "{{{1
  let limit = a:timeout
  let start = reltime()
  while 1
    let elapsed = str2float(reltimestr(reltime(start)))
    if getchar(1)
      return s:getchar()
    endif
    if elapsed > limit
      throw 'KEYBOARD_TIMEOUT'
    endif
    sleep 10m
  endwhile
endfunction

function! s:pattern_for(word, wildchar) "{{{1
  let pat = '\V\c' . escape(a:word, '\') . '\v'
  let pat = substitute(pat, '\.', '\\v.\\V', 'g')
  if !empty(a:wildchar)
    let pat = substitute(pat, 
          \ escape(a:wildchar, '\') , '\\v.*\\V', 'g')
  endif
  return pat
endfunction

function! s:is_visual(mode) "{{{1
  return a:mode =~# s:vmode_pattern
endfunction
let s:vmode_pattern = "v\\|V\\|\<C-v>"
"}}}

" Special Keys
let s:fixed_special_key = [
      \ '<BS>',
      \ '<Tab>',
      \ '<S-Tab>',
      \ '<NL>',
      \ '<FF>',
      \ '<CR>',
      \ '<Return>',
      \ '<Enter>',
      \ '<Esc>',
      \ '<Space>',
      \ '<lt>',
      \ '<Bslash>',
      \ '<Bar>',
      \ '<Del>',
      \ '<CSI>',
      \ '<xCSI>',
      \ '<EOL>',
      \ '<Up>',
      \ '<Down>',
      \ '<Left>',
      \ '<Right>',
      \ '<S-Up>',
      \ '<S-Down>',
      \ '<S-Left>',
      \ '<S-Right>',
      \ '<C-Left>',
      \ '<C-Right>',
      \ '<Help>',
      \ '<Undo>',
      \ '<Insert>',
      \ '<Home>',
      \ '<End>',
      \ '<PageUp>',
      \ '<PageDown>',
      \ '<kHome>',
      \ '<kEnd>',
      \ '<kPageUp>',
      \ '<kPageDown>',
      \ '<kPlus>',
      \ '<kMinus>',
      \ '<kMultiply>',
      \ '<kDivide>',
      \ '<kEnter>',
      \ '<kPoint>',
      \ ]

function! s:function_key() "{{{1
  let R = []
  let R += map(range(1,12), "'<F' . v:val . '>'")    " <F1> - <F12>
  let R += map(range(1,12), "'<S-F' . v:val . '>'")  " <S-F1> - <S-F12>
  let R += map(range(0, 9), "'<k' . v:val . '>'")    " <k0> - <k9>
  return R
endfunction

function! s:combination_key() "{{{1
  let modifire_meta    = [ '<M-%s>', '<A-%s>', '<D-%s>' ]
  let modifire_control = [ '<C-%s>' ]
  let modifire_shift   = [ '<S-%s>' ]
  let R = []

  let chars = map(range(33, 126), 'nr2char(v:val)')

  let lower = filter(copy(chars), "v:val =~# '\\l'")
  let upper = filter(copy(chars), "v:val =~# '\\u'")
  let other = filter(copy(chars), "v:val =~# '\\A'")

  for char in chars
    let R += map(copy(modifire_meta), 'printf(v:val, char)')
  endfor
  for char in lower + other
    let R += map(copy(modifire_control), 'printf(v:val, char)')
  endfor
  for char in other
    let R += map(copy(modifire_shift), 'printf(v:val, char)')
  endfor
  return R
endfunction

function! s:special_key_table() "{{{1
  let D = {}
  for key in (s:fixed_special_key + s:function_key() + s:combination_key())
    let k = eval('"\' . key . '"')
    if has_key(D, k)
      continue
    else
      let D[k] = key
    endif
  endfor
  return D
endfunction

function! smalls#util#use(list) "{{{1
  let u = {}
  for fname in a:list
    let u[fname] = function(s:sid . fname)
  endfor
  return u
endfunction

function! smalls#util#import(fname) "{{{1
  return function(s:sid . a:fname)
endfunction
"}}}
" vim: foldmethod=marker
