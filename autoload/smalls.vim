let s:plog = smalls#util#import("plog")
let s:getchar = smalls#util#import("getchar")
let s:getchar_timeout = smalls#util#import("getchar_timeout")

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
function! s:smalls.init(dir, mode) "{{{1
  let self.mode = a:mode
  let self.lastmsg = ''
  let self.dir = a:dir
  let self._notfound   = 0
  let [c, l, w0, w_ ] = [col('.'), line('.'), line('w0'), line('w$') ]
  let self.env = {
        \ 'mode': a:mode,
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
  let self.cli_keyboard = self.cli_keyboard_init()
  let self._break = 0
endfunction

function! s:smalls.cli_keyboard_init() "{{{1
    let keyboard = smalls#keyboard#cli#new(self)
  call keyboard.bind("\<CR>",
        \ { 'func': self.do_jump_first, 'args': [keyboard], 'self': self })
  call keyboard.bind("\<F2>",
        \ { 'func': self.do_excursion, 'args': [keyboard], 'self': self })
  call keyboard.bind("\<Tab>",
        \ { 'func': self.do_move_next, 'args': [keyboard], 'self': self })
  " call keyboard.bind("\<F9>",
        " \ { 'func': self.debug, 'args': [keyboard], 'self': self })
  let jump_trigger = get(g:, "smalls_jump_trigger", g:smalls_jump_keys[0])
  call keyboard.bind(jump_trigger,
        \ { 'func': self.do_jump, 'args': [keyboard], 'self': self })
  return keyboard
endfunction

function! s:smalls.debug(kbd) "{{{1

  let g:V = self.hl
endfunction

function! s:smalls.finish() "{{{1
  if self._notfound
    call getchar(0)
    call self.blink_pos()
    call getchar(0)
    if self.mode !~ 'n\|o'
      normal! gv
    endif
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
          \ '&cursorline': 0,
          \ '&modifiable': 1,
          \ '&readonly':   0,
          \ '&spell':      0,
          \ }
          " \ '&virtualedit': 'all',
          " \ '&updatetime': g,
  let curbuf = bufname('')
  for [var, val] in items(opts)
    let self._opts[var] = getbufvar(curbuf, var)
    call setbufvar(curbuf, var, val)
    unlet var val
  endfor
endfunction

function! s:smalls.restore_opts() "{{{1
  for [var, val] in items(self._opts)
    call setbufvar(bufname(''), var, val)
    unlet var val
  endfor
endfunction

function! s:smalls.cursor_hide() "{{{1
  redir => cursor
  silent! highlight Cursor
  redir END
  if cursor !~# 'xxx'
    return ''
  endif
  let self.cursor_restore_cmd = 'highlight Cursor ' .
        \  substitute(matchstr(cursor, 'xxx \zs.*'), "\n", ' ', 'g')

  highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
endfunction

function! s:smalls.cursor_restore() "{{{1
  execute self.cursor_restore_cmd
endfunction

function! s:smalls.loop() "{{{1
  let kbd = self.cli_keyboard
  let hl = self.hl
  while 1
    call hl.shade()
    if kbd.data_len() ==# 0
      call hl.orig_pos()
    endif
    call kbd.show_prompt()

    if ! g:smalls_jump_keys_auto_show ||
          \ ( kbd.data_len() < g:smalls_jump_keys_auto_show_min_input_length )
      call kbd.input(s:getchar())
    else
      try
        call kbd.input(s:getchar_timeout(g:smalls_jump_keys_auto_show_timeout))
      catch /KEYBOARD_TIMEOUT/
        call self.do_jump(kbd)
      endtry
    endif

    if self._break
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
endfunction

function! s:smalls.start(dir, mode)  "{{{1
  let dir = { 'forward': 'fwd', 'backward': 'bwd', 'all': 'all' }[a:dir]
  try
    call self.init(dir, a:mode)
    call self.set_opts()
    call self.cursor_hide()
    call self.loop()
 catch
   if v:exception ==# "NotFound"
      let self._notfound = 1
    endif
    let self.lastmsg = v:exception
  finally
    call self.hl.clear()
    call self.restore_opts()
    call self.cursor_restore()
    call self.finish()
  endtry
endfunction

