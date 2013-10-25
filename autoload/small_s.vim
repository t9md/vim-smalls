" KeyMap:
"==================
" "{{{
" {
  " 'col': 21,
  " 'coladd': 0,
  " 'curswant': 21,
  " 'leftcol': 0,
  " 'lnum': 1,
  " 'skipcol': 0,
  " 'topfill': 0,
  " 'topline': 1
" }
" "}}}
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
  return "exit"
endfunction "}}}
function! s:key.delete() "{{{
  return "delete"
endfunction "}}}
function! s:key.input(c) "{{{
  let action = get(s:keymap, a:c, -1)
  let g:V = action
  if action ==# -1
    return
  endif
  if type(get(self, action)) ==# type(function("getchar"))
    let val = call(self[action], [], {})
  else
    let val = ''
  endif
  return val
endfunction "}}}

function! s:echohl(msg, ...) "{{{
  let hl = a:0 ? a:1 : "Identifier"
  silent execute 'echohl ' . hl
  echon a:msg
  echohl Normal
endfunction "}}}

" MainObject:
"==================
let s:samalls = {}
let s:samalls._prompt = "/"
func! s:samalls.input() "{{{
  let c = getchar()
  return type(c) == type(0)
        \ ? nr2char(c)
        \ : c
endf "}}}

function! s:samalls.init() "{{{
  let self._retry = 0
  let self._notfound = 0
  let s:samalls._hl_ids = []
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

function! s:samalls.finish() "{{{
  let &scrolloff = self._scrolloff

  call self.hl_clear()

  if self._notfound
    call winrestview(self._view)
  else
    let @/= self._word
  endif
  echo
endfunction "}}}

function! s:samalls.prompt() "{{{
  call s:echohl(self._prompt, "Function")
  call s:echohl(self._word)
endfunction "}}}

function! s:samalls.hl_clear() "{{{
  for id in self._hl_ids
    call matchdelete(id)
  endfor
  let self._hl_ids = []
endfunction "}}}

function! s:samalls.spot() "{{{
  call self.init()
  " call cursor(self._env.top, 1)
  while 1
    call self.prompt()
    redraw
    let c = self.input()
    let val = s:key.input(c)

    if !empty(val)
      if val ==# "exit"
        break
      elseif val ==# 'delete'
        let self._word = self._word[: -2]
      endif
    else
      let self._word .= c
    endif

    call self.hl_clear()
    if self.search()
      call self.hl_cursor()
      redraw
    else
      if !self._retry
        let self._retry = 1
        call self.hl_cursor()
        redraw
      else
        let self._notfound = 1
        let self._lastword = self._word
        break
      endif
    endif
  endwhile
  call self.finish()
endfunction "}}}

function! s:samalls.search() "{{{
  if self._retry
    call cursor(self._env.top, 1)
    return search(self._word, 'ceW', self._env.cur)
  else
    return search(self._word, 'ceW', self._env.last)
  endif
endfunction "}}}

function! s:samalls.hl_cursor() "{{{
  let pos = getpos('.')
  let s = self._word
  " ex) [88,24] => '\%88l\%24c'
  let pattern = '\c' . s . '\%'. pos[1] .'l\%'. ( pos[2] + 1 ).'c'
  let cursor_pattern = '\%'. pos[1] .'l\%'. ( pos[2]).'c'
  let self._hl_ids += [ matchadd("SmallsCandidate", '\c' . s , 100) ]
  let self._hl_ids += [ matchadd("SmallsCurrent", pattern, 101) ]
  let self._hl_ids += [ matchadd("SmallsCursor", cursor_pattern, 102) ]
endfunction "}}}

" PublicInterface:
"===================
function! samalls#spot() "{{{
  call s:samalls.spot()
endfunction "}}}
function! samalls#debug() "{{{
  echo PP(s:samalls)
endfunction "}}}
" vim: foldmethod=marker
