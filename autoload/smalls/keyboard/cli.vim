let s:getchar = smalls#util#import("getchar")
let s:cli_table = {
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
      \ "\<Esc>": "do_cancel",
      \ }

let keyboard = {}
let s:keyboard = keyboard
function! keyboard.do_head() "{{{1
  let self.cursor = 0
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
  call self.echohl("[S]", 'Statement')
  call self.show_prompt()
  let c = s:getchar()
  if c == "\<C-w>"
    call self.do_set_cword()
  endif
endfunction

function! keyboard.do_set_cword() "{{{1
  call self._set(expand('<cword>'))
endfunction

function! keyboard.do_cancel() "{{{1
  throw 'Canceled'
endfunction

function! keyboard.do_enter() "{{{1
  throw 'ENTER'
endfunction

function! smalls#keyboard#cli#new(owner) "{{{1
  let keyboard = smalls#keyboard#base#new(a:owner, s:cli_table, "> ")
  return extend(deepcopy(keyboard), s:keyboard, 'force')
endfunction "}}}
" vim: foldmethod=marker
