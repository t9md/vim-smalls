let s:plog = smalls#util#import("plog")

" Util:
function! s:msg(msg) "{{{1
  redraw
  call s:echohl('Smalls ', 'Type')
  call s:echohl(a:msg, 'Normal')
endfunction


function! s:echohl(msg, color) "{{{1
  try
    silent execute 'echohl ' . a:color
    echon a:msg
  finally
    echohl Normal
  endtry
endfunction
"}}}

" Main:
let s:smalls = {}
function! s:smalls.init(dir) "{{{1
  let self.lastmsg = ''
  let self.dir = a:dir
  let self.prompt      = "> "
  let self.cancelled   = 0
  let self.lastpos     = [0,0]
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
  let self.hl = smalls#highlighter#new(a:dir, self.env)
  let self.finder = smalls#finder#new(a:dir, self.env)
  let self._word = ''
  let self._view = winsaveview()
  call self.set_opts()
endfunction

function! s:smalls.finish() "{{{1
  if self._notfound
    call self.blink_pos()
    call getchar(0)
  else
    let @/= self._word
  endif
  redraw!
  if !empty(self.lastmsg)
    call s:msg(self.lastmsg)
  endif
endfunction

function! s:smalls.show_prompt() "{{{1
  redraw
  call s:echohl(self.prompt, 'Function')
  call s:echohl(self._word,  'Identifier')
endfunction

function! s:smalls.getchar() "{{{1
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
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
  try
    call self.init(a:dir)
    while 1
      call self.hl.shade()
      call self.show_prompt()

      let c = self.getchar()
      if c == "\<Esc>"
        throw "CANCELLED"
      elseif c == get(g:, "smalls_jump_trigger", g:smalls_jump_keys[0])
        call self.hl.clear('SmallsCurrent',
              \ 'SmallsCursor', 'SmallsCandidate')
        let pos_new = self.get_jump_target(self._word)
        if !empty(pos_new)
          call pos_new.jump()
        endif
        break
      elseif  c ==# "\<C-h>" || c ==# "\<BS>"
        if len(self._word) >= 1
          let self._word = self._word[:-2]
        endif
        if len(self._word) ==# 0
          call self.hl.clear()
          continue
        endif
      else
        let self._word .= c
      endif

      let found = self.finder.one(self._word)
      if empty(found)
        throw "NOT_FOUND"
      endif
      call self.hl.clear()
      call self.hl.candidate(self._word, found)
    endwhile

 catch
    if v:exception ==# "NOT_FOUND"
      let self._notfound = 1
      " call self.hl.clear()
    elseif v:exception ==# "CANCELLED"
      let self.cancelled = 1
      call winrestview(self._view)
    endif
    let self.lastmsg = v:exception
  finally
    call self.hl.clear()
    call self.restore_opts()
    call self.finish()
  endtry
endfunction

function! s:smalls.get_jump_target(word) "{{{1
  if empty(a:word)
    return []
  endif
  let targets = self.finder.all(a:word)
  let tgt2pos = smalls#grouping#SCTree(targets, split(g:smalls_jump_keys, '\zs'))
  let pos_new = smalls#ui#start(tgt2pos)
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
