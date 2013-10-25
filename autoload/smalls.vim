" KeyMap:
"==================
" keymap {{{
let s:_keymap = {
      \ "exit"         : [ "\<Esc>", ";" ],
      \ "delete"       : [ "\<BS>", ";" ],
      \ "head"         : [ "\<C-a>"],
      \ "end"          : [ "\<C-e>"],
      \ "char_forward" : [ "\<C-f>"],
      \ "char_back"    : [ "\<C-b>"],
      \ }
 "}}}
function! s:setup_keymap(keymap) "{{{
  let keymap = {}
  for [action, keys] in items(a:keymap)
    for k in keys
      if ! has_key(keymap, k)
        let keymap[k] = action
      endif
    endfor
  endfor
  return keymap
endfunction "}}}

let s:keymap = s:setup_keymap( s:_keymap)
let s:key = {}

function! s:key.exit() "{{{
  throw "smalls-exit"
endfunction "}}}

function! s:key.delete() "{{{
  let s = s:smalls
  let s._word = s._word[: -2]
endfunction "}}}

function! s:key.input(c) "{{{
  let action = get(s:keymap, a:c, -1)
  if action ==# -1
    let s:smalls._word .= a:c
    return
  else
    call call(self[action], [], {})
  endif
endfunction "}}}

function! s:echohl(msg, ...) "{{{
  let hl = a:0 ? a:1 : "Identifier"
  silent execute 'echohl ' . hl
  echon a:msg
  echohl Normal
endfunction "}}}

" MainObject:
"==================
let s:smalls = {}
let s:smalls._prompt = ">> "
func! s:smalls.input() "{{{
  let c = getchar()
  return type(c) == type(0)
        \ ? nr2char(c)
        \ : c
endf "}}}

function! s:smalls.init() "{{{
  let self._guicursor = &guicursor
  let &guicursor = 'n:hor1-SmallsCursorHide'
  let self._retry = 0
  let self._notfound = 0
  let s:smalls._hl_ids = []
  let self._scrolloff = &scrolloff
  let &scrolloff = 0
  let view = winsaveview()
  let env = {
        \ "top": view.topline,
        \ "cur": view.topline + winline() - 1,
        \ "last": view.topline + winheight(0) - 1
        \ }
  let self._word = ''
  let self._env = env
  let self._view = view
endfunction "}}}

function! s:smalls.finish() "{{{
  let &scrolloff = self._scrolloff

  call self.hl_clear()

  if self._notfound
    call winrestview(self._view)
  else
    let @/= self._word
  endif
  silent set guicursor&
  let &guicursor = self._guicursor
  echo
endfunction "}}}

function! s:smalls.prompt() "{{{
  call s:echohl(self._prompt, "SmallsInput")
  call s:echohl(self._word)
  " call s:echohl(self._word)
  redraw
endfunction "}}}


function! s:smalls.spot() "{{{
  call self.init()
  " call cursor(self._env.top, 1)
  while 1
    call self.prompt()
    let c = self.input()

    try
      call s:key.input(c)
    catch /smalls-exit/
      break
    endtry

    if !self.search()
      if !self._retry
        call cursor(self._env.top, 1)
        let self._retry = 1
        continue
      else
        let self._notfound = 1
      endif
    endif

    call self.hl_clear()
    call self.hl_cursor()

    if self._notfound | break | endif
  endwhile

  call self.finish()
endfunction "}}}

function! s:smalls.search() "{{{
  if self._retry
    return search(self._word, 'ceW', self._env.cur)
  else
    return search(self._word, 'ceW', self._env.last)
  endif
endfunction "}}}

function! s:smalls.hl_clear() "{{{
  for id in self._hl_ids
    call matchdelete(id)
  endfor
  let self._hl_ids = []
endfunction "}}}

function! s:smalls.hl_cursor() "{{{
  let pos = getpos('.')
  let s = self._word
  " ex) [88,24] => '\%88l\%24c'
  let pattern = '\c' . s . '\%'. pos[1] .'l\%'. ( pos[2] + 1 ).'c'
  let cursor_pattern = '\%'. pos[1] .'l\%'. ( pos[2]).'c'
  let self._hl_ids += [ matchadd("SmallsCandidate", '\c' . s , 100) ]
  let self._hl_ids += [ matchadd("SmallsCurrent", pattern, 101) ]
  let self._hl_ids += [ matchadd("SmallsCursor",   cursor_pattern, 102) ]
  redraw
endfunction "}}}

" PublicInterface:
"===================
function! smalls#spot() "{{{
  call s:smalls.spot()
endfunction "}}}
function! smalls#debug() "{{{
  echo PP(s:smalls)
endfunction "}}}
" vim: foldmethod=marker
