function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction "}}}

let h = {} | let s:h = h
let h.ids = []
let s:priorities = {
      \ 'SmallsShade':       99,
      \ 'SmallsRegion':     102,
      \ 'SmallsCandidate':  101,
      \ 'SmallsCurrent':    103,
      \ 'SmallsCursor':     104,
      \ 'SmallsJumpTarget': 105,
      \ }

function! h.new(env) "{{{1
  let self.env = a:env
  let self.ids = {}
  for color in keys(s:priorities)
    let self.ids[color] = []
  endfor
  return self
endfunction

function! h.dump() "{{{1
  echo PP(self)
endfunction

function! h.hl(color, pattern) "{{{1
  call add(self.ids[a:color],
        \ matchadd(a:color, a:pattern, s:priorities[a:color]))
endfunction

function! h.clear(...) "{{{1
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

function! h.shade() "{{{1
  if ! g:smalls_shade | return | endif
  let pat = s:intrpl('%{w0}l\_.*%{w$}l', self.env)
  call self.hl("SmallsShade", '\v'. pat )
endfunction "}}}

function! h.orig_pos()
  let pos = '%{l}l%{c}c'
  call self.hl("SmallsCursor",    s:intrpl('\v\c' . pos, self.env))
endfunction

function! h.blink_orig_pos()
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

function! h.region(pos) "{{{1
  call self.clear("SmallsRegion")
  let e = {
        \ 'nl': a:pos[0],
        \ 'nc': a:pos[1],
        \ 'nc+1': a:pos[1] + 1,
        \ }
  call extend(e, self.env, 'error')
  " possibly move backward, so only adjust forward direction carefully.
  let org_p = self.env.p
  if ( org_p.line < a:pos[0] ) ||
        \ (( org_p.line == a:pos[0] ) && ( org_p.col < a:pos[1] ))
    let pat =  '%{l}l%>{c-1}c\_.*%{nl}l%<{nc+1}c'
  else
    let pat = '%{nl}l%>{nc}c\_.*%{l}l%<{c+2}c'
  endif
  call self.hl("SmallsRegion", s:intrpl('\v\c'. pat, e))
endfunction


function! h.candidate(word, pos) "{{{1
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
  call self.hl("SmallsCursor",    s:intrpl('\v\c%{cl}l%{ke}c', e))
  if self.env.mode != 'n'
    call self.region(a:pos)
  endif
endfunction

function! smalls#highlighter#new(env) "{{{1
  return s:h.new(a:env)
endfunction
" vim: foldmethod=marker
