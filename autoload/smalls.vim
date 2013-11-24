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
function! s:smalls.init(mode) "{{{1
  let self.mode = a:mode
  let self.lastmsg = ''
  let self._notfound   = 0

  if self._is_visual()
    " to get precise start point in visual mode.
    " exe 'normal! ' . "\<Esc>"
    exe 'normal! gvo' | exe "normal! " . "\<Esc>"
  endif

  let [l, c, w0, w_ ] = [ line('.'), col('.'), line('w0'), line('w$') ]

  if self._is_visual()
    " for neatly revert original visual start/end pos
    exe 'normal! gvo' | exe "normal! " . "\<Esc>"
  endif
        " \ 'p': smalls#pos#new([c,l]),
  let self.env = {
        \ 'mode': a:mode,
        \ 'w0': w0,
        \ 'w0-1': w0-1,
        \ 'w$': w_,
        \ 'w$+1': w_+1,
        \ 'p': smalls#pos#new([l, c]),
        \ 'l': l,
        \ 'l-1': l-1,
        \ 'l+1': l+1,
        \ 'c': c,
        \ 'c-1': c-1,
        \ 'c+1': c+1,
        \ 'c+2': c+2,
        \ }
  let self.hl       = smalls#highlighter#new(self.env)
  let self.finder   = smalls#finder#new(self.env)
  let self.keyboard_cli = smalls#keyboard#cli#new(self)
  let self._break = 0
endfunction

function! s:smalls.finish() "{{{1
  if self._notfound
    if g:smalls_blink_on_notfound
      call self.hl.blink_orig_pos()
    endif
    if self.mode !~ 'n\|o'
      normal! gv
    endif
  endif
  redraw!
  if !empty(self.lastmsg)
    call s:msg(self.lastmsg)
  endif
  let g:smalls_current_mode = ''
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
  let kbd = self.keyboard_cli
  let g:smalls_current_mode = 'cli'
  let hl = self.hl
  while 1
    call hl.shade()
    if kbd.data_len() ==# 0
      call hl.orig_pos()
    endif

    let timeout = 
          \ ( g:smalls_jump_keys_auto_show &&
          \ ( kbd.data_len() >= g:smalls_jump_keys_auto_show_min_input_length ))
          \ ? g:smalls_jump_keys_auto_show_timeout : -1
    try
      call kbd.read_input(timeout)
    catch /KEYBOARD_TIMEOUT/
      call self.do_jump(kbd)
    endtry

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

function! s:smalls.start(mode)  "{{{1
  try
    call self.init(a:mode)
    call self.set_opts()
    call self.cursor_hide()
    call self.loop()
  catch
    if v:exception ==# "NotFound"
      let self._notfound = 1
    elseif v:exception ==# "Canceled"
      if self.mode !~ 'n\|o'
        normal! gv
      endif
    endif
    let self.lastmsg = v:exception
  finally
    call self.hl.clear()
    call self.restore_opts()
    call self.cursor_restore()
    call self.finish()
  endtry
endfunction

function! s:smalls.do_jump(kbd, ...) "{{{1
  " let wordend = a:0 ? 1 : 0
  call self.hl.clear()
  call self.hl.shade()

  let pos_new = self.get_jump_target(a:kbd.data)
  if !empty(pos_new)
    " if wordend
      " let pos_new.col += a:kbd.data_len() - 1
    " endif
    call self._jump_to_pos(pos_new)
  endif
  let self._break = 1
endfunction

function! s:smalls.do_jump_first(kbd) "{{{1
  let found = self.finder.one(a:kbd.data)
  if !empty(found)
    let pos_new = smalls#pos#new(found)
    call self._jump_to_pos(pos_new)
  endif
  let self._break = 1
endfunction

function! s:smalls._jump_to_pos(pos) "{{{1
  " FIXME
  " I can't determine my mind how much adjustment is appropriate.
  " need deep consideration
  call s:smalls._adjust_col(a:pos)
  " call s:smalls._adjust_col_aggressive(a:pos)
  call a:pos.jump(self._is_visual())
