let s:debug = 0
" KeyMap:
"==================
" keymap {{{
let s:_keymap = {
      \ "exit"         : [ "\<Esc>", ";" ],
      \ "delete"       : [ "\<BS>", "\<C-h>" ],
      \ "head"         : [ "\<C-a>"],
      \ "end"          : [ "\<C-e>"],
      \ "char_forward" : [ "\<C-f>"],
      \ "char_back"    : [ "\<C-b>"],
      \ "next_candidate" : [ "\<Tab>", "\<C-n>"],
      \ "prev_candidate" : [ "\<C-p>"],
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
  let [l,c] = getpos('.')[1:2]
  call cursor(l, c-1)
  call s.hl_clear()
  call s.hl_cursor()

  throw "smalls-delete"
endfunction "}}}

function! s:key.prev_candidate() "{{{
  throw "smalls-prev"
endfunction "}}}
function! s:key.next_candidate() "{{{
  let p =  getpos('.')

  call setpos(l, c-1)
  throw "smalls-next"
  " let self._debug = "NEXT"
endfunction "}}}

function! s:echo(var)
  if s:debug 
    echo a:var
 endif
endfunction

function! s:key.input(c) "{{{
  let action = get(s:keymap, a:c, -1)
  if action ==# -1
    let s:smalls._word .= a:c
    return
  else
    call s:echo(action)
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
  " let self._guicursor = &guicursor
  " let &guicursor = 'n:hor1-SmallsCursorHide'
  "
  let self._retry = 0
  let self._notfound = 0
  let s:smalls._hl_ids = []
  let self._scrolloff = &scrolloff
  let &scrolloff = 0
  let view = winsaveview()
  let env = {
        \ "top": view.topline,
        \ "cur": view.lnum,
        \ "last": line('w$'),
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
  if exists("self._guicursor")
    silent set guicursor&
    let &guicursor = self._guicursor
  endif
  echo
endfunction "}}}

function! s:smalls.prompt() "{{{
  call s:echohl(self._prompt, "SmallsInput")
  call s:echohl(self._word)
  " call s:echohl(self._word)
  call s:redraw()
endfunction "}}}


function! s:smalls.spot() "{{{
  call self.init()
  " call cursor(self._env.top, 1)
  while 1
    " echo getpos('.')[1:2]
    call self.prompt()
    let c = self.input()
    try
      call s:key.input(c)
    catch /smalls-exit/
      break
    catch /smalls-delete/
      continue
    " catch /smalls-next/
    endtry
    " echo "===============PASS"

    call self.search(self._word, "ceW", self._env.last)
    call self.hl_clear()
    call self.hl_cursor()

    if self._notfound | break | endif
  endwhile

  call self.finish()
endfunction "}}}

function! s:smalls.search(word, opt, stopline) "{{{
  if empty(self._word) | return | endif

  " searchpos({pattern} [, {flags} [, {stopline} [, {timeout}]]])	*searchpos()*

  let found = searchpos(a:word, a:opt, a:stopline)
  if !(found == [0,0])
    echo "FOUND" . string(getpos('.'))
    let tl = foldclosedend(line('.'))
    if tl ==# -1
      return 1
    endif
    call cursor(tl+1, 1)
    echo "call from:" . string(getpos('.')) .
          \ " (" . join([a:word, a:opt, a:stopline],', ') . ")"
    call self.search(a:word, a:opt, a:stopline)
  else
    if self._retry
      let self._notfound = 1
      return 0
    endif
    call cursor(self._env.top, 1)
    let self._retry = 1
    call self.search(a:word, a:opt, self._env.cur)
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
  if empty(s) | return | endif
  " ex) [88,24] => '\%88l\%24c'
  let pattern = '\c' . s . '\%'. pos[1] .'l\%'. ( pos[2] + 1 ).'c'
  let cursor_pattern = '\%'. pos[1] .'l\%'. ( pos[2]).'c'
  let self._hl_ids += [ matchadd("SmallsCandidate", '\c' . s , 100) ]
  let self._hl_ids += [ matchadd("SmallsCurrent", pattern, 101) ]
  let self._hl_ids += [ matchadd("SmallsCursor",   cursor_pattern, 102) ]

  call s:redraw()
endfunction "}}}

function! s:redraw()
  if  s:debug | return | endif
  redraw
endfunction

" PublicInterface:
"===================
function! smalls#spot() "{{{
  call s:smalls.spot()
endfunction "}}}
function! smalls#debug() "{{{
  echo PP(s:keymap)
  echo "---"
  echo PP(s:smalls)
endfunction "}}}
" vim: foldmethod=marker
