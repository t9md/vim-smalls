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

function! smalls#special_key_table#get() "{{{1
  return s:special_key_table()
endfunction
" vim: foldmethod=marker
