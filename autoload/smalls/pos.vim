let s:is_visual = smalls#util#import('is_visual')
let s:pattern_for = smalls#util#import("pattern_for")

let s:pos = {}
function! s:pos.new(owner, pos) "{{{1
  " a:pos => [line, col]
  let o = deepcopy(self)
  let [ o.line, o.col ] = a:pos
  let o.owner = a:owner
  return o
endfunction

function! s:pos.to_s() "{{{1
  return string(self.to_list())
endfunction

function! s:pos.to_list() "{{{1
  return [self.line, self.col]
endfunction

function! s:pos.set() "{{{1
  call cursor(self.line, self.col)
endfunction

function! s:pos.is_gt(pos) "{{{1
  return ( self.line > a:pos.line ) ||
        \ (( self.line == a:pos.line ) && ( self.col > a:pos.col ))
endfunction

function! s:pos.is_ge_col(pos) "{{{1
  return ( self.col >= a:pos.col )
endfunction

function! s:pos.is_ge_line(pos) "{{{1
  return ( self.line >= a:pos.line )
endfunction

function! s:pos.jump() "{{{1
  call self._adjust_col()

  let mode = self.owner.mode()
  if s:is_visual(mode)
    execute 'normal! ' . mode
  endif
  normal! m`
  call self.set()
endfunction

function! s:pos.is_wild() "{{{1
  return !empty(matchstr(self.word(), '\V' . self.owner.conf.wildchar))
endfunction

function! s:pos.word() "{{{1
  return self.owner.keyboard_cli.data
endfunction

function! s:pos.offset() "{{{1
  let word = self.word()
  return self.is_wild()
        \ ? len(matchstr(getline(self.line),
        \   s:pattern_for(word, self.owner.conf.wildchar)))
        \ : len(word)
endfunction
"}}}

unlockvar s:FWD_R s:BWD_L s:FWD_L s:BWD_R
let  [ s:FWD_R,    s:BWD_L,    s:FWD_L,   s:BWD_R  ] = [ 1, 2, 3, 4 ]
"    S---------E E---------+ +---------S +---------E
"    |         E E         | E         | |         |
"    +---------E E---------S E---------+ S---------+
lockvar s:FWD_R s:BWD_L s:FWD_L s:BWD_R

function! s:pos.analyze(pos_s, pos_e) "{{{1
  let S = a:pos_s
  let E = a:pos_e
  let CASE =
        \ ( S.line <= E.line && S.col <= E.col ) ? s:FWD_R :
        \ ( S.line >= E.line && S.col >= E.col ) ? s:BWD_L :
        \ ( S.line <  E.line && S.col >= E.col ) ? s:FWD_L :
        \ ( S.line >  E.line && S.col <= E.col ) ? s:BWD_R :
        \ NEVER_HAPPEN

  let [ U, D, L, R ] =
        \ CASE ==#  s:FWD_R ? [ S, E, S, E ] :
        \ CASE ==#  s:BWD_L ? [ E, S, E, S ] :
        \ CASE ==#  s:FWD_L ? [ S, E, E, S ] :
        \ CASE ==#  s:BWD_R ? [ E, S, S, E ] :
        \ NEVER_HAPPEN
  return { 'CASE': CASE, 'U': U, 'D': D, 'L': L, 'R': R }
endfunction

function! s:pos.adjust(case) "{{{1
  let offset = self.offset()
  let mode = self.owner.mode()
  let C      = a:case
  let pos_org = self.owner.pos()

  if     mode =~# 'v\|o'
    if (C ==# s:FWD_R || C ==# s:FWD_L) | let self.col += offset - 1 | endif
  elseif mode =~# "\<C-v>"
    if (C ==# s:FWD_R || C ==# s:BWD_R) | let self.col += offset | endif
    if (C ==# s:FWD_R || C ==# s:BWD_R) | let self.col -= 1      | endif
  endif

  if self.owner.conf.adjust !=# 'till'
    return
  endif
  if  mode ==# 'v'
    let self.col = (C ==# s:FWD_R || C==# s:FWD_L)
          \ ? self.col - offset
          \ : self.col + offset

  elseif mode ==# "\<C-v>"
    let self.col = (C ==# s:FWD_R || C==# s:FWD_R)
          \ ? self.col - offset
          \ : self.col + offset
  endif
endfunction

function! s:pos._adjust_col() "{{{1
  let pos_org = self.owner.pos()
  let p       = self.analyze(pos_org, self)
  let word    = self.owner.keyboard_cli.data
  call self.adjust(p['CASE'])
endfunction

function! smalls#pos#new(owner, pos) "{{{1
  return s:pos.new(a:owner, a:pos)
endfunction

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" vim: foldmethod=marker
