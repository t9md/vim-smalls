" Base:
let s:getchar = smalls#util#import("getchar")
let s:plog = smalls#util#import("plog")
let s:getchar_timeout = smalls#util#import("getchar_timeout")

let s:keyboard = {}

" Usage of bind()
" call s:keyboard.bind(jump_trigger,
" \ { 'func': self.do_jump, 'args': [keyboard], 'self': self })
function! s:keyboard.bind(key, action) "{{{1
  let self._table[a:key] = a:action
endfunction

function! s:keyboard.read_input(...) "{{{1
  call self.show_prompt()
  " optional arg is timeout, empty or -1 mean 'no timeout'.
  if (a:0 && a:1 != -1)
    call self.input(s:getchar_timeout(a:1))
  else
    call self.input(s:getchar())
  end
endfunction

function! s:keyboard.init(owner, table, prompt_str) "{{{1
  let self._table  = a:table
  let self._prompt_str = a:prompt_str
  let self.owner   = a:owner
  let self._yanked = ''
  let self.data    = ''
  let self.cursor  = 0
  let self.input_history = []
  let self.input_history_max = 10
  return self
endfunction

function! s:keyboard.input_history_add(c) "{{{1
  call add(self.input_history, a:c)
  if len(self.input_history) > self.input_history_max
    echo remove(self.input_history, 0)
  endif
endfunction

function! s:keyboard.input(c) "{{{1
  call self.input_history_add(a:c)
  if !has_key(self._table, a:c)
    cal self._set( self._setchar(a:c) )
  else
    call self.execute(a:c)
  endif
endfunction

function! s:keyboard.execute(c) "{{{1
  let action = self._table[a:c]
  if type(action) ==# type('')
    if has_key(self, action)
      call self[action]()
    else
      call self._action_missing(action)
    endif
  elseif type(action) ==# type({})
    call call(action.func, action.args, action.self)
  endif
endfunction

function! s:keyboard._setchar(c)
  " should be overwitten
  return a:c
endfunction

function! s:keyboard.data_len() "{{{1
  return len(self.data)
endfunction

function! s:keyboard._action_missing(action) "{{{1
  " called when 'ation' was not found in _table
  " here hook do NOTHING, should be overwitten in subclass
endfunction

function! s:keyboard._set(c) "{{{1
  let self.data = self._before() . a:c .  self._after()
  let self.cursor += len(a:c)
endfunction 

function! s:keyboard._before() "{{{1
  return  self.cursor == 0 ? '' : self.data[ : self.cursor - 1]
endfunction

function! s:keyboard._after() "{{{1
  return self.data[self.cursor : ]
endfunction

function! s:keyboard.echohl(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction

function! s:keyboard.show_prompt() "{{{1
  " call self.echohl(self.cursor, "Number")
  " call self.echohl("[S]", 'Statement')
  call self.echohl(self._prompt_str, 'Identifier')
  call self.echohl(self._before(),  'SmallsCli')
  let after = self._after()
  if empty(after) | let after = ' ' | endif
  call self.echohl(after[0],  'SmallsCliCursor')
  call self.echohl(after[1:],  'SmallsCli')
  redraw
endfunction

function! smalls#keyboard#base#new(owner, table, prompt_str) "{{{1
  call filter(a:table, 'v:val != "__UNMAP__"')
  let kbd = deepcopy(s:keyboard)
  return kbd.init(a:owner, a:table, a:prompt_str)
endfunction "}}}

" vim: foldmethod=marker
