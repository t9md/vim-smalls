let s:U = smalls#util#use([ "escape", "plog" ])

function! s:interpolate(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction "}}}

let h = {}
let s:h = h
let h.ids = []
let s:priorities = {
      \ 'SmallsShade':       99,
      \ 'SmallsCandidate':  100,
      \ 'SmallsCurrent':    101,
      \ 'SmallsCursor':     102,
      \ 'SmallsJumpTarget': 103,
      \ }
function! h.new(dir, env) "{{{1
  let self.env = a:env
  let self.dir = a:dir
  let self.ids = {}
  return self
endfunction

function! h.hl(color, pattern) "{{{1
  let self.ids[a:color] = matchadd(a:color, a:pattern, s:priorities[a:color])
endfunction

function! h.clear(...) "{{{1
  let colors = a:0 ? a:000 : keys(self.ids)
  for color in colors
    if !has_key(self.ids, color)
      continue
    endif
    let id = self.ids[color]
    call matchdelete(id)
    unlet self.ids[color] 
  endfor
endfunction

function! h.shade() "{{{1
  if ! g:smalls_shade | return | endif
  let e = self.env
  let pos        = '%{l}l%{c}c'
  let forward    = pos . '\_.*%{w$}l'
  let backward   = '%{w0}l\_.*' . pos
  let all   = '%{w0}l\_.*%{w$}l'
  let pat = 
        \ self.dir ==# "backward" ? s:interpolate(backward,e) :
        \ self.dir ==# "forward"  ? s:interpolate(forward,e)  :
        \ self.dir ==# "all"      ? s:interpolate(all,e)      : throw

  call self.hl("SmallsShade", '\v'. pat )
endfunction "}}}
function! h.candidate(word, pos) "{{{1
  if empty(a:word) | return | endif
  if empty(a:pos)  | return | endif
  let wordlen = len(a:word)
  let e = {
        \ 'k':    s:U.escape(a:word),
        \ 'cl':   a:pos[0],
        \ 'ke+1': a:pos[1] + wordlen,
        \ 'ke':   a:pos[1] + wordlen - 1,
        \ }
  if self.dir==# 'forward'
    let curline   = '%{l}l%>{c}c{k}'
    let next2end  = '%>{l}l{k}%<{w$+1}l'
    let candidate = '\v\c('. curline .')|('. next2end .')'
  elseif self.dir ==# "backward"
    let curline   = '%{l}l{k}%<{c+1}c'
    let next2top  = '%>{w0-1}l{k}%<{l}l'
    let candidate = '\v\c('. curline .')|('. next2top .')'
  elseif self.dir ==# "all"
    let candidate = '\v\c{k}'
  end

  call extend(e, self.env, 'error')
  let candidate = s:interpolate(candidate, e)
  let current   = s:interpolate('\v\c{k}%{cl}l%{ke+1}c', e)
  let pos       = s:interpolate('\v\c%{cl}l%{ke}c', e)

  call self.hl("SmallsCandidate", '\c' . candidate)
  call self.hl("SmallsCurrent", current)
  call self.hl("SmallsCursor", pos)
endfunction

function! smalls#highlighter#new(dir, env) "{{{1
  return s:h.new(a:dir, a:env)
endfunction
" vim: foldmethod=marker
