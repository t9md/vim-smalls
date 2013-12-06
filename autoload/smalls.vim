let s:plog            = smalls#util#import("plog")
let s:getchar         = smalls#util#import("getchar")
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
  let self.lastmsg   = ''
  let self._notfound = 0
  let self._auto_set = 0
  let self.env       = {}
  " need env.mode from here. used in serveral function.
  let self.env.mode  = a:mode

  " to get precise start point in visual mode.
  if self._is_visual() | exe "normal! gvo\<Esc>" | endif
  let [ l, c ] = [ line('.'), col('.') ]
  call extend(self.env, { 'w0': line('w0'), 'w$': line('w$'), 'l': l, 'c': c })
  let self.env.p = smalls#pos#new([l, c])

  " for neatly revert original visual start/end pos
  if self._is_visual() | exe "normal! gvo\<Esc>" | endif

  let self.hl           = smalls#highlighter#new(self.env)
  let self.finder       = smalls#finder#new(self.env)
  let self.keyboard_cli = smalls#keyboard#cli#new(self)
  let self._break       = 0
endfunction

function! s:smalls.finish() "{{{1
  if self._notfound
    if g:smalls_blink_on_notfound
      call self.hl.blink_cursor()
    endif
    if self._is_visual()
      normal! gv
    endif
  endif
  if g:smalls_auto_set_blink && !empty(self._auto_set)
    call self.hl.blink_cursor()
  endif
  redraw!
  if !empty(self.lastmsg)
    call s:msg(self.lastmsg)
  endif
  call self.update_mode('')
endfunction

let s:smalls_vim_options = {}
let s:smalls_vim_options.global = { '&scrolloff':  0 }
let s:smalls_vim_options.buffer = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0, }
let s:smalls_vim_options.window = {
      \ '&cursorline': 0,
      \ '&spell':      0, }

function! s:smalls.set_opts() "{{{1
  let self.opts = smalls#opts#new()
  call self.opts.prepare(s:smalls_vim_options, self._wins).save().change()
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
  call self.update_mode('cli')
  let kbd = self.keyboard_cli
  let hl  = self.hl
  while 1
    call hl.shade()
    call hl.orig_pos()

    let timeout = 
          \ ( g:smalls_jump_keys_auto_show &&
          \ ( kbd.data_len() >= g:smalls_jump_keys_auto_show_min_input_length ))
          \ ? g:smalls_jump_keys_auto_show_timeout : -1
    try
      call kbd.read_input(timeout)
    catch /KEYBOARD_TIMEOUT/
      call self.do_jump(kbd)
    endtry

    if self.auto_excursion &&
          \ kbd.data_len() >=# g:smalls_auto_excursion_min_input_length
      call self.do_excursion(kbd)
    endif
    call hl.clear()
    if kbd.data_len() ==# 0
      continue
    endif
    if self._break
      break
    endif

    if g:smalls_auto_set &&
          \ kbd.data_len() >=# g:smalls_auto_set_min_input_lenght
      let founds = self.finder.all(kbd.data)
      if len(founds) ==# 1
        let self._auto_set = 1
        call kbd.do_jump_first()
        break
      else
        if empty(founds)
          throw "NotFound"
        else
          let found = founds[0]
        endif
      endif
    else
      let found = self.finder.one(kbd.data)
    endif
    if empty(found)
      throw "NotFound"
    endif
    call hl.candidate(kbd.data, found)
  endwhile
endfunction

function! s:smalls.start(mode, auto_excursion, ...)  "{{{1
  try
    let self.auto_excursion = a:auto_excursion
    let self.multi_win = a:0 ? 1 : 0
    let self._wins = self.multi_win ? range(1, winnr('$')) : [ winnr() ]
    call self.init(a:mode)

    call self.set_opts()
    call self.cursor_hide()
    call self.loop()
  catch
    if v:exception ==# "NotFound"
      let self._notfound = 1
    elseif v:exception ==# "Canceled"
      if self._is_visual()
        normal! gv
      endif
    endif
    let self.lastmsg = v:exception
  finally
    call self.hl.clear()
    call self.opts.restore()
    call self.cursor_restore()
    call self.finish()
  endtry
endfunction

function! s:smalls.fork()
  if self.is_parent()
  else
  endif
endfunction

function! s:smalls.win_start(mode, ...)  "{{{1
  let self._wins = range(1, winnr('$')) 
  let err = 0
  try
    let self.auto_excursion = a:0 ? 1 : 0

    let self.wins = {}
    let winnr_main = winnr()

    for w in self._wins
      if w ==# winnr_main
        let self.wins[w] = self
      else
        let self.wins[w] = deepcopy(self)
      endif
      let self.wins[w]._winnr_main = winnr_main
      execute w  . 'wincmd w'
      call self.wins[w].init(a:mode)
    endfor
    call self.win_back()
    try
      call self.loop2()
    catch
      let err = 1
    endtry
  finally
    let winnum = winnr()
    let pwinnum = winnr('#')
    noautocmd windo call clearmatches()
    execute pwinnum . "wincmd w"
    execute winnum . "wincmd w"
    " call s:plog(' err = ' . err)
    if err
      call self.win_back()
    endif
  endtry
endfunction

function! s:windo(func, obj) "{{{
  let winnum = winnr()
  let pwinnum = winnr('#')
  " echo [pwinnum, winnum]
  " echo PP(a:func)
  " echo PP(a:obj)
  noautocmd windo call call(a:func, [], a:obj)
  execute pwinnum . "wincmd w"
  execute winnum . "wincmd w"
