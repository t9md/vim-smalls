" POS:
let pos = {} | let s:pos = pos
function! pos.new(pos) "{{{1
  " pos should size one List of [line, col]
  let o = deepcopy(self)
  let o.line = a:pos[0]
  let o.col  = a:pos[1]
  return o
endfunction

function! pos.to_s() "{{{1
  return string(self.to_list())
endfunction

function! pos.to_list() "{{{1
  return [self.line, self.col]
endfunction

function! pos.set() "{{{1
  call cursor(self.line, self.col)
endfunction

function! pos.jump(...) "{{{1
  if a:0 ? a:1 : 0
    normal! gv
  endif
  normal! m`
  call cursor(self.line, self.col)
endfunction

function! pos.jump_one_col_more() "{{{1
  let self.col += 1
  call self.jump()
endfunction

function! smalls#pos#new(pos) "{{{1
  return s:pos.new(a:pos)
endfunction

" vim: foldmethod=marker
