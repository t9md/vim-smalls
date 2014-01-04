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
      \ 'SmallsRegion':     102,
      \ 'SmallsCurrent':    107,
      \ 'SmallsPos':        106,
      \ 'SmallsJumpTarget': 111,
      \ }

function! s:h.new(conf, env) "{{{1
  let self.conf = a:conf
  let self.env  = a:env
  let self.ids = {}
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
  call self.hl("SmallsShade", '\v'.
        \ s:intrpl('%{w0}l\_.*%{w$}l', self.env))
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
  let color = a:NOT_FOUND ? 'SmallsPos' : 'SmallsCurrent'
  let sleep_time = '80m'
  for i in range(2)
    call self.cword(color) | redraw | exe 'sleep' sleep_time
    call self.clear(color) | redraw | exe 'sleep' sleep_time
  endfor
endfunction

function! s:h._region(word, pos) "{{{1
  call self.clear("SmallsRegion")
  let wordlen = len(a:word)
  let vars = {
        \ 'nl': a:pos.line,
        \ 'nc': a:pos.col,
        \ 'ke': a:pos.col + wordlen - 1,
        \ }
  call extend(vars, self.env, 'error')

  " possibly move backward, so only adjust forward direction carefully.
  if a:pos.is_gt(self.env.p)
    let pat =
          \ self.env.mode =~# 'v\|o'
          \   ? '%{l}l%>{c-1}c\_.*%{nl}l%<{nc+1}c' :
          \ self.env.mode ==# 'V'
          \   ? '%{l}l\_.*%{nl}l' :
          \ self.env.mode ==# "\<C-v>" ?
          \   ( a:pos.is_ge_col(self.env.p)
          \   ? '\v\c%>{l-1}l%>{c-1}c.*%<{nl+1}l%<{ke+1}c'
          \   : '\v\c%>{l-1}l%>{nc-1}c.*%<{nl+1}l%<{c+1}c' )
          \ : NEVER_HAPPEN
  else
    let pat =
          \ self.env.mode =~# 'v\|o' ?
          \   '%{nl}l%>{nc}c\_.*%{l}l%<{c+2}c' :
          \ self.env.mode ==# 'V' ?
          \   '%{nl}l\_.*%{l}l' :
          \ self.env.mode ==# "\<C-v>" ?
          \   ( a:pos.is_ge_col(self.env.p)
          \   ? '\v\c%>{nl-1}l%>{c-1}c.*%<{l+1}l%<{ke+1}c'
          \   : '\v\c%>{nl-1}l%>{nc-1}c.*%<{l+1}l%<{c+1}c' )
          \ : NEVER_HAPPEN
  endif
  call self.hl("SmallsRegion", s:intrpl('\v\c'. pat, vars))
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

function! s:h._current(word, pos) "{{{1
  call self.clear("SmallsCurrent")

  let pos = smalls#pos#new({}, a:pos)
  let vars = {
        \ 'cl': pos.line,
        \ 'ke': pos.col + len(a:word) - 1,
        \ }
  " call extend(vars, self.env, 'error')
  let pattern = s:pattern_for(a:word, self.conf.wildchar)
        \ . s:intrpl('%{cl}l%{ke+1}c', vars)
  call self.hl("SmallsCurrent", pattern)
  if self.env.mode != 'n'
    call self._region(a:word, pos)
  endif
  return self
endfunction

function! smalls#highlighter#new(conf, env) "{{{1
  return s:h.new(a:conf, a:env)
endfunction

function! smalls#highlighter#extend_priority(table) "{{{1
  call extend(s:priorities, a:table, 'force')
endfunction

function! smalls#highlighter#get_table() "{{{1
  return s:priorities
endfunction
"}}}

" vim: foldmethod=marker
