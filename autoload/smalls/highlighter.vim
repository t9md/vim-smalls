let s:pattern_for = smalls#util#import("pattern_for")

function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  let r = []
  for expr in s:scan(a:string, mark)
    call add(r, substitute(expr, '\v([a-z][a-z$0]*)', '\=a:vars[submatch(1)]', 'g'))
  endfor
  call map(r, 'eval(v:val)')
  return substitute(a:string, mark,'\=remove(r, 0)', 'g')
endfunction

function! s:scan(str, pattern) "{{{1
  let ret = []
  let nth = 1
  while 1
    let m = matchlist(a:str, a:pattern, 0, nth)
    if empty(m)
      break
    endif
    call add(ret, m[1])
    let nth += 1
  endwhile
  return ret
endfunction
"}}}

let s:h = {}
let s:h.ids = []
let s:priorities = {
      \ 'SmallsShade':      101,
      \ 'SmallsCandidate':  103,
      \ 'SmallsRegion':     104,
      \ 'SmallsCurrent':    107,
      \ 'SmallsPos':        106,
      \ 'SmallsJumpTarget': 111,
      \ }
      " \ 'SmallsPos':        106,

function! s:h.new(owner, conf, env) "{{{1
  let self.owner = a:owner
  let self.conf  = a:conf
  let self.env   = a:env
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
    if !has_key(self.ids, color)
      continue
    endif
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
  " call self.hl("SmallsShade", '\v'.
        " \ s:intrpl('%{w0}l\_.*%{w$}l', self.env))
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
"}}}

function! s:h._region(word, pos) "{{{1
  let E = smalls#pos#new(self.owner, a:pos)
  let CASE = E.get_case(self.env.p)
  let [U, D, L, R] = E.pos_UDLR(CASE, self.env.p)
  call E.adjust(CASE)

  if self.env.mode =~# 'v\|o'
    let pat = printf('\v\c%%%dl%%>%dc\_.*%%%dl%%<%dc',
          \ U.line, U.col - 1, D.line, D.col + 1)
  elseif self.env.mode =~# 'V'
    let pat = printf('\v\c%%%dl\_.*%%%dl', U.line, D.line)
  elseif self.env.mode =~# "\<C-v>"
    let pat = printf( '\v\c%%>%dl%%>%dc.*%%<%dl%%<%dc',
          \ U.line - 1, L.col - 1, D.line + 1, R.col + 1)
  endif
  call self.hl("SmallsRegion", pat)
endfunction

function! s:h.jump_target(poslist) "{{{1
  let pattern = join(
        \ map(a:poslist, "'%'. v:val[0] .'l%'. v:val[1] .'c'" ), '|')
  call self.hl('SmallsJumpTarget', '\v'. pattern)
endfunction

function! s:h.candidate(word, pos) "{{{1
  call self.clear("SmallsCandidate")
  if empty(a:word) | return | endif
  if empty(a:pos)  | return | endif

  call self.hl("SmallsCandidate", s:pattern_for(a:word, self.conf.wildchar))

  call self._current(a:word, a:pos)
  return self
endfunction

function! s:h.is_wild(word)
  return !empty(matchstr(a:word, '\V' . self.conf.wildchar))
endfunction

function! s:h._current(word, pos) "{{{1
  call self.clear("SmallsCurrent")

  let dest      = smalls#pos#new({}, a:pos)
  let offset    = self.offset_for(a:word, dest.line)
  let dest.col += offset

  let pattern = s:pattern_for(a:word, self.conf.wildchar) . 
        \ printf('%%%dl%%%dc', dest.line, dest.col)
  call self.hl("SmallsCurrent", pattern)
  call self.clear("SmallsRegion")
  if self.env.mode != 'n'
    call self._region(a:word, a:pos)
  endif
  return self
endfunction

function! smalls#highlighter#new(owner, conf, env) "{{{1
  return s:h.new(a:owner, a:conf, a:env)
endfunction

function! smalls#highlighter#extend_priority(table) "{{{1
  call extend(s:priorities, a:table, 'force')
endfunction

function! smalls#highlighter#get_table() "{{{1
  return s:priorities
endfunction
"}}}

" vim: foldmethod=marker
