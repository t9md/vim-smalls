let s:pos = {}

function! s:pos.new(pos) "{{{1
  " a:pos => [line, col]
  let o = deepcopy(self)
  let o.line = a:pos[0]
  let o.col  = a:pos[1]
  return o
endfunction

function! s:pos.to_s() "{{{1
  return string(self.to_list())
endfunction

function! s:pos.to_list() "{{{1
  return [self.line, self.col]
endfunction

function! s:pos.set() "{{{1
  call cursor(self.line, self.col)
endfunction

function! s:pos.jump(...) "{{{1
  if a:0
    execute "normal! " . a:1
  endif
  normal! m`
  call self.set()
endfunction

function! smalls#pos#new(pos) "{{{1
  return s:pos.new(a:pos)
endfunction

" vim: foldmethod=marker
