let s:plog = smalls#util#import("plog")

let f = {} | let s:f = f
function! f.new(env) "{{{1
  let self.env = a:env
  return self
endfunction

function! f.one(word) "{{{1
  return self.all(a:word, 1)
endfunction

function! f.all(word, ...) "{{{1
  let one = a:0
  let self.found = []
  if empty(a:word)
    return found
  endif
  let word = '\V\c' . escape(a:word, '\')
  try
    call self.move_next_col()
    call self.search(word, 'c', self.env['w$'], one)
    if one && !empty(self.found)
      return self.found[0]
    endif
    " retry from line('w0')
    call self.move_begin_of_window()
    call self.search(word, 'c', self.env['w$'], one)
    if one && !empty(self.found)
      return self.found[0]
    endif
  finally
    call self.env.p.set()
  endtry
  return self.found
endfunction

function! f.search(word, opt, stopline, one) "{{{1
  while 1
    let pos = searchpos(a:word, a:opt, a:stopline)
    if pos == [0, 0]
      break
    endif
    " skip fold
    let linum = foldclosedend(pos[0])
    if linum != -1
      if linum == self.env['w$']
        break
      endif
      call cursor(linum + 1 , 1)
      continue
    endif

    if index(self.found, pos) != -1 | break | endif
    call add(self.found, pos)
    if a:one | break | endif

    if self.is_EOL()
      call self.move_next_head_of_line()
    else
      call self.move_next_col()
    endif
  endwhile
endfunction


function! f.retry() "{{{1
  if self.firsttime
    call self.move_begin_of_window()
    let self.firsttime = !self.firsttime
    return 1
  else
    return 0
  endif
endfunction
function! f.is_EOL() "{{{1
  return (col('.') >= col('$') - 1)
endfunction

function! f.is_end_of_window() "{{{1
  return line('.') == self.env['w$']
endfunction

function! f.move_begin_of_window() "{{{1
  call cursor(self.env['w0'], 1)
endfunction

function! f.move_next_head_of_line() "{{{1
  call cursor(line('.') + 1, 1)
endfunction

function! f.move_next_col() "{{{1
  call cursor(0, col('.') + 1)
endfunction


function! smalls#finder#new(env) "{{{1
  return s:f.new(a:env)
endfunction
" vim: foldmethod=marker
