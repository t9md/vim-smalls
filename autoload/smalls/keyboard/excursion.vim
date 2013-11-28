let s:getchar = smalls#util#import("getchar")
let s:plog    = smalls#util#import("plog")
" if !exists('g:loaded_smalls')
  " runtime plugin/smalls.vim
" endif

let s:key_table = {
      \   "\<C-c>": "do_cancel",
      \   "\<C-e>": "do_back_cli",
      \   "\<Esc>": "do_back_cli",
      \        "n": "do_next",
      \   "\<Tab>": "do_next",
      \        "p": "do_prev",
      \ "\<S-Tab>": "do_prev",
      \        "k": "do_up",
      \        "j": "do_down",
      \        "h": "do_left",
      \        "l": "do_right",
      \        "d": "do_delete",
      \   "\<C-d>": "do_delete",
      \        "y": "do_yank",
      \   "\<C-y>": "do_yank",
      \        "v": "do_select_v",
      \        "V": "do_select_V",
      \   "\<C-v>": "do_select_CTRL_V",
      \        ";": "do_set",
      \    "\<CR>": "do_set",
      \ }
      " \    "\<F9>": "do_debug",

let s:keyboard = {}

function! s:keyboard.init(word, poslist) "{{{1
  let self.index   = 0
  let self.word    = a:word
  let self.poslist = a:poslist
  let self.max     = len(a:poslist)
  return self
endfunction

function! s:keyboard.do_cancel() "{{{1
  let self.owner._break = 1
endfunction

function! s:keyboard.do_back_cli() "{{{1
  throw 'BACK_CLI'
endfunction

function! s:keyboard.line() "{{{1
  return self.poslist[self.index][0]
endfunction

function! s:keyboard.col() "{{{1
  return self.poslist[self.index][1]
endfunction

function! s:keyboard.pos() "{{{1
  return self.poslist[self.index]
endfunction

function! s:keyboard.do_up() "{{{1
  call self.do_ud('prev')
endfunction

function! s:keyboard.do_down() "{{{1
  call self.do_ud('next')
endfunction

function! s:keyboard.do_ud(dir) "{{{1
  let fn = 'do_' . a:dir
  let [cl, cc] = self.pos()
  call self[fn]()
  while cl == self.line() && cc != self.col()
    call self[fn]()
  endwhile
endfunction

function! s:keyboard.do_right() "{{{1
  call self.do_lr('next')
endfunction

function! s:keyboard.do_left() "{{{1
  call self.do_lr('prev')
endfunction

function! s:keyboard.do_lr(dir) "{{{1
  let fn = 'do_' . a:dir
  let cl = self.line()
  call self[fn]()
  while cl != self.line()
    call self[fn]()
  endwhile
endfunction

function! s:keyboard.do_next() "{{{1
  let self.index = (self.index + 1) % self.max
endfunction

function! s:keyboard.do_prev() "{{{1
  let self.index = ((self.index - 1) + self.max ) % self.max
endfunction

function! s:keyboard.do_set() "{{{1
  let pos_new = smalls#pos#new(self.pos())
  call self.owner._jump_to_pos(pos_new)
  let self.owner._break = 1
endfunction

function! s:keyboard.do_delete() "{{{1
  if !self.owner._is_visual()
    call self.do_select_v()
  endif
  call self.do_set()
  normal! d
endfunction

function! s:keyboard.do_yank() "{{{1
  if !self.owner._is_visual()
    call self.do_select_v()
  endif
  call self.do_set()
  normal! y
endfunction

function! s:keyboard.do_direct() "{{{1
  exe 'normal! ' . self.last_input
  let pos_new = smalls#pos#new(self.pos())
  call self.owner._set_to_pos(pos_new)
  " let self.owner._break = 1
endfunction

function! s:keyboard.do_select_v() "{{{1
  call self._do_select('v')
endfunction

function! s:keyboard.do_select_V() "{{{1
  call self._do_select('V')
endfunction

function! s:keyboard.do_select_CTRL_V() "{{{1
  call self._do_select("\<C-v>")
endfunction

function! s:keyboard._do_select(key) "{{{1
  " only emulate select, so set to env.mode
  let self.owner.env.mode = a:key
endfunction

function! s:keyboard._do_normal(key) "{{{1
  let pos_new = smalls#pos#new(self.pos())
  execute 'normal! ' . a:key
  call self.owner._jump_to_pos(pos_new)
endfunction

function! s:keyboard.do_debug() "{{{1
  " call s:plog( self.owner.env.mode )
endfunction

function! smalls#keyboard#excursion#get_table() "{{{1
  return s:key_table
endfunction "}}}
function! smalls#keyboard#excursion#extend_table(table) "{{{1
  call extend(s:key_table, a:table, 'force')
endfunction "}}}
function! smalls#keyboard#excursion#replace_table(table) "{{{1
  let s:key_table = a:new_table
endfunction "}}}
function! smalls#keyboard#excursion#new(owner, word, poslist) "{{{1
  let help = "[Excursion]"
  let keyboard = smalls#keyboard#base#new(a:owner, s:key_table, help)
  call extend(keyboard, s:keyboard, 'force')
  return keyboard.init(a:word, a:poslist)
endfunction "}}}

" vim: foldmethod=marker
