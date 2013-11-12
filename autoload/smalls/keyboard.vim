let keyboard = {}
let s:keyboard = keyboard
let s:table = {
      \ "\<C-h>": "do_delete",
      \ "\<BS>":  "do_delete",
      \ "\<C-a>": "do_head",
      \ "\<C-e>": "do_end",
      \ "\<C-f>": "do_char_forward",
      \ "\<C-r>": "do_special",
      \ "\<C-k>": "do_kill",
      \ "\<C-y>": "do_yank",
      \ "\<C-c>": "do_cancel",
      \ "\<C-b>": "do_char_backward",
      \ "\<CR>":  "do_enter",
      \ "\<Esc>":  "do_cancel",
      \ }

let jump_trigger = get(g:, "smalls_jump_trigger", g:smalls_jump_keys[0])
let s:table[jump_trigger] = "do_jump"

function! keyboard.do_jump() "{{{1
  " throw "JUMP"
  let self.interrupt = 1
  let self.interrupt_msg = "JUMP"
endfunction

function! keyboard.read() "{{{1
  call self.show_prompt()
  let c = s:getchar()
  call self.input(c)
endfunction

function! keyboard.init(owner) "{{{1
  let self._table = s:table
  let self.owner = a:owner
  let self._yanked = ''
  let self.data = ''
  let self.cursor = 0
  let self.interrupt = 0
  let self.interrupt_msg = ""
endfunction

function! keyboard.input(c) "{{{1
  if has_key(self._table, a:c) 
    call self[self._table[a:c]]()
  else
    call self._set(a:c)
  endif
endfunction

function! keyboard._set(c) "{{{1
  let self.data = self._before() . a:c .  self._after()
  let self.cursor += len(a:c)
endfunction 

function! keyboard._before() "{{{1
  return  self.cursor == 0 ? '' : self.data[ : self.cursor - 1]
endfunction
function! keyboard._after() "{{{1
  return self.data[self.cursor : ]
endfunction
function! keyboard.do_head() "{{{1
  let self.cursor = 0
endfunction
function! keyboard.data_len() "{{{1
  return len(self.data)
endfunction
function! keyboard.do_char_forward() "{{{1
  let self.cursor = min([self.cursor+1, self.data_len()])
endfunction
function! keyboard.do_char_backward() "{{{1
  let self.cursor = max([self.cursor-1, 0 ])
endfunction
function! keyboard.do_delete() "{{{1
  call self.do_char_backward()
  let self.data = self._before()
endfunction
function! keyboard.do_kill() "{{{1
  let self._yanked = self._after()
  let self.data = self._before()
endfunction
function! keyboard.do_yank() "{{{1
  call self._set(self._yanked)
endfunction
function! keyboard.do_end() "{{{1
  let self.cursor = len(self.data)
endfunction
function! keyboard.do_special() "{{{1
  redraw
  call s:echohl("[S]> ", 'Function')
  let c = s:getchar()
  if c == "\<C-w>"
    call self.do_set_cword()
  endif
endfunction

function! keyboard.do_set_cword()
  call self._set(expand('<cword>'))
endfunction

function! s:getchar() "{{{1
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfunction

function! keyboard.do_cancel() "{{{1
  throw 'CANCELED'
endfunction
function! keyboard.do_quit() "{{{1
  throw 'QUIT'
endfunction
function! keyboard.do_enter() "{{{1
  throw 'ENTER'
endfunction
function! keyboard.handle(c) "{{{1
  let self.data .= a:c
endfunction "}}}

function! s:echohl(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction

function! s:keyboard.show_prompt() "{{{1
  redraw
  " call s:echohl(self.cursor, "Number")
  call s:echohl("> ", 'Function')
  call s:echohl(self._before(),  'SmallsCli')
  let after = self._after()
  if empty(after) | let after = ' ' | endif
  call s:echohl(after[0],  'SmallsCliCursor')
  call s:echohl(after[1:],  'SmallsCli')
endfunction

function! Main() "{{{1
  call s:keyboard.init({})
  try
    while 1
      call s:keyboard.show_prompt()
      let c = s:getchar()
      call s:keyboard.input(c)
    endwhile
  catch
    echo v:exception
  endtry
endfunction "}}}

function! smalls#keyboard#new(owner) "{{{1
  call s:keyboard.init(a:owner)
  return s:keyboard
endfunction
" vim: foldmethod=marker
