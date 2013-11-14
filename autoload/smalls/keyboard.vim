let s:getchar = smalls#util#import("getchar")

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
      \ "\<C-g>": "do_cancel",
      \ "\<C-b>": "do_char_backward",
      \ "\<Esc>": "do_cancel",
      \ }

function! keyboard.bind(key, action) "{{{1
  let self._table[a:key] = a:action
endfunction

function! keyboard.read() "{{{1
  call self.show_prompt()
  call self.input(s:getchar())
endfunction

function! keyboard.init(owner) "{{{1
  let self._table  = s:table
  let self.owner   = a:owner
  let self._yanked = ''
  let self.data    = ''
  let self.cursor  = 0

  let self.interrupt     = 0
  let self.interrupt_msg = ""
  return self
endfunction

function! keyboard.input(c) "{{{1
  if !has_key(self._table, a:c) 
    call self._set(a:c)
  else
    let action = self._table[a:c]
    if type(action) ==# type('')
      call self[action]()
    elseif type(action) ==# type({})
      call call(action.func, action.args, action.self)
    endif
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
  call s:echohl("[S]", 'Statement')
  call self.show_prompt()
  let c = s:getchar()
  if c == "\<C-w>"
    call self.do_set_cword()
  endif
endfunction

function! keyboard.do_set_cword()
  call self._set(expand('<cword>'))
endfunction

function! keyboard.do_cancel() "{{{1
  throw 'Canceled'
endfunction

function! keyboard.do_enter() "{{{1
  throw 'ENTER'
endfunction

function! s:echohl(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction

function! s:keyboard.show_prompt() "{{{1
  redraw
  " call s:echohl(self.cursor, "Number")
  call s:echohl("> ", 'Identifier')
  call s:echohl(self._before(),  'SmallsCli')
  let after = self._after()
  if empty(after) | let after = ' ' | endif
  call s:echohl(after[0],  'SmallsCliCursor')
  call s:echohl(after[1:],  'SmallsCli')
endfunction

function! smalls#keyboard#new(owner) "{{{1
  return s:keyboard.init(a:owner)
endfunction "}}}

let s:h = {}
function! s:h.hoge(arg)
  echo a:arg
  call self.hoga(a:arg)
endfunction
function! s:h.hoga(arg)
  echo toupper(a:arg)
endfunction
finish
function! Main() "{{{1
  call s:keyboard.init({})
  call s:keyboard.bind("\<F2>", { 'func': s:h.hoge, 'args': ["a"] , 'self': s:h })
  try
    let cnt = 1
    while (cnt < 10)
      call s:keyboard.read()
      let cnt += 1
    endwhile
  catch
    echo v:exception
  endtry
endfunction "}}}
" vim: foldmethod=marker
