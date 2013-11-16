let s:plog = smalls#util#import("plog")

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

function! h.new(dir, env) "{{{1
  let self.env = a:env
  let self.dir = a:dir
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
  " call s:plog(self.ids)
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
  let pos = '%{l}l%{c}c'
  let pat = 
        \ self.dir ==# "fwd" ? s:intrpl(pos . '\_.*%{w$}l', self.env):
        \ self.dir ==# "bwd" ? s:intrpl('%{w0}l\_.*' . pos, self.env):
        \ self.dir ==# "all" ? s:intrpl('%{w0}l\_.*%{w$}l', self.env): throw
  call self.hl("SmallsShade", '\v'. pat )
endfunction "}}}

function! h.orig_pos()
  let pos = '%{l}l%{c}c'
  call self.hl("SmallsCursor",    s:intrpl('\v\c' . pos, self.env))
endfunction

function! h.region(pos) "{{{1
  call self.clear("SmallsRegion")
  let e = {
        \ 'nl': a:pos[0],
        \ 'nc': a:pos[1],
        \ 'nc+1': a:pos[1] + 1,
        \ }
  call extend(e, self.env, 'error')
  " let pos = '%{l}l%{c}c'
  let pat_table = {
        \ 'fwd': '%{l}l%>{c-1}c\_.*%{nl}l%<{nc+1}c',
        \ 'bwd': '%{nl}l%>{nc}c\_.*%{l}l%<{c}c',
        \ }
  " let block_pat_table = {
        " \ 'fwd': '%{l}l%>{c-1}c\_.*%{nl}l%<{nc+1}c',
        " \ 'bwd': '%{nl}l%>{nc}c\_.*%{l}l%<{c}c',
        " \ }
  
  " 'all' mode possibly move backward, so only adjust forward direction carefully.
  let pat_name = self.dir
  if self.dir     ==# 'all'
    let org_p = self.env.p
    if ( org_p.line < a:pos[0] ) ||
          \ (( org_p.line == a:pos[0] ) && ( org_p.col < a:pos[1] ))
      let pat_name = 'fwd'
    else
      let pat_name = 'bwd'
    endif
  endif
  let pat = pat_table[pat_name]
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

  if self.dir     ==# 'fwd'
    let curline     = '%{l}l%>{c}c{k}'
    let next2end    = '%>{l}l{k}%<{w$+1}l'
    let candidate   = '('. curline .')|('. next2end .')'
  elseif self.dir ==# "bwd"
    let curline     = '%{l}l{k}%<{c+1}c'
    let next2top    = '%>{w0-1}l{k}%<{l}l'
    let candidate   = '('.curline .')|('. next2top .')'
  elseif self.dir ==# "all"
    let candidate   = '{k}'
  end
  call extend(e, self.env, 'error')

  call self.hl("SmallsCandidate", s:intrpl('\v\c'. candidate, e))
  call self.hl("SmallsCurrent",   s:intrpl('\v\c{k}%{cl}l%{ke+1}c', e))
  call self.hl("SmallsCursor",    s:intrpl('\v\c%{cl}l%{ke}c', e))
  if self.env.mode != 'n'
    call self.region(a:pos)
  endif
endfunction

function! smalls#highlighter#new(dir, env) "{{{1
  return s:h.new(a:dir, a:env)
endfunction
" vim: foldmethod=marker