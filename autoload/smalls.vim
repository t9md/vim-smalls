let s:debug = 0
let g:smalls_shade = 1
let g:smalls_jump_keys = ';ABCDEFGHIJKLMNOPQRSTUVWXYZ'

let g:smalls_hl_priorities = {
      \ 'SmallsShade':       10,
      \ 'SmallsCandidate':  100,
      \ 'SmallsCurrent':    101,
      \ 'SmallsCursor':     102,
      \ 'SmallsJumpTarget': 200,
      \ }

" Util:
function! s:msg(msg, ...) "{{{1
  let color = a:0 ? a:1 : "Normal"
	echohl Type
	echon 'Smalls: '
	exec "echohl"  color
  echon a:msg
	echohl None
endfunction

function! s:echohl(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction
"}}}

" Main: redraw
let s:smalls = {}
function! s:smalls.init() "{{{1
  let self.prompt      = "> "
  let self.cancelled   = 0
  let self.lastpos     = [0,0]
  let self._notfound   = 0
  let s:smalls._hl_ids = []
  let self.pos_org     = getpos('.')[1:2]
  let env = {
        \ "top": line('w0'),
        \ "last": line('w$'),
        \ "cur": line('.'),
        \ "col": col('.'),
        \ }
  let self._word = ''
  let self.env = env
  let self._view = winsaveview()
endfunction

function! s:smalls.finish() "{{{1
  if self._notfound
    call self.blink_pos()
    call getchar(0)
  else
    let @/= self._word
  endif
endfunction

function! s:smalls.show_prompt() "{{{1
  call s:echohl(self.prompt, "SmallsInput")
  call s:echohl(self._word,  "Identifier")
  redraw
endfunction

function! s:smalls.log(msg)
  cal vimproc#system('echo "' . a:msg . '" >> ~/vimlog.log')
endfunction

function! Plog(msg)
  cal vimproc#system('echo "' . PP(a:msg) . '" >> ~/vimlog.log')
endfunction

function! s:smalls.getchar() "{{{1
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfunction

function! s:smalls.set_opts() "{{{1
  let self._opts = {}
  let opts = {
          \ '&scrolloff': 0,
          \ '&modified':    0,
          \ '&guicursor': 'n:hor1-SmallsCursorHide',
          \ '&cursorline': 0,
          \ '&modifiable':  1,
          \ '&readonly':    0,
          \ '&spell':       0,
          \ }
  let self._opts = {}
  let curbuf = bufname('')
  for [var, val] in items(opts)
    let self._opts[var] = getbufvar(curbuf, var)
    call setbufvar(curbuf, var, val)
  endfor
endfunction

function! s:smalls.restore_opts() "{{{1
  for [var, val] in items(self._opts)
    if var == '&guicursor'
      silent set guicursor&
    endif
    call setbufvar(bufname(''), var, val)
  endfor
endfunction

  
function! s:smalls.start(dir)  "{{{1
  " dir: 0 => forward, 1 => backward
  call self.init()
  let self._dir = a:dir
  try
    call self.set_opts()

    while 1
      call self.hl_shade()
      call self.show_prompt()

      let c = self.getchar()
      if c == "\<Esc>"
        throw "CANCELLED"
      endif

      if c == ";"
        let pos_new =  self.get_jump_target()
        let self.lastpos = [pos_new.line, pos_new.col ]
        break
      endif

      if c ==# "\<C-h>" || c ==# "\<BS>"
        if len(self._word) >= 1
          let self._word = self._word[:-2]
        endif
      else
        let self._word .= c
      endif

      let found = self.gather_candidate(1)
      if empty(found)
        throw "NOT_FOUND"
      endif
      call self.hl_clear()
      call self.hl_candidate(found[0])
    endwhile

  catch
    if v:exception ==# "NOT_FOUND"
      let self._notfound = 1
      call self.hl_clear()
    elseif v:exception ==# "CANCELLED"
      let self.cancelled = 1
      call winrestview(self._view)
    endif
    call s:msg(v:exception)
  finally
    if self.lastpos != [0,0] && !self.cancelled
      call setpos('.', [0, self.lastpos[0], self.lastpos[1], 0])
    endif
    call self.hl_clear()
    call self.restore_opts()
    call self.finish()
  endtry
endfunction

let s:metachar = '\/~ .*^|[''$()'
function! s:smalls.escape(char)
  return escape(a:char, s:metachar)
endfunction


function! s:ensure(expr, err) "{{{1
  if ! a:expr
    throw a:err
  endif
endfunction

function! s:smalls.get_jump_target()
  let targets = self.gather_candidate()
  if empty(targets)
    return smalls#pos#new(self.lastpos)
  endif
  " call s:ensure( !empty(targets), "No candidate")
  " call self.plog(targets)
  let tgt2pos = smalls#grouping#SCTree(targets, split(g:smalls_jump_keys, '\zs'))
  let pos_new = smalls#ui#start(tgt2pos)
  return pos_new
endfunction

function! s:smalls.gather_candidate(...) "{{{1
  let limit = a:0 > 0 ? a:1 : 0
  let word = self.escape(self._word)
  let targets = []

  if empty(word)
    return targets
  endif

  let d = self._dir
  let [opt, stopline, fname, ope] =
        \ d ==# 'backward' ? [ 'b', self.env.top , 'foldclosed',    '-'] :
        \ d ==# 'forward' ?  [ '' , self.env.last, 'foldclosedend', '+'] : throw

  try
    while 1
      let pos = searchpos('\v'. word, opt, stopline)
      if pos == [0, 0] | break | endif

      let linum = function(fname)(pos[0])
      if linum != -1
        call cursor(eval('linum' . ope . '1') , pos[1])
        continue
      endif
      call add(targets, pos)
      if limit && (len(targets) >= limit )
        break
      endif
    endwhile
  finally
    call cursor(self.env.cur, self.env.col)
  endtry
  return targets
endfunction



function! s:smalls.hl_clear() "{{{1
  for id in self._hl_ids
    call matchdelete(id)
  endfor
  let self._hl_ids = []
endfunction

function! s:smalls.hl_candidate(pos) "{{{1
  if empty(self._word) | return | endif
  if empty(a:pos)      | return | endif
  
  let [line, col ] = a:pos
  let keyword = self.escape(self._word)
  call Plog(keyword)
  " ex) [88,24] => '\%88l\%24c'
  " let top        = self.env.top
  " let top_above  = top - 1
  " let last       = self.env.last
  " let last_below = last + 1
  " let line       = self.env.cur
  " let col        = self.env.col

  let top_above  = self.env.top - 1
  let last_below = self.env.last + 1
  let org_line   = self.env.cur
  let org_col    = self.env.col

  " let pat            = '\v(%>10l%<32l)'
  " let candidate       = '\v(%>10llet%<32l)'
  if self._dir==# 'forward'
    let curline       = '%%' . org_line . 'l%%>' . org_col . 'c' . '%s'
    let next2end      = '%%>' . org_line . 'l' .  '%s' . '%%<' . last_below . 'l'
    let candidate_pat = '\v(' . curline . ')' . '|' . '(' . next2end . ')'
    let candidate     = printf(candidate_pat, keyword, keyword)
  elseif self._dir ==# "backward"
    let curline       = '%%' . org_line . 'l' . '%s' . '%%<' . (org_col+1) . 'c'
    let next2top      = '%%>' . top_above . 'l' . '%s' . '%%<' . (org_line) . 'l'
    let candidate_pat = '\v(' . curline . ')' . '|' . '(' . next2top . ')'
    let candidate     = printf(candidate_pat, keyword, keyword)
  elseif self._dir ==# "left"
    let candidate     = '\v(%>'. top_above .'l%<' . org_col . 'c' . keyword
          \ . '%<' . last_below  . 'l)'
    " call self.log(candidate)
  elseif self._dir ==# "right"
    let candidate = '\v(%>'. top_above .'l%>' . org_col . 'c' . keyword 
          \ . '%<' . last_below . 'l)'
  end
  let self._hl_ids += [ matchadd("SmallsCandidate", '\c' . candidate , 100) ]

  let current = '\v\c' . keyword . '%'. line .'l%' . ( col + len(self._word)).'c'
  cal Plog(current)
  let self._hl_ids += [ matchadd("SmallsCurrent", current, 101) ]

  let hl_pos   = '\v%' . line . 'l%'. (col -1 + len(self._word)) .'c'
  let self._hl_ids += [ matchadd("SmallsCursor",   hl_pos, 102) ]
endfunction

function! s:smalls.hl_shade() "{{{1
  if ! g:smalls_shade | return | endif
  let top        = self.env.top
  let top_above  = top - 1
  let last       = self.env.last
  let last_below = last + 1
  let line       = self.env.cur
  let col        = self.env.col
  let pos        = '%' . line . 'l%'. col .'c'
  let forward    = pos . '\_.*%'. (last + 1).'l'
  let backward   = '%'. top .'l\_.*' . pos
  let right      = '%>'. top_above .'l%>' . (col -1) . 'c%<' . last_below . 'l'
  let left       = '%>'. top_above .'l%<' . (col +1) . 'c%<' . last_below . 'l'
  let hl_re = 
        \ self._dir ==# "backward" ? backward :
        \ self._dir ==# "forward"  ? forward  :
        \ self._dir ==# "right"    ? right    :
        \ self._dir ==# "left"     ? left     : throw

  let self._hl_ids += [ matchadd("SmallsShade", '\v' . hl_re, 10) ]
endfunction "}}}

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
