let s:is_visual = smalls#util#import('is_visual')

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

function! s:pos.jump() "{{{1
  call self._adjust_col()

  let mode = self.owner.mode()
  if s:is_visual(mode)
    execute 'normal! ' . mode
  endif
  normal! m`
  call self.set()
endfunction

function! s:pos._need_adjust_col() "{{{1
  let mode    = self.owner.mode()
  let pos_org = self.owner.pos()

  if mode ==# 'n' | return 0                   | endif
  if mode ==# 'o' | return self.is_gt(pos_org) | endif

  if s:is_visual(mode)
    return mode =~# 'v\|V'
          \ ? self.is_gt(pos_org)
          \ : self.is_ge_col(pos_org)
  endif
endfunction


function! s:pos._adjust_col() "{{{1
  let mode    = self.owner.mode()
  let pos_org = self.owner.pos()
  let wordlen = self.owner.keyboard_cli.data_len()
  if self._need_adjust_col()
    let self.col += (wordlen - 1)
  endif

  if mode ==# 'o' && self.owner.conf.operator_motion_inclusive && self.is_gt(pos_org)
    let self.pos.col += 1
    if self.col > len(getline(self.line)) " line end
      let self.line += 1
      let self.col = 1
    endif
  endif
  if self.owner.conf.adjust !=# 'till'
    return
  endif
  if mode ==# 'v'
    let self.col = self.is_gt(pos_org)
          \ ? self.col - wordlen
          \ : self.col + wordlen
  elseif mode ==# "\<C-v>"
    let self.col = self.is_ge_col(pos_org)
          \ ? self.col - wordlen
          \ : self.col + wordlen
  endif
  return self
endfunction



function! smalls#pos#new(owner, pos) "{{{1
  return s:pos.new(a:owner, a:pos)
endfunction

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" let pos1 = smalls#pos#new([3,3])
" let pos2 = smalls#pos#new([3,4])
" echo pos1.is_ge_col(pos2)
" echo pos2.is_forward_col(pos1)
" echo pos2.is_forward_to(pos1)

" vim: foldmethod=marker
