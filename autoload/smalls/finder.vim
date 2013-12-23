let s:plog = smalls#util#import("plog")

let s:finder = {}

function! s:finder.new(env) "{{{1
  let self.env = a:env
  return self
endfunction

function! s:finder.one(word) "{{{1
  return self.all(a:word, 1)
endfunction

function! s:finder.all(word, ...) "{{{1
  let one = !empty(a:000)
  let self.found = []
  if empty(a:word) | return found | endif
  let word = '\V\c' . escape(a:word, '\')

  try
    for start in [ 'cursor_NEXT_COL', 'cursor_TOW' ]
      call self[start]()
      call self.search(word, 'c', self.env['w$'], one)
      if one && !empty(self.found) | return self.found[0] | endif
    endfor
  finally
    call self.env.p.set()
  endtry
  return self.found
endfunction

function! s:finder.search(word, opt, stopline, one) "{{{1
  let line_org = self.env.p.line "cache
  while 1
    let pos = searchpos(a:word, a:opt, a:stopline)
    if pos == [0, 0] | break | endif

    let linum = foldclosedend(pos[0]) " skip fold
    if linum != -1
      if linum == self.env['w$'] | break | endif
      call cursor(linum + 1 , 1)
      continue
    endif

    if line_org <= pos[0] && index(self.found, pos) != -1
      break
    endif
    call add(self.found, pos)
    if a:one | break | endif

    if self.cursor_is_EOL()
      call self.cursor_HONL()
    else
      call self.cursor_NEXT_COL()
    endif
  endwhile
endfunction

function! s:finder.cursor_is_EOL() "{{{1
  return (col('.') >= col('$') - 1)
endfunction

function! s:finder.cursor_is_EOW() "{{{1
  return line('.') == self.env['w$']
endfunction

function! s:finder.cursor_TOW() "{{{1
  " top of window
  call cursor(self.env['w0'], 1)
endfunction

function! s:finder.cursor_HONL() "{{{1
  " head of next line
  call cursor(line('.') + 1, 1)
endfunction

function! s:finder.cursor_NEXT_COL() "{{{1
  call cursor(0, col('.') + 1)
endfunction

function! smalls#finder#new(env) "{{{1
  return s:finder.new(a:env)
endfunction
"}}}
" vim: foldmethod=marker
