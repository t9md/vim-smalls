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
      \ 'SmallsPos':        100,
      \ 'SmallsJumpTarget': 111,
      \ }
      " \ 'SmallsPos':        106,

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
  let pos_org = self.env.p
  let pos_new = smalls#pos#new({}, a:pos)
  let wordlen = len(a:word)

  let POSNEW_IS_GT     = pos_new.is_gt(pos_org)
  let POSNEW_IS_GE_COL = pos_new.is_ge_col(pos_org)

  " possibly move backward, so only adjust forward direction carefully.
  if self.env.mode =~# 'v\|o'
      let [ LINEs, COLs, LINEe, COLe ] = POSNEW_IS_GT
            \ ? [ pos_org.line, pos_org.col - 1, pos_new.line, pos_new.col + wordlen + 1 ]
            \ : [ pos_new.line, pos_new.col - 1, pos_org.line, pos_org.col + 2       ]
    let pat = printf('\v\c%%%dl%%>%dc\_.*%%%dl%%<%dc', LINEs, COLs, LINEe, COLe)

  elseif self.env.mode =~# 'V'
    let [ LINEs, LINEe ] = POSNEW_IS_GT
          \ ? [pos_org.line, pos_new.line ]
          \ : [pos_new.line, pos_org.line ]
    let pat = printf('\v\c%%%dl\_.*%%%dl', LINEs, LINEe)

  elseif self.env.mode =~# "\<C-v>"
    " let pos_new = smalls#pos#new({}, a:pos)
    " if self.is_wild(a:word)
      " let offset = len(matchstr(getline(new_pos.line),
            " \ s:pattern_for(a:word, self.conf.wildchar)))
      " let new_pos.col = new_pos.col + offset
    " else
      " let new_pos.col = new_pos.col + len(a:word)
    " endif

    let FWD_R = 1 " FORWARD  RIGHT
    let BWD_L = 2 " BACKWARD LEFT
    let FWD_L = 3 " FORWARD  LEFT
    let BWD_R = 4 " BACKWARD RIGHT

    "     [ FWD_R ]    [ BWD_L ]    [ FWD_L ]    [ BWD_R ]
    "    S---------+  E---------+  +---------S  +---------E
    "    |         |  |         |  |         |  |         |
    "    +---------E  +---------S  E---------+  S---------+
    let S = self.env.p
    let E = smalls#pos#new({}, a:pos)
    let E_L_ge = E.is_ge_line(S)
    let E_C_ge = E.is_ge_col(S)

    let CASE =
          \ (  E_L_ge &&  E_C_ge ) ? FWD_R :
          \ ( !E_L_ge && !E_C_ge ) ? BWD_L :
          \ (  E_L_ge && !E_C_ge ) ? FWD_L :
          \ ( !E_L_ge &&  E_C_ge ) ? BWD_R :
          \ NEVER_HAPPEN

    let [ U, D, L, R ] =
          \ CASE ==#  FWD_R  ?  [ S, E, S, E ] :
          \ CASE ==#  BWD_L  ?  [ E, S, E, S ] :
          \ CASE ==#  FWD_L  ?  [ S, E, E, S ] :
          \ CASE ==#  BWD_R  ?  [ E, S, S, E ] :
          \ NEVER_HAPPEN

    if CASE ==# FWD_R || CASE ==# BWD_R
      let R.col += wordlen - 1
    endif

    let [ LINEs, COLs, LINEe, COLe ] = [ U.line, L.col, D.line, R.col ]

          " \ CASE is FWD_R ? [ pU.line, pL.col, pD.line, pR.col + wordlen - 1 ] :
          " \ CASE is BWD_L ? [ pU.line, pL.col, pD.line, pR.col ] :
          " \ CASE is FWD_L ? [ pU.line, pL.col, pD.line, pR.col ] :
          " \ CASE is BWD_R ? [ pU.line, pL.col, pD.line, pR.col + wordlen - 1 ] :
    let fmt = '\v\c%%>%dl%%>%dc.*%%<%dl%%<%dc'
    let pat = printf( fmt , LINEs - 1, COLs - 1, LINEe + 1, COLe + 1)

    " let CASE =
          " \ (  POSNEW_IS_GT &&  POSNEW_IS_GE_COL ) ? FWD_R :
          " \ ( !POSNEW_IS_GT &&  POSNEW_IS_GE_COL ) ? BWD_L :
          " \ (  POSNEW_IS_GT && !POSNEW_IS_GE_COL ) ? FWD_L :
          " \ ( !POSNEW_IS_GT && !POSNEW_IS_GE_COL ) ? BWD_R :
          " \ NEVER_HAPPEN


                 " let self.u = u
  " let self.l = l       |       let self.r = r
                 " let self.d = d


    " let [ LINEs, COLs, LINEe, COLe ] =
          " \ CASE is FWD_R ? [ pos_org.line, pos_org.col, pos_new.line, pos_new.col - 1 + wordlen ] :
          " \ CASE is BWD_L ? [ pos_new.line, pos_org.col, pos_org.line, pos_new.col - 1 + wordlen ] :
          " \ CASE is FWD_L ? [ pos_org.line, pos_new.col, pos_new.line, pos_org.col               ] :
          " \ CASE is BWD_R ? [ pos_new.line, pos_new.col, pos_org.line, pos_org.col               ] :
          " \ NEVER_HAPPEN

    " let [ LINEs, COLs, LINEe, COLe ] =
          " \ CASE is FWD_R ? [ pos_org.line, pos_org.col, pos_new.line, pos_new.col - 1 + wordlen ] :
          " \ CASE is BWD_L ? [ pos_new.line, pos_org.col, pos_org.line, pos_new.col - 1 + wordlen ] :
          " \ CASE is FWD_L ? [ pos_org.line, pos_new.col, pos_new.line, pos_org.col               ] :
          " \ CASE is BWD_R ? [ pos_new.line, pos_new.col, pos_org.line, pos_org.col               ] :
          " \ NEVER_HAPPEN

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

  let pos = smalls#pos#new({}, a:pos)
  if self.is_wild(a:word)
    let offset = len(matchstr(getline(pos.line),
          \ s:pattern_for(a:word, self.conf.wildchar)))
    let pos.col = pos.col + offset
  else
    let pos.col = pos.col + len(a:word)
  endif

  let pattern = s:pattern_for(a:word, self.conf.wildchar)
        \ . s:intrpl('%{cl}l%{cc}c', { 'cl': pos.line, 'cc': pos.col })

  " call self.hl("SmallsCurrent", pattern)
  call self.clear("SmallsRegion")
  if self.env.mode != 'n'
    call self._region(a:word, a:pos)
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
