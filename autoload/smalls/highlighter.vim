let s:plog    = smalls#util#import("plog")

" function! s:intrpl(string, vars) "{{{1
  " let mark = '\v\{(.{-})\}'
  " return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
" endfunction "}}}

" function! s:intrpl(string, vars) "{{{1
  " let mark = '\v\{(.{-})\}'
  " for kv in items(a:vars)
    " exe 'let ' . join(kv, '=')
  " endfor
  " return substitute(a:string, mark,'\=eval(submatch(1))', '')
" endfunction "}}}

function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  let r = []
  for expr in s:scan(a:string, mark)
    call add(r, substitute(expr, '\v([a-z][a-z$0]*)', '\=a:vars[submatch(1)]', 'g'))
  endfor
  call map(r, 'eval(v:val)')
  return substitute(a:string, mark,'\=remove(r, 0)', 'g')
endfunction "}}}

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

let s:h = {}
let s:h.ids = []
let s:priorities = {
      \ 'SmallsShade':      101,
      \ 'SmallsCandidate':  103,
      \ 'SmallsRegion':     102,
      \ 'SmallsCurrent':    107,
      \ 'SmallsPos':        109,
      \ 'SmallsJumpTarget': 111,
      \ }

function! s:h.new(env) "{{{1
  let o = deepcopy(self)
  let o.env = a:env
  let o.ids = {}
  for color in keys(s:priorities)
    let o.ids[color] = []
  endfor
  return o
endfunction

function! s:h.dump() "{{{1
endfunction

function! s:h.hl(color, pattern) "{{{1
  call add(self.ids[a:color],
        \ matchadd(a:color, a:pattern, s:priorities[a:color]))
endfunction

function! s:h.clear(...) "{{{1
  let colors = a:0 ? a:000 : keys(self.ids)
  for color in colors
    if !has_key(self.ids, color)
      continue
    endif
    for id in self.ids[color]
      call matchdelete(id)
    endfor
    let self.ids[color] = []
  endfor
endfunction

function! s:h.shade() "{{{1
  if ! g:smalls_shade | return | endif
  let pat = s:intrpl('%{w0}l\_.*%{w$}l', self.env)
  call self.hl("SmallsShade", '\v'. pat )
endfunction

function! s:h.orig_pos() "{{{1
  " call self.hl('SmallsPos', '\%#')
  let pos = '%{l}l%{c}c'
  call self.hl("SmallsPos", s:intrpl('\v\c' . pos, self.env))
endfunction

function! s:h.blink_cursor() "{{{1
  " used to notify curor position to user when exit smalls
  let sleep_time = 80m
  for i in range(2)
    call self.orig_pos() | redraw! | exe 'sleep' sleep_time
    call self.clear()    | redraw! | exe 'sleep' sleep_time
  endfor
  " to avoid user's input mess buffer, we consume 
  " keyinput feeded while blinking.
  while getchar(1) | call getchar() | endwhile
endfunction

function! s:h.region(pos, word) "{{{1
  let wordlen = len(a:word)
  call self.clear("SmallsRegion")
  let e = {
        \ 'nl': a:pos[0],
        \ 'nc': a:pos[1],
        \ 'ke': a:pos[1] + wordlen - 1,
        \ }
  call extend(e, self.env, 'error')

  " possibly move backward, so only adjust forward direction carefully.
  if self._is_forward(a:pos)
    let pat =
          \ self.env.mode =~# 'v\|o' ? '%{l}l%>{c-1}c\_.*%{nl}l%<{nc+1}c' :
          \ self.env.mode ==# 'V' ? '%{l}l\_.*%{nl}l' :
          \ self.env.mode ==# "\<C-v>" ?
          \   ( self._is_col_forward(a:pos[1])
          \   ? '\v\c%>{l-1}l%>{c-1}c.*%<{nl+1}l%<{ke+1}c'
          \   : '\v\c%>{l-1}l%>{nc-1}c.*%<{nl+1}l%<{c+1}c' )
          \ : throw
  else
    let pat =
          \ self.env.mode =~# 'v\|o' ? '%{nl}l%>{nc}c\_.*%{l}l%<{c+2}c' :
          \ self.env.mode ==# 'V' ? '%{nl}l\_.*%{l}l' :
          \ self.env.mode ==# "\<C-v>" ?
          \   ( self._is_col_forward(a:pos[1])
          \   ? '\v\c%>{nl-1}l%>{c-1}c.*%<{l+1}l%<{ke+1}c'
          \   : '\v\c%>{nl-1}l%>{nc-1}c.*%<{l+1}l%<{c+1}c' )
          \ : throw
  endif
  call self.hl("SmallsRegion", s:intrpl('\v\c'. pat, e))
endfunction

function! s:h._is_forward(dst_pos) "{{{1
  return ( self.env.p.line < a:dst_pos[0] ) ||
        \ (( self.env.p.line == a:dst_pos[0] ) && ( self.env.p.col < a:dst_pos[1] ))
endfunction

function! s:h._is_col_forward(col) "{{{1
  return ( self.env.p.col <= a:col )
endfunction

function! s:h.jump_target(poslist) "{{{1
  let pattern = join(
        \ map(a:poslist, "'%'. v:val[0] .'l%'. v:val[1] .'c'" ), '|')
  call self.hl('SmallsJumpTarget', '\v'. pattern)
endfunction

function! s:h.candidate(word, pos) "{{{1
  call self.clear("Smallscandidate", "SmallsCurrent")
  if empty(a:word) | return | endif
  if empty(a:pos)  | return | endif
  let e = {
        \ 'cl': a:pos[0],
        \ 'ke': a:pos[1] + len(a:word) - 1,
        \ }
  let word = '\V'. escape(a:word, '\') . '\v'
  call extend(e, self.env, 'error')
  call self.hl("SmallsCandidate", s:intrpl('\v\c' . word , e))
  call self.hl("SmallsCurrent",   s:intrpl('\v\c' . word . '%{cl}l%{ke+1}c', e))
  if self.env.mode != 'n'
    call self.region(a:pos, a:word)
  endif
endfunction

function! smalls#highlighter#new(env) "{{{1
  return s:h.new(a:env)
endfunction

function! smalls#highlighter#extend_priority(table) "{{{1
  call extend(s:priorities, a:table, 'force')
endfunction

function! smalls#highlighter#get_table() "{{{1
  return s:priorities
endfunction
"}}}

" vim: foldmethod=marker
