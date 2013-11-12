map <SID>xx <SID>xx
let s:sid = maparg("<SID>xx")
unmap <SID>xx
let s:sid = substitute(s:sid, 'xx', '', '')

function! s:plog(msg) "{{{1
  cal vimproc#system('echo "' . PP(a:msg) . '" >> ~/vim.log')
endfunction
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

" let s:metachar = '\=?/<>~ .{*^%|[''$()'
" function! s:escape(char)
  " return escape(a:char, s:metachar)
" endfunction

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
" vim: foldmethod=marker
