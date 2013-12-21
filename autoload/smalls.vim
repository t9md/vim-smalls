let s:plog            = smalls#util#import("plog")
let s:getchar         = smalls#util#import("getchar")
let s:getchar_timeout = smalls#util#import("getchar_timeout")

let s:vim_options = {}
let s:vim_options.global = {
      \ '&scrolloff':  0
      \ }
let s:vim_options.buffer = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0, }
let s:vim_options.window = {
      \ '&cursorline': 0,
      \ '&spell':      0, }

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

function! s:preserve_env(mode) "{{{1
  " to get precise start point in visual mode.
  " if (a:mode != 'n' && a:mode != 'o') | exe "normal! gvo\<Esc>" | endif
  if (a:mode  =~# "v\\|V\\|\<C-v>" ) | exe "normal! gvo\<Esc>" | endif
  let [ l, c ] = [ line('.'), col('.') ]
  " for neatly revert original visual start/end pos
  if (a:mode  =~# "v\\|V\\|\<C-v>" ) | exe "normal! gvo\<Esc>" | endif
  return {
        \ 'mode': a:mode, 'w0': line('w0'), 'w$': line('w$'), 'l': l, 'c': c,
        \ 'p': smalls#pos#new([ l, c ]),
        \ }
endfunction
"}}}

" Main:
let s:smalls = {}

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

function! s:smalls.init(mode) "{{{1
  let self.lastmsg   = ''
  let self._notfound = 0
  let self._auto_set = 0
  let self._break    = 0
  let self._wins     = self.multi_win ? range(1, winnr('$')) : [ winnr() ]
  let self._winnr_main = winnr()

  let self.wins = {}

  call self.wincall(self._wins, self.win_setup, [a:mode], self)

  let wn_main      = winnr()
  let self.env     = self.wins[wn_main].env
  let self.hl      = self.wins[wn_main].hl
  let self.finder  = self.wins[wn_main].finder
  let self.kbd_cli = smalls#keyboard#cli#new(self)
endfunction

function! s:smalls.win_setup(wn, mode) "{{{1
  let env = s:preserve_env(a:mode)
  let self.wins[a:wn] = { 
        \ 'env': env,
        \ 'hl': smalls#highlighter#new(env),
        \ 'finder': smalls#finder#new(env),
        \ }
endfunction

function! s:smalls.wincall(wins, block, args, self) "{{{1
  try
    for wn in a:wins
      execute wn . 'wincmd w'
      call call(a:block, [wn] + a:args, a:self)
    endfor
  finally
    execute self._winnr_main . 'wincmd w'
  endtry
endfunction

function! s:smalls.set_opts() "{{{1
  let self.opts = smalls#opts#new()
  call self.opts.prepare(s:vim_options, self._wins).save().change()
endfunction

function! s:smalls.hl_shade(win) "{{{1
  call self.wins[a:win].hl.shade()
endfunction

function! s:smalls.hl_clear(wn) "{{{1
  call self.wins[a:wn].hl.clear()
endfunction

function! s:smalls.find_one(win, word) "{{{1
  let found = self.wins[a:win].finder.one(a:word)
  if empty(found)
    call self.wins[a:win].hl.clear()
    call remove(self.wins, a:win)
    if len(self.wins) == 0
      throw "NotFound"
    endif
  else
    call self.wins[a:win].hl.candidate(a:word, found)
  endif
endfunction

function! s:smalls.start(mode, auto_excursion, ...)  "{{{1
  try
    let self.auto_excursion = a:auto_excursion
    let self.multi_win      = a:0 ? 1 : 0
    call self.init(a:mode)

    call self.set_opts()
    " call self.cursor_hide()
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
    call self.wincall(keys(self.wins), self.hl_clear, [], self)
    call self.opts.restore()
    " call self.cursor_restore()
    call self.finish()
  endtry
endfunction

function! s:smalls.loop() "{{{1
  call self.update_mode('cli')
  let kbd = self.kbd_cli

  while 1
    call self.wincall(keys(self.wins), self.hl_shade, [], self)
    if has_key(self.wins, self._winnr_main)
      call self.hl.orig_pos()
    endif

    let timeout = 
          \ ( g:smalls_auto_jump &&
          \ ( kbd.data_len() >= g:smalls_auto_jump_min_input_length ))
          \ ? g:smalls_auto_jump_timeout : -1
    try
      call kbd.read_input(timeout)
    catch /KEYBOARD_TIMEOUT/
      call self.do_jump(kbd)
    endtry

    if self.auto_excursion &&
          \ kbd.data_len() >=# g:smalls_auto_excursion_min_input_length
      call self.do_excursion(kbd)
    endif
    call self.wincall(keys(self.wins), self.hl_clear, [], self)

    if kbd.data_len() ==# 0
      continue
    endif
    if self._break
      break
    endif

    " if g:smalls_auto_set &&
          " \ kbd.data_len() >=# g:smalls_auto_set_min_input_lenght
      " let founds = self.finder.all(kbd.data)
      " if len(founds) ==# 1
        " let self._auto_set = 1
        " call kbd.do_jump_first()
        " break
      " else
        " if empty(founds)
          " throw "NotFound"
        " else
          " let found = founds[0]
        " endif
      " endif
    " else
    call self.wincall(keys(self.wins), self.find_one, [kbd.data], self)
  endwhile
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

function! s:smalls.do_jump(kbd, ...) "{{{1
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

function! s:smalls._is_visual() "{{{1
  return (self.env.mode != 'n' && self.env.mode != 'o')
endfunction

function! s:smalls._need_adjust_col(pos) "{{{1
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
    let a:pos.col += self.kbd_cli.data_len() - 1
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

function! s:smalls.update_mode(mode) "{{{1
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
  call call(s:smalls.start, a:000, s:smalls)
endfunction

function! smalls#win_start(...) "{{{1
  call call( s:smalls.win_start, a:000, s:smalls)
endfunction

function! smalls#debug() "{{{1
endfunction
"}}}

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif
echo 'OK'

" let g:Test = {}
" function! Main()
  " " echo winnr()
  " let g:Test[winnr()] = s:smalls.preserve_env('n')
" endfunction
" call s:wincall('Main', [], {} )

" vim: foldmethod=marker
