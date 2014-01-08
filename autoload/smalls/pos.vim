let s:is_visual   = smalls#util#import('is_visual')
let s:pattern_for = smalls#util#import("pattern_for")

let s:pos = {}
function! s:pos.new(owner, pos) "{{{1
  " a:pos => [line, col]
  let o = deepcopy(self)
  let [ o.line, o.col ] = a:pos
  let o.owner = a:owner
  let o._where = ''
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

function! s:pos.jump() "{{{1
  call self.adjust()

  let mode = self.owner.mode()
  if s:is_visual(mode)
    execute 'normal! ' . mode
  endif
  normal! m`
  call self.set()
endfunction

function! s:pos.is_wild() "{{{1
  return !empty(matchstr(
        \ self.owner.word(), '\V' . self.owner.conf.wildchar))
endfunction

function! s:pos.offset() "{{{1
  let word = self.owner.word()
  let R = self.is_wild()
        \ ? len(matchstr(getline(self.line),
        \   s:pattern_for(word, self.owner.conf.wildchar)))
        \ : len(word)
  return R - 1
endfunction
"}}}

unlockvar s:FWD_R s:BWD_L s:FWD_L s:BWD_R
let  [ s:FWD_R,   s:FWD_L,    s:BWD_L,   s:BWD_R  ] = [ 1, 2, 3, 4 ]

"      BWD_L         BWD_R
"    ++++++++++- +++++++++++                        
"    ++++++++++- +++++++++++                        
"    ++++++++++S S----------                        
"    ----------S S++++++++++                        
"    ++++++++++- +++++++++++
"    ++++++++++- +++++++++++                        
"      FWD_L         FWD_R

lockvar s:FWD_R s:BWD_L s:FWD_L s:BWD_R

function! s:pos.where() "{{{1
  " determine case and return case number( CONSTANTS )
  if empty(self._where)
    let S = self.owner.pos()
    let E = self
    let self._where = 
          \ ( S.line <= E.line && S.col <= E.col ) ? s:FWD_R :
          \ ( S.line <  E.line && S.col >  E.col ) ? s:FWD_L :
          \ ( S.line >= E.line && S.col >  E.col ) ? s:BWD_L :
          \ ( S.line >  E.line && S.col <= E.col ) ? s:BWD_R :
          \ NEVER_HAPPEN
  endif
  return self._where
endfunction

function! s:pos.get_UDLR() "{{{1
  " return [ Up, Down, Left, Right ]
  let S = self.owner.pos()
  let E = self
  let CASE = self.where()
  return
        \ CASE ==#  s:FWD_R ? [ S, E, S, E ] :
        \ CASE ==#  s:BWD_L ? [ E, S, E, S ] :
        \ CASE ==#  s:FWD_L ? [ S, E, E, S ] :
        \ CASE ==#  s:BWD_R ? [ E, S, S, E ] :
        \ NEVER_HAPPEN
endfunction

function! s:pos.adjust() "{{{1
  let CASE    = self.where()
  let offset  = self.offset()
  let mode    = self.owner.mode()

  if     mode =~# 'v\|o'
    if (CASE ==# s:FWD_R || CASE ==# s:FWD_L) | let self.col += offset | endif
  elseif mode =~# "\<C-v>"
    if (CASE ==# s:FWD_R || CASE ==# s:BWD_R) | let self.col += offset | endif
  endif

  " [FIXME] need more precise adjustment when col is 0 or $
  if self.owner.conf.adjust ==# 'till'
    if  mode =~# 'v\|o'
      let self.col = (CASE ==# s:FWD_R || CASE ==# s:FWD_L)
            \ ? self.col - offset - 1
            \ : self.col + offset + 1

    elseif mode ==# "\<C-v>"
      let self.col = (CASE ==# s:FWD_R || CASE ==# s:FWD_R)
            \ ? self.col - offset - 1
            \ : self.col + offset + 1
    endif
    if ( CASE ==# s:FWD_L || CASE ==# s:FWD_R ) && self.col ==# 0
      let self.line -= 1
      let self.col = len(getline(self.line)) + 1
    endif
  elseif self.owner.conf.adjust ==# 'wordend'
    if  mode ==# 'n'
      let self.col += offset
    elseif mode =~# 'v\|o'
      if (CASE ==# s:BWD_R || CASE ==# s:BWD_L)
        let self.col += offset
      endif
    elseif mode ==# "\<C-v>"
      if (CASE ==# s:FWD_L || CASE ==# s:BWD_L)
        let self.col += offset
      endif
    endif
  endif
endfunction

function! smalls#pos#new(owner, pos) "{{{1
  return s:pos.new(a:owner, a:pos)
endfunction

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" vim: foldmethod=marker