endfunction

function! s:smalls._is_visual() "{{{1
  return (self.mode != 'n' && self.mode != 'o')
endfunction

function! s:smalls._need_adjust_col(pos)
  if self.mode == 'n'
    return 0
  elseif self.mode ==# 'o'
    return self._is_forward(a:pos)
  elseif self._is_visual()
    if self.mode =~# 'v\|V'
      return self._is_forward(a:pos)
    elseif self.mode ==# "\<C-v>"
      return self._is_col_forward(a:pos.col)
  endif
endfunction

function! s:smalls._adjust_col(pos) "{{{1
  if self._need_adjust_col(a:pos)
    let a:pos.col += self.keyboard_cli.data_len() - 1
  endif
  if self.mode ==# 'o' && g:smalls_operator_always_inclusive
    if self._is_forward(a:pos)
      let a:pos.col += 1
      if a:pos.col > len(getline(a:pos.line))
        let a:pos.line += 1
        let a:pos.col = 1
      endif
    endif
  endif
endfunction


function! s:smalls._adjust_col_aggressive(pos) "{{{1
  if self.mode == 'n'
    return
  endif

  " possibly move backward, so only adjust forward direction carefully.
  if self.mode ==# 'o'
    if self._is_forward(a:pos)
      let a:pos.col += self.keyboard_cli.data_len() - 1
      let a:pos.col += 1
      if a:pos.col > len(getline(a:pos.line))
        let a:pos.line += 1
        let a:pos.col = 1
      endif
    endif
  endif

  if self._is_visual()
    if self.mode =~# 'v\|V'
      if self._is_forward(a:pos)
        let a:pos.col += self.keyboard_cli.data_len() - 1
      endif
    elseif self.mode ==# "\<C-v>"
      if self._is_col_forward(a:pos.col)
          let a:pos.col += self.keyboard_cli.data_len() - 1
      endif
    endif
  endif
endfunction

function! s:smalls._is_forward(dst_pos) "{{{1
  return ( self.env.p.line < a:dst_pos.line ) ||
        \ (( self.env.p.line == a:dst_pos.line ) && ( self.env.p.col < a:dst_pos.col ))
endfunction

function! s:smalls._is_col_forward(col) "{{{1
  return ( self.env.p.col < a:col )
endfunction


function! s:smalls.do_excursion(kbd, ...) "{{{1
  " force to update statusline by meaningless option update ':help statusline'
  let g:smalls_current_mode = 'excursion' | let &ro = &ro
  let first_dir = a:0 ? a:1 : ''
  let word = a:kbd.data
  if  empty(word) | return [] | endif
  let poslist  = self.finder.all(word)
  if len(poslist) ==# 1
    return
  endif
  let kbd = smalls#keyboard#excursion#new(self, word, poslist)

  if !empty(first_dir)
    call kbd['do_' . first_dir]()
    call self.hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
    call self.hl.candidate(word, kbd.pos())
  endif

  try
    while 1
      call kbd.read_input()
      if self._break
        break
      endif
      call self.hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
      call self.hl.candidate(word, kbd.pos())
      redraw
    endwhile
  catch 'BACK_CLI'
  " force to update statusline by meaningless option update ':help statusline'
    let g:smalls_current_mode = 'cli' | let &ro = &ro
    let self._break = 0
  endtry
endfunction

function! s:smalls.get_jump_target(word) "{{{1
  if empty(a:word) | return [] | endif
  let poslist = self.finder.all(a:word)
  let pos_new = smalls#jump#new(self.env, self.hl).get_pos(poslist)
  return pos_new
endfunction
"}}}

" PublicInterface:
function! smalls#start(mode) "{{{1
  call s:smalls.start(a:mode)
endfunction "}}}

function! smalls#debug() "{{{
  " let g:V = s:smalls.hl
  " echo PP(s:smalls)
endfunction
" vim: foldmethod=marker
