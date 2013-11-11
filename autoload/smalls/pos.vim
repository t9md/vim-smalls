" POS:
let s:pos = {}
function! s:pos.new(pos) "{{{1
  " pos should size one List of [line, col]
  let o = deepcopy(self)
  let o.line = a:pos[0]
  let o.col  = a:pos[1]
  return o
endfunction

function! s:pos.to_s() "{{{1
  return string([self.line, self.col])
endfunction

function! s:pos.set(...) "{{{1
  if !a:0
    normal! m`
    call cursor(self.line, self.col)
  else
    call cursor(self.line, self.col)
  endif
endfunction

function! smalls#pos#new(pos) "{{{1
  return s:pos.new(a:pos)
endfunction

" vim: foldmethod=marker
