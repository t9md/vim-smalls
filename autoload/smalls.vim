let s:plog = smalls#util#import("plog")

" Util:
function! s:msg(msg) "{{{1
  redraw
  call s:echohl('Smalls ', 'Type')
  call s:echohl(a:msg, 'Normal')
endfunction


function! s:echohl(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction
"}}}

" Main:
let s:smalls = {}
function! s:smalls.init(dir) "{{{1
  let self.lastmsg = ''
  let self.dir = a:dir
  let self.prompt      = "> "
  " let self.cancelled   = 0
  let self._notfound   = 0
  let [c, l, w0, w_ ] = [col('.'), line('.'), line('w0'), line('w$') ]
  let self.env = {
        \ 'w0': w0,
        \ 'w0-1': w0-1,
        \ 'w$': w_,
        \ 'w$+1': w_+1,
        \ 'p': smalls#pos#new(getpos('.')[1:2]),
        \ 'l': l,
        \ 'c': c,
        \ 'c-1': c-1,
        \ 'c+1': c+1,
        \ }
  let self.hl       = smalls#highlighter#new(a:dir, self.env)
  let self.finder   = smalls#finder#new(a:dir, self.env)
  " let self._view    = winsaveview()
  let keyboard = smalls#keyboard#new(self)
  let self.keyboard = keyboard
endfunction

function! s:smalls.finish() "{{{1
  if self._notfound
    call getchar(0)
    call self.blink_pos()
    call getchar(0)
  " else
    " let @/= self._word
  endif
  redraw!
  if !empty(self.lastmsg)
    call s:msg(self.lastmsg)
  endif
endfunction

function! s:smalls.set_opts() "{{{1
  let self._opts = {}
  let opts = {
          \ '&scrolloff':  0,
          \ '&modified':   0,
          \ '&guicursor':  'n:hor1-SmallsCursorHide',
          \ '&cursorline': 0,
          \ '&modifiable': 1,
          \ '&readonly':   0,
          \ '&spell':      0,
          \ }
  let self._opts = {}
  let curbuf = bufname('')
  for [var, val] in items(opts)
    let self._opts[var] = getbufvar(curbuf, var)
    call setbufvar(curbuf, var, val)
    unlet var val
  endfor
endfunction

function! s:smalls.restore_opts() "{{{1
  for [var, val] in items(self._opts)
    if var == '&guicursor'
      silent set guicursor&
    endif
    call setbufvar(bufname(''), var, val)
    unlet var val
  endfor
endfunction

function! s:smalls.start(dir)  "{{{1
  let dir = { 'forward': 'fwd', 'backward': 'bwd', 'all': 'all' }[a:dir]
  try
    call self.init(dir)
    call self.set_opts()
    let kbd = self.keyboard
    let hl = self.hl
    while 1
      call hl.shade()
      call kbd.read()
      if self.handler(kbd)
        break
      endif
      call hl.clear()
      if kbd.data_len() ==# 0
        continue
      endif

      let found = self.finder.one(kbd.data)
      if empty(found)
        throw "NotFound"
      endif
      call hl.candidate(kbd.data, found)
    endwhile
 catch
   if v:exception ==# "NotFound"
      let self._notfound = 1
    " elseif v:exception ==# "Canceled"
      " let self.cancelled = 1
      " call winrestview(self._view)
    endif
    let self.lastmsg = v:exception
  finally
    call hl.clear()
    call self.restore_opts()
    call self.finish()
  endtry
endfunction

function! s:smalls.handler(keyboard) "{{{1
  let kbd = a:keyboard
  let hl  = self.hl
  if !kbd.interrupt
    return 0
  endif
  let kbd.interrupt = 0
  if kbd.interrupt_msg ==# 'JUMP'
    call hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
    let pos_new = self.get_jump_target(kbd.data)
    if !empty(pos_new)
      call pos_new.jump()
    endif
    return 1
  elseif kbd.interrupt_msg ==# 'JUMP_FIRST'
    let found = self.finder.one(kbd.data)
    if empty(found)
      throw "NOT_FOUND"
    endif
    call smalls#pos#new(found).jump()
    return 1
  endif
endfunction

function! s:smalls.get_jump_target(word) "{{{1
  if empty(a:word) | return [] | endif
  let poslist  = self.finder.all(a:word)
  " " if only one destination, we won't show jump screen.
  " if len(poslist) ==# 1
    " return smalls#pos#new(poslist[0])
  " endif
  let pos_new  = smalls#jump#get_pos(poslist)
  return pos_new
endfunction

function! s:smalls.blink_pos() "{{{1
  let s:blink_stay  = '200m'
  let s:blink_sleep = '200m'
  let [line, col ] = getpos('.')[1:2]
  let hl_pos   = '\%' . line . 'l\%'. col .'c'
  call self.blink("SmallsCursor", 2, hl_pos, 104)
endfunction

function! s:smalls.blink(hl, count, pattern, priority) "{{{1
 for i in range(1, a:count)
   let id = matchadd(a:hl, a:pattern, a:priority)
   redraw!
   execute "sleep " . s:blink_stay
   call matchdelete(id)
   redraw!
   if i >= a:count
     break
   endif
   execute "sleep " . s:blink_sleep
 endfor
endfunction
"}}}

" PublicInterface:
function! smalls#start(dir) "{{{1
  call s:smalls.start(a:dir)
endfunction "}}}
function! smalls#debug() "{{{
  echo PP(s:keymap)
  echo "---"
  echo PP(s:smalls)
endfunction
" vim: foldmethod=marker
