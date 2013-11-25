let s:plog    = smalls#util#import("plog")

function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction "}}}

let s:h = {}
let s:h.ids = []
let s:priorities = {
      \ 'SmallsShade':      101,
      \ 'SmallsCandidate':  103,
      \ 'SmallsRegion':     105,
      \ 'SmallsCurrent':    107,
      \ 'SmallsCursor':     109,
      \ 'SmallsJumpTarget': 111,
      \ }

function! s:h.new(env) "{{{1
  let self.env = a:env
  let self.ids = {}
  for color in keys(s:priorities)
    let self.ids[color] = []
  endfor
  return self
endfunction

function! s:h.dump() "{{{1
  echo PP(self)
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
endfunction "}}}

function! s:h.orig_pos()
  let pos = '%{l}l%{c}c'
  call self.hl("SmallsCursor",    s:intrpl('\v\c' . pos, self.env))
endfunction

function! s:h.blink_orig_pos()
  " used to notify user's mistake and spot cursor.
  " to avoid user's input mess buffer, we consume keyinput while blinking.
  let pat = s:intrpl('\v\c%{l}l%{c}c', self.env)
  for i in range(2)
    call getchar(0)
    call self.hl("SmallsCursor", pat)
    redraw!
    sleep 200m
    call self.clear()
    redraw!
    sleep 100m
  endfor
endfunction

function! s:h.region(pos, word) "{{{1
  let wordlen = len(a:word)
  call self.clear("SmallsRegion")
  let e = {
        \ 'nl': a:pos[0],
        \ 'nl+1': a:pos[0] + 1,
        \ 'nl-1': a:pos[0] - 1,
        \ 'nc': a:pos[1],
        \ 'nc+1': a:pos[1] + 1,
        \ 'nc-1': a:pos[1] - 1,
        \ 'ke+1': a:pos[1] + wordlen,
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

function! s:h.select(pos)
  exe 'normal! ' . "<Esc>"
  call self.env.p.set()
  exe 'normal! ' . self.env.mode
  call cursor(a:pos)
endfunction

function! s:h._is_forward(dst_pos) "{{{1
  return ( self.env.p.line < a:dst_pos[0] ) ||
        \ (( self.env.p.line == a:dst_pos[0] ) && ( self.env.p.col < a:dst_pos[1] ))
endfunction

function! s:h._is_col_forward(col) "{{{1
  return ( self.env.p.col < a:col )
endfunction


function! s:h.jump_target(poslist) "{{{1
  let hl_expr = join(
        \ map(a:poslist, "'%'. v:val[0] .'l%'. v:val[1] .'c'" ), '|')
  call self.hl('SmallsJumpTarget', '\v'. hl_expr)
endfunction

function! s:h.candidate(word, pos) "{{{1
  if empty(a:word) | return | endif
  if empty(a:pos)  | return | endif
  let wordlen = len(a:word)
  let e = {
        \ 'k':  '\V'. escape(a:word, '\'). '\v',
        \ 'cl':   a:pos[0],
        \ 'ke+1': a:pos[1] + wordlen,
        \ 'ke':   a:pos[1] + wordlen - 1,
        \ }

  let candidate   = '{k}'
  call extend(e, self.env, 'error')

  call self.hl("SmallsCandidate", s:intrpl('\v\c'. candidate, e))
  call self.hl("SmallsCurrent",   s:intrpl('\v\c{k}%{cl}l%{ke+1}c', e))
  " call self.hl("SmallsCursor",    s:intrpl('\v\c%{cl}l%{ke}c', e))
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
" vim: foldmethod=marker
