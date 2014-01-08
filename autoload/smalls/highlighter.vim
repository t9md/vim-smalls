let s:pattern_for = smalls#util#import("pattern_for")

let s:h = {}
let s:h.ids = []
let s:priorities = {
      \ 'SmallsShade':      101,
      \ 'SmallsCandidate':  105,
      \ 'SmallsRegion':     104,
      \ 'SmallsCurrent':    107,
      \ 'SmallsPos':        106,
      \ 'SmallsJumpTarget': 111,
      \ }
      " \ 'SmallsPos':        106,

function! s:h.new(owner) "{{{1
  let self.owner = a:owner
  let self.conf  = a:owner.conf
  let self.env   = a:owner.env
  let self.ids   = {}
  for color in keys(s:priorities)
    let self.ids[color] = []
  endfor
  return self
endfunction

function! s:h.hl(color, pattern) "{{{1
  call add(self.ids[a:color],
        \ matchadd(a:color, a:pattern, s:priorities[a:color]))
endfunction

function! s:h.clear(...) "{{{1
  let colors = !empty(a:000) ? a:000 : keys(self.ids)
  for color in colors
    for id in self.ids[color]
      call matchdelete(id)
    endfor
    let self.ids[color] = []
  endfor
  return self
endfunction

function! s:h.shade() "{{{1
  if ! self.conf.shade
    return self
  endif
  let pattern = printf('\v%%%dl\_.*%%%dl', self.env['w0'], self.env['w$'])
  call self.hl("SmallsShade", pattern)
  return self
endfunction

function! s:h.cursor() "{{{1
  call self.hl('SmallsPos', '\%#')
  return self
endfunction

function! s:h.cword(color) "{{{1
  call self.hl(a:color, '\k*\%#\k*')
endfunction

function! s:h.blink_cword(NOT_FOUND) "{{{1
  " used to notify curor position to user when exit smalls
  let color      = a:NOT_FOUND ? 'SmallsPos' : 'SmallsCurrent'
  let sleep_time = '80m'
  for i in range(2)
    call self.cword(color) | redraw | exe 'sleep' sleep_time
    call self.clear(color) | redraw | exe 'sleep' sleep_time
  endfor
endfunction

function! s:h.offset_for(word, line) "{{{1
  return self.is_wild(a:word)
        \ ? len(matchstr(getline(a:line), s:pattern_for(a:word, self.conf.wildchar)))
        \ : len(a:word)
endfunction

function! s:h.refresh() "{{{1
  call self.shade().cursor().candidate().current().region()
endfunction

function! s:h.region() "{{{1
  call self.clear("SmallsRegion")
  if self.env.mode ==# 'n'
    return self
  endif
  let pos = self.env.dest
  if empty(pos)
    return self
  endif
  let E  = smalls#pos#new(self.owner, pos)
  let [U, D, L, R] = E.get_UDLR()
  call E.adjust()

  if self.env.mode =~# 'v\|o'
    let pat = printf('\v\c%%%dl%%%dc\_.*%%%dl%%%dc',
          \ U.line, U.col, D.line, D.col + 1)

  elseif self.env.mode =~# 'V'
    let pat = printf('\v\c%%%dl\_.*%%%dl', U.line, D.line)

  elseif self.env.mode =~# "\<C-v>"
    let pat = printf( '\v\c%%>%dl%%>%dc.*%%<%dl%%<%dc',
          \ U.line - 1, L.col - 1, D.line + 1, R.col + 1)
  endif
  call self.hl("SmallsRegion", pat)
  return self
endfunction

function! s:h.jump_target(poslist) "{{{1
  let pattern = join(
        \ map(a:poslist, "'%'. v:val[0] .'l%'. v:val[1] .'c'" ), '|')
  call self.hl('SmallsJumpTarget', '\v'. pattern)
  return self
endfunction

function! s:h.candidate() "{{{1
  call self.clear("SmallsCandidate")
  let word = self.owner.word()
  if empty(word) | return self | endif

  call self.hl("SmallsCandidate", s:pattern_for(word, self.conf.wildchar))
  return self
endfunction

function! s:h.is_wild(word) "{{{1
  return !empty(matchstr(a:word, '\V' . self.conf.wildchar))
endfunction

function! s:h.current() "{{{1
  call self.clear("SmallsCurrent")
  let word = self.owner.word()
  let pos  = self.owner.env.dest
  if empty(word) || empty(pos)
    return self
  endif
  let [line, col]  = pos
  let offset       = self.offset_for(word, line)
  let col         += offset

  let pattern = s:pattern_for(word, self.conf.wildchar) . 
        \ printf('%%%dl%%%dc', line, col)
  call self.hl("SmallsCurrent", pattern)
  return self
endfunction

function! smalls#highlighter#new(owner) "{{{1
  return s:h.new(a:owner)
endfunction

function! smalls#highlighter#extend_priority(table) "{{{1
  call extend(s:priorities, a:table, 'force')
endfunction

function! smalls#highlighter#get_table() "{{{1
  return s:priorities
endfunction
"}}}

" vim: foldmethod=marker
