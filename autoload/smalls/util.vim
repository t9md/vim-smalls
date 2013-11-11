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


function! s:setlines(lines, key) "{{{1
  try
    " Try to join changes with previous undo block
    undojoin
  catch
  endtry

  " key is 'orig' or 'marker'
  for line_num in sort(keys(a:lines))
    call setline(line_num, a:lines[line_num][a:key])
  endfor
endfunction

function! s:getchar() "{{{1
  let char = getchar()
  if char == char2nr("\<Esc>")
    " Escape key pressed
    redraw
    call s:msg('Cancelled')
    return ''
  endif
  return nr2char(char)
endfunction

let s:metachar = '\=/~ .{*^%|[''$()'
function! s:escape(char)
  return escape(a:char, s:metachar)
endfunction

function! smalls#util#use(list) "{{{1
  let u = {}
  for fname in a:list
    let u[fname] = function(s:sid . fname)
  endfor
  return u
endfunction
" vim: foldmethod=marker