function! s:smalls.do_jump(kbd) "{{{1
  call self.hl.clear()
  call self.hl.shade()
  let pos_new = self.get_jump_target(a:kbd.data)
  if !empty(pos_new)
    call self.adjust_col(pos_new)
    call pos_new.jump(self._is_visual())
  endif
  let self._break = 1
endfunction

function! s:smalls._is_visual()
  return (self.mode != 'n' && self.mode != 'o')
endfunction

function! s:smalls.adjust_col(pos)
  if self.mode != 'o'
    return
  endif
  if self.dir == 'fwd'
    let a:pos.col += 1
    return
  endif

  " 'all' mode possibly move backward, so only adjust forward direction carefully.
  let org_p = self.env.p
  if ( org_p.line < a:pos.line ) ||
        \ (( org_p.line == a:pos.line ) && ( org_p.col < a:pos.col ))
    let a:pos.col += 1
  endif
endfunction

function! s:smalls.do_jump_first(kbd) "{{{1
  let found = self.finder.one(a:kbd.data)
  if !empty(found)
    let pos_new = smalls#pos#new(found)
    call self.adjust_col(pos_new)
    call pos_new.jump(self._is_visual())
  endif
  let self._break = 1
endfunction

function! s:smalls.do_move_next(kbd) "{{{1
  " very exprimental feature and won't document
  let word = a:kbd.data
  if empty(word) | return [] | endif
  let poslist  = self.finder.all(word)
  let max = len(poslist)
  let index = 0
  let index = (index + 1) % max
  call self.hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
  call self.hl.candidate(word, poslist[index])
  redraw
  while 1
    let c = s:getchar()
    if c == "\<Esc>"
      break
    elseif c ==# "n" | let index = (index +  1) % max
    elseif c ==# "N" | let index = ((index - 1) + max ) % max
    elseif c == ';'
      let pos_new = smalls#pos#new(poslist[index])
      call self.adjust_col(pos_new)
      call pos_new.jump(self._is_visual())
      break
    endif
    call self.hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
    call self.hl.candidate(word, poslist[index])
    redraw
  endwhile
  let self._break = 1
endfunction

function! s:smalls.do_excursion(kbd) "{{{1
  " very exprimental feature and won't document
  let word = a:kbd.data
  if empty(word) | return [] | endif
  let poslist  = self.finder.all(word)
  let max = len(poslist)
  let index = 0
  let [key_l, key_r, key_u, key_d, key_n, key_p ] = self.dir ==# 'bwd'
        \ ? [ 'l', 'h', 'j', 'k', 'p', 'n' ]
        \ : [ 'h', 'l', 'k', 'j', 'n', 'p' ]
  while 1
    let c = s:getchar()
    if c == "\<Esc>"
      break
    endif
    if     c == key_n | let index = (index +  1) % max
    elseif c == key_p | let index = ((index - 1) + max ) % max
    elseif c == "\<Tab>" | let index = (index +  1) % max
    elseif c == "\<S-Tab>" | let index = ((index - 1) + max ) % max
    elseif c =~ 'j\|k'
      let cl = poslist[index][0]
      while 1
        let index = c ==# key_d ? (index + 1) % max : ((index - 1) + max ) % max
        let nl = poslist[index][0]
        if cl != nl
          break
        endif
      endwhile
    elseif c =~ 'h\|l'
      let [cl, cc] = poslist[index]
      while 1
        let index = c ==# key_r ? (index + 1) % max : ((index - 1) + max ) % max
        let [nl, nc] = poslist[index]
        if cl == nl
          break
        endif
      endwhile
    elseif c == ';'
      let pos_new = smalls#pos#new(poslist[index])
      call self.adjust_col(pos_new)
      call pos_new.jump(self._is_visual())
      break
    endif
    call self.hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
    call self.hl.candidate(word, poslist[index])
    redraw
  endwhile
  let self._break = 1
endfunction

function! s:smalls.get_jump_target(word) "{{{1
  if empty(a:word) | return [] | endif
  let poslist = self.finder.all(a:word)
  let pos_new = smalls#jump#new(self.dir, self.env, self.hl).get_pos(poslist)
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
function! smalls#start(dir, mode) "{{{1
  call s:smalls.start(a:dir, a:mode)
endfunction "}}}
function! smalls#debug() "{{{
  let g:V = s:smalls.hl
  " echo PP(s:smalls)
endfunction
" vim: foldmethod=marker
