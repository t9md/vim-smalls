let s:pattern_for = smalls#util#import("pattern_for")

let s:finder = {}
function! s:finder.new(owner) "{{{1
  let self.owner = a:owner
  let self.env = a:owner.env
  let self.conf = a:owner.conf
  return self
endfunction

function! s:finder.one(word) "{{{1
  return self.all(a:word, 1)
endfunction

function! s:finder.all(word, ...) "{{{1
  let one = !empty(a:000)
  let RESULT = []
  if empty(a:word) | return RESULT | endif

  try
    for start in [ 'cursor_NEXT_COL', 'cursor_TOW' ]
      call self[start]()
      call self.search(s:pattern_for(a:word, self.conf.wildchar),
            \ RESULT, self.env['w$'], one)
      if one && !empty(RESULT) | return RESULT | endif
    endfor
  finally
    call self.env.p.set()
  endtry
  return RESULT
endfunction

function! s:finder.search(word, RESULT, stopline, one) "{{{1
  let line_org = self.env.p.line "cache
  while 1
    let pos = searchpos(a:word, 'c', a:stopline)
    if pos == [0, 0] | break | endif

    let linum = foldclosedend(pos[0]) " skip fold
    if linum != -1
      if linum == self.env['w$'] | break | endif
      call cursor(linum + 1 , 1)
      continue
    endif

    if line_org <= pos[0] && index(a:RESULT, pos) != -1
      break
    endif
    call add(a:RESULT, pos)
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

function! smalls#finder#new(owner) "{{{1
  return s:finder.new(a:owner)
endfunction
"}}}
" vim: foldmethod=marker
