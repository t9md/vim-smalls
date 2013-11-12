let keyboard = {}
let s:keyboard = keyboard
let s:table = {
      \ "\<C-h>": "do_delete",
      \ "\<BS>":  "do_delete",
      \ "\<C-a>": "do_head",
      \ "\<C-e>": "do_end",
      \ "\<C-f>": "do_char_forward",
      \ "\<C-k>": "do_kill",
      \ "\<C-y>": "do_yank",
      \ "\<C-c>": "do_quit",
      \ "\<C-b>": "do_char_backward",
      \ "\<CR>":  "do_enter",
      \ "\<Esc>":  "do_cancel",
      \ }

function! keyboard.init() "{{{1
  let self._table = s:table
  let self._yanked = ''
  let self.data = ''
  let self.cursor = 0
endfunction

function! keyboard.input(c) "{{{1
  if has_key(self._table, a:c) 
    call self[self._table[a:c]]()
  else
    call self.set(a:c)
  endif
endfunction

function! keyboard.set(c) "{{{1
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
  call self.set(self._yanked)
endfunction
function! keyboard.do_end() "{{{1
  let self.cursor = len(self.data)
endfunction
function! keyboard.do_cancel() "{{{1
  throw "CANCEL"
endfunction
function! keyboard.do_quit() "{{{1
  throw "QUIT"
endfunction

function! keyboard.do_enter() "{{{1
  echo self.data
  throw "ENTER"
endfunction

function! keyboard.handle(c) "{{{1
  let self.data .= a:c
endfunction "}}}
function! s:echohl(msg, color) "{{{1
  try
    silent execute 'echohl ' . a:color
    echon a:msg
  finally
    echohl Normal
  endtry
endfunction

function! s:keyboard.show_prompt() "{{{1
  redraw
  call s:echohl(self.cursor, "Number")
  call s:echohl("> ", 'Function')
  call s:echohl(self._before(),  'SmallsCli')
  call s:echohl(self._after()[0],  'SmallsCliCursor')
  call s:echohl(self._after()[1:],  'SmallsCli')
endfunction

function! s:getchar() "{{{1
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfunction

function! Main() "{{{1
  call s:keyboard.init()
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
" vim: foldmethod=marker
