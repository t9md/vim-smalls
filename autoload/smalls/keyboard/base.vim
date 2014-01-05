" Base:
let s:getchar           = smalls#util#import("getchar")
let s:getchar_timeout   = smalls#util#import("getchar_timeout")
let s:special_key_table = smalls#util#import('special_key_table')()

let s:keyboard = {}

function! s:sort_val(v1, v2) "{{{1
  return a:v1[1] == a:v2[1]
        \ ? 0
        \ : a:v1[1] > a:v2[1] ? 1 : - 1
endfunction
"}}}

" Usage of bind()
" call s:keyboard.bind(jump_trigger,
"       \ { 'func': self.do_jump, 'args': [keyboard], 'self': self })
function! s:keyboard.bind(key, action) "{{{1
  let self._table[a:key] = a:action
endfunction

function! s:keyboard.read_input(...) "{{{1
  call self.show_prompt()
  " optional arg is timeout, empty or -1 mean 'no timeout'.
  let timeout = self._timeout_second()
  if timeout !=# -1
    call self.input(s:getchar_timeout(timeout))
  else
    call self.input(s:getchar())
  end
endfunction

function! s:keyboard._timeout_second() "{{{1
  " should overwrite in subclass
  return -1
endfunction

function! s:keyboard.init(owner, table, name, help) "{{{1
  let self._help             = a:help
  let self._table            = a:table
  let self.owner             = a:owner
  let self._yanked           = ''
  let self.name              = a:name
  let self.data              = ''
  let self.cursor            = 0
  let self.input_history     = []
  let self.input_history_max = 10
  return self
endfunction

function! s:keyboard.input_history_add(c) "{{{1
  call add(self.input_history, a:c)
  if len(self.input_history) > self.input_history_max
    call remove(self.input_history, 0)
  endif
endfunction

function! s:keyboard.input(c) "{{{1
  call self.input_history_add(a:c)
  if self._is_normal_key(a:c)
    cal self._set( self._setchar(a:c) )
  else
    call self.execute(a:c)
  endif
endfunction

function! s:keyboard._is_normal_key(c) "{{{1
  return !has_key(self._table, a:c)
endfunction

function! s:keyboard.execute(c) "{{{1
  call self.call_action(self._table[a:c])
endfunction

function! s:keyboard.call_action(action) "{{{1
  if type(a:action) ==# type('')
    if has_key(self, a:action)
      call self[a:action]()
    else
      call self._action_missing(a:action)
    endif
  elseif type(a:action) ==# type({})
    call call(a:action.func, a:action.args, a:action.self)
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
  " set char or chars into cursor position.
  let self.data = self._before() . a:c .  self._after()
  let self.cursor += len(a:c)
endfunction 

function! s:keyboard._before() "{{{1
  return  self.cursor == 0 ? '' : self.data[ : self.cursor - 1]
endfunction

function! s:keyboard._after() "{{{1
  return self.data[self.cursor : ]
endfunction

function! s:keyboard.msg(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echon a:msg
  echohl Normal
endfunction

function! s:keyboard.echo(msg, color) "{{{1
  silent execute 'echohl ' . a:color
  echo a:msg
  echohl Normal
endfunction

function! s:keyboard.help() "{{{1
  let helplang = split(self.owner.conf.helplang, ',')
  for lang in helplang + ['en']
    if has_key(self._help, lang)
      let desc_table = get(self._help, lang)
      break
    endif
  endfor

  let width_char   = 7
  let width_action = max(map(deepcopy(self._table), 'len(v:val)'))
  let width_desc   = max(map(deepcopy(desc_table), 'strdisplaywidth(v:val)'))

  let R = []
  let format = printf("| %%-%dS | %%-%dS | %%-%dS |",
        \ width_char, width_action, width_desc )
  let sep = printf(format,
        \ repeat('-', width_char),
        \ repeat('-', width_action),
        \ repeat('-', width_desc), 
        \ )
  call add(R, printf(format, 'Char', 'Action', 'Description'))
  call add(R, sep)

  for [char, action] in sort(items(self._table), function('s:sort_val'))
    if action =~# '^do_excursion_with_'
      let description = '[exc] do_' . matchstr(action, '^do_excursion_with_\zs.*$')
    else
      let description = get(desc_table, action, '')
    endif
    call add(R, printf(format,
          \ get(s:special_key_table, char, char), action, description) )
  endfor
  return join(R, "\n")
endfunction

function! s:keyboard.do_help() "{{{1
  call self.msg(self.help(), 'Type')
  call self.msg("\nType key to continue: ", 'Normal')
  call getchar()
endfunction

function! s:keyboard.show_prompt() "{{{1
  call self.show_id()
  call self.msg(printf(' %-2s', self._mode_str()), 'Statement')
  call self.msg(' > ', 'Identifier')
  call self.msg(self._before(),  'SmallsCli')
  let after = self._after()
  if empty(after) | let after = ' ' | endif
  call self.msg(after[0],  'SmallsCliCursor')
  call self.msg(after[1:],  'SmallsCli')
  redraw
endfunction

let s:mode_map = {
      \ 'n':      'N ',
      \ 'v':      'V ',
      \ 'V':      'VL',
      \ "\<C-v>": 'VB',
      \ 'o':      'OP',
      \ }

function! s:keyboard._mode_str() "{{{1
  return s:mode_map[self.owner.mode()]
endfunction

function! s:keyboard._prompt_str() "{{{1
  let mode = printf(' [ %-2s ]', s:mode_map[self.owner.mode()])
  return self.name . mode . ' > '
endfunction

function! smalls#keyboard#base#new(owner, table, name, help) "{{{1
  call filter(a:table, 'v:val != "__UNMAP__"')
  let kbd = deepcopy(s:keyboard)
  return kbd.init(a:owner, a:table, a:name, a:help)
endfunction "}}}

" vim: foldmethod=marker