endfunction "}}}

function! s:smalls.is_main() "{{{1
  return self._winnr_main == winnr()
endfunction

function! s:smalls.win_back() "{{{1
  execute self._winnr_main . 'wincmd w'
endfunction

function! s:smalls.loop2() "{{{1
  let kbd = self.keyboard_cli
  let hl  = self.hl
  while 1
    for [win, smalls] in items(self.wins)
      execute win . 'wincmd w'
      call smalls.hl.shade()
    endfor
    call self.win_back()

    call hl.orig_pos()
    call kbd.read_input()
    if self._break | break | endif

    for [win, smalls] in items(self.wins)
      execute win . 'wincmd w'
      call smalls.hl.clear()
    endfor
    call self.win_back()

    if kbd.data_len() ==# 0
      continue
    endif

    let err_max = len(self.wins)
    let err = 0

    for [win, smalls] in items(self.wins)
      try
        call smalls.update_candidate(win, kbd.data)
      catch
        let err += 1
        call remove(self.wins, win)
        " call smalls.hl.shade()
        if err >= err_max
          throw "NotFound"
        endif
      endtry
    endfor
    call self.win_back()
  endwhile
endfunction

function! s:smalls.update_candidate(win, data)
  execute a:win . 'wincmd w'
  call self.hl.clear()
  let found =  self.finder.one(a:data)
  if empty(found)
    " call self.hl.clear()
    throw "NotFound"
  endif
  call self.hl.candidate(a:data, found)
endfunction

function!  s:wincall(func, args, self) "{{{
  let winnum = winnr()
  let pwinnum = winnr('#')
  noautocmd windo call call(a:func, a:args, a:self)
  execute pwinnum . "wincmd w"
  execute winnum . "wincmd w"
  redraw
endfunction

function! s:smalls.do_jump(kbd, ...) "{{{1

  if has_key(self, 'wins') && empty(a:000)
    for [win, smalls] in items(self.wins)
      execute win . 'wincmd w'
      call call(self.do_jump, [a:kbd, 1], smalls)
    endfor
    let self._break =  1
    return
  endif

  call self.hl.clear()
  call self.hl.shade()
  let pos_new = self.get_jump_target(a:kbd.data)
  if !empty(pos_new)
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
  call s:smalls._adjust_col(a:pos)
  if self._is_visual()
    call a:pos.jump(self.env.mode)
  else
    call a:pos.jump()
  endif
endfunction

function! s:smalls._set_to_pos(pos) "{{{1
  call s:smalls._adjust_col(a:pos)
  call a:pos.jump()
endfunction

function! s:smalls._is_visual() "{{{1
  return (self.env.mode != 'n' && self.env.mode != 'o')
endfunction

function! s:smalls._need_adjust_col(pos)
  if self.env.mode ==# 'n' | return 0 | endif
  if self.env.mode ==# 'o' | return self._is_forward(a:pos) | endif
  if self._is_visual()
    return self.env.mode =~# 'v\|V'
          \ ? self._is_forward(a:pos)
          \ : self._is_col_forward(a:pos.col)
  endif
endfunction

function! s:smalls._adjust_col(pos) "{{{1
  if self._need_adjust_col(a:pos)
    let a:pos.col += self.keyboard_cli.data_len() - 1
  endif
  if self.env.mode ==# 'o'
        \ && g:smalls_operator_motion_inclusive
        \ && self._is_forward(a:pos)
    let a:pos.col += 1
    if a:pos.col > len(getline(a:pos.line)) " line end
      let a:pos.line += 1
      let a:pos.col = 1
    endif
  endif
endfunction

function! s:smalls._is_forward(dst_pos) "{{{1
  return ( self.env.p.line < a:dst_pos.line ) ||
        \ (( self.env.p.line == a:dst_pos.line ) && ( self.env.p.col < a:dst_pos.col ))
endfunction

function! s:smalls._is_col_forward(col) "{{{1
  return ( self.env.p.col <= a:col )
endfunction

function! s:smalls.update_mode(mode)
  " force to update statusline by meaningless option update ':help statusline'
  let g:smalls_current_mode = a:mode
  let &ro = &ro
endfunction

function! s:smalls.do_excursion(kbd, ...) "{{{1
  let word = a:kbd.data
  if empty(word) | return [] | endif

  call self.update_mode('excursion')
  let first_action = a:0 ? a:1 : ''
  let poslist = self.finder.all(word)
  let kbd     = smalls#keyboard#excursion#new(self, word, poslist)

  try
    while 1
      call self.hl.clear()
      call self.hl.shade()
      call self.hl.orig_pos()

      if !empty(first_action)
        call kbd['do_' . first_action]()
        let first_action = ''
      endif

      call self.hl.candidate(word, kbd.pos())
      if self._break
        break
      endif
      call kbd.read_input()
      redraw
    endwhile
  catch 'BACK_CLI'
    call self.update_mode('cli')
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
function! smalls#start(...) "{{{1
  call call( s:smalls.start, a:000, s:smalls)
endfunction "}}}

function! smalls#win_start(...) "{{{1
  call call( s:smalls.win_start, a:000, s:smalls)
endfunction "}}}

function! smalls#debug() "{{{
endfunction
"}}}
" vim: foldmethod=marker
