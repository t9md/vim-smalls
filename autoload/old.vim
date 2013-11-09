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
function! s:setup_keymap(keymap) "{{{1
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

function! s:key.exit() "{{{1
  throw "smalls-exit"
endfunction

function! s:key.delete() "{{{1
  let s = s:smalls
  let s._word = s._word[: -2]
  let [l,c] = getpos('.')[1:2]
  call cursor(l, c-1)
  call s.hl_clear()
  call s.hl_cursor()

  throw "smalls-delete"
endfunction

function! s:key.prev_candidate() "{{{1
  throw "smalls-prev"
endfunction
function! s:key.next_candidate() "{{{1
  let p =  getpos('.')

  call setpos(l, c-1)
  throw "smalls-next"
  " let self._debug = "NEXT"
endfunction

function! s:key.input(c) "{{{1
  let action = get(s:keymap, a:c, -1)
  if action ==# -1
    let s:smalls._word .= a:c
    return
  else
    call s:echo(action)
    call call(self[action], [], {})
  endif
endfunction
"}}}
