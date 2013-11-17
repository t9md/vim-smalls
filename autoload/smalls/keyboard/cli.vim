let s:getchar = smalls#util#import("getchar")
let s:plog    = smalls#util#import("plog")

let s:key_table = {
      \ "\<C-c>":   "do_cancel",
      \ "\<Esc>":   "do_cancel",
      \ "\<CR>":    "do_jump_first",
      \ "\<C-h>":   "do_delete",
      \ "\<BS>":    "do_delete",
      \ "\<C-a>":   "do_head",
      \ "\<C-e>":   "do_end",
      \ "\<C-f>":   "do_char_forward",
      \ "\<C-b>":   "do_char_backward",
      \ "\<C-k>":   "do_kill",
      \ "\<C-y>":   "do_yank",
      \ "\<C-r>":   "do_special",
      \ "\<Tab>":   "do_excursion_with_next",
      \ "\<C-n>":   "do_excursion_with_next",
      \ "\<S-Tab>": "do_excursion_with_prev",
      \ "\<C-p>":   "do_excursion_with_prev",
      \ }

let jump_trigger = get(g:, "smalls_jump_trigger", g:smalls_jump_keys[0])
let s:key_table[jump_trigger] = 'do_jump'

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
  call self.echohl("[S]", 'Statement')
  call self.show_prompt()
  let c = s:getchar()
  if c == "\<C-w>"
    call self.do_set_cword()
  endif
  redraw
endfunction

function! keyboard.do_set_cword() "{{{1
  call self._set(expand('<cword>'))
endfunction

function! keyboard.do_cancel() "{{{1
  throw 'Canceled'
endfunction

function! keyboard.do_jump() "{{{1
  call call(self.owner.do_jump, [self], self.owner)
endfunction

function! keyboard.do_jump_wordend() "{{{1
  call call(self.owner.do_jump, [self, 1], self.owner)
endfunction

function! keyboard.do_jump_first() "{{{1
  call call(self.owner.do_jump_first, [self], self.owner)
endfunction

function! keyboard.do_excursion() "{{{1
  call call(self.owner.do_excursion, [self], self.owner)
endfunction

function! keyboard.do_excursion_with_next() "{{{1
  call call(self.owner.do_excursion, [self, 'next'], self.owner)
endfunction

function! keyboard.do_excursion_with_prev() "{{{1
  call call(self.owner.do_excursion, [self, 'prev'], self.owner)
endfunction

function! keyboard.do_candidate_next() "{{{1
  call call(self.owner.do_candidate_next, [self], self.owner)
endfunction


function! smalls#keyboard#cli#get_table() "{{{1
  return s:key_table
endfunction "}}}
function! smalls#keyboard#cli#extend_table(table) "{{{1
  call extend(s:key_table, a:table, 'force')
endfunction "}}}
function! smalls#keyboard#cli#replace_table(table) "{{{1
  let s:key_table = a:new_table
endfunction "}}}
function! smalls#keyboard#cli#new(owner) "{{{1
  let keyboard = smalls#keyboard#base#new(a:owner, s:key_table, "> ")
  return extend(keyboard, s:keyboard, 'force')
endfunction "}}}
" vim: foldmethod=marker
