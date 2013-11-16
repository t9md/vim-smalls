let s:getchar = smalls#util#import("getchar")

let keyboard = {}
let s:keyboard = keyboard

function! keyboard.bind(key, action) "{{{1
  let self._table[a:key] = a:action
endfunction


function! keyboard.read_timeout() "{{{1
  call self.show_prompt()
  call self.input(s:getchar())
endfunction

function! keyboard.init(owner, table, prompt_str) "{{{1
  let self._table  = a:table
  let self._prompt_str = a:prompt_str
  let self.owner   = a:owner
  let self._yanked = ''
  let self.data    = ''
  let self.cursor  = 0

  " let self.interrupt     = 0
  " let self.interrupt_msg = ""
  let self.last_input = ''
  return self
endfunction

function! keyboard.input(c) "{{{1
  let self.last_input = a:c
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

function! keyboard.data_len() "{{{1
  return len(self.data)
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

function! keyboard.echohl(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction

function! s:keyboard.show_prompt() "{{{1
  redraw
  " call self.echohl(self.cursor, "Number")
  call self.echohl(self._prompt_str, 'Identifier')
  call self.echohl(self._before(),  'SmallsCli')
  let after = self._after()
  if empty(after) | let after = ' ' | endif
  call self.echohl(after[0],  'SmallsCliCursor')
  call self.echohl(after[1:],  'SmallsCli')
endfunction

function! smalls#keyboard#base#new(owner, table, prompt_str) "{{{1
  let kbd = deepcopy(s:keyboard)
  return kbd.init(a:owner, a:table, a:prompt_str)
endfunction "}}}

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