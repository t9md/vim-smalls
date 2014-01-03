" Cli:
" scriptencoding utf-8
let s:getchar = smalls#util#import("getchar")

let s:key_table = {
      \   "\<C-g>": "do_cancel",
      \   "\<Esc>": "do_cancel",
      \   "\<C-h>": "do_delete",
      \    "\<BS>": "do_delete",
      \   "\<C-a>": "do_head",
      \   "\<C-f>": "do_char_forward",
      \ "\<Right>": "do_char_forward",
      \   "\<C-b>": "do_char_backward",
      \  "\<Left>": "do_char_backward",
      \   "\<C-k>": "do_kill_to_end",
      \   "\<C-u>": "do_kill_line",
      \   "\<C-r>": "do_special",
      \   "\<C-e>": "do_excursion",
      \    "\<CR>": "do_excursion_with_set",
      \   "\<C-d>": "do_excursion_with_delete",
      \   "\<C-t>": "do_excursion_with_delete_till",
      \        "D": "do_excursion_with_delete_line",
      \   "\<C-y>": "do_excursion_with_yank",
      \        "Y": "do_excursion_with_yank_line",
      \        "V": "do_excursion_with_select_V",
      \   "\<C-v>": "do_excursion_with_select_CTRL_V",
      \   "\<Tab>": "do_excursion_with_next",
      \   "\<C-n>": "do_excursion_with_next",
      \ "\<S-Tab>": "do_excursion_with_prev",
      \   "\<C-p>": "do_excursion_with_prev",
      \   "\<C-c>": "do_excursion_with_change",
      \        "E": "do_auto_excursion_toggle",
      \    "\<F1>": "do_help",
      \ }

let s:help = {}
let s:help.en = {
      \ "do_cancel":                       'Cancel',
      \ "do_delete":                       'delete char before cursor',
      \ "do_head":                         'Set cursor to head',
      \ "do_char_forward":                 'Move cursor one char forward',
      \ "do_char_backward":                'Move cursor one char backward',
      \ "do_kill_to_end":                  'Delete chars after cursor',
      \ "do_kill_line":                    'Delete all chars you input',
      \ "do_special":                      'Special handling [experimental]',
      \ "do_excursion":                    'Begin [exc] mode',
      \ "do_excursion_with_set":           '[exc] do_set',
      \ "do_excursion_with_delete":        '[exc]do_delete',
      \ "do_excursion_with_delete_till":   '[exc] do_delete_till',
      \ "do_excursion_with_delete_line":   '[exc] do_delete_line',
      \ "do_excursion_with_yank":          '[exc] do_yank',
      \ "do_excursion_with_yank_line":     '[exc] do_yank_line',
      \ "do_excursion_with_select_V":      '[exc] do_select_V(line)',
      \ "do_excursion_with_select_CTRL_V": '[exc]do_select_CTRL_V(block)',
      \ "do_excursion_with_next":          '[exc] do_next',
      \ "do_excursion_with_prev":          '[exc] do_prev',
      \ "do_excursion_with_change":        '[exc] do_change',
      \ "do_auto_excursion_toggle":        'toggle auto_excursion',
      \ "do_jump":                         'Start jump',
      \ "do_help":                         'show this help',
      \ }
let s:help.ja = {
      \ "do_cancel":                       'キャンセル',
      \ "do_delete":                       'カーソルの前の文字を消す',
      \ "do_head":                         'カーソルを先頭に',
      \ "do_char_forward":                 'カーソルを1文字進める',
      \ "do_char_backward":                'カーソルを1文字戻す',
      \ "do_kill_to_end":                  'カーソルから行末までを削除',
      \ "do_kill_line":                    '全文字削除',
      \ "do_special":                      '特別な事をする [試作段階]',
      \ "do_excursion":                    '[exc] モードを開始',
      \ "do_auto_excursion_toggle":        'auto_excursion をトグル',
      \ "do_jump":                         'ジャンプを開始',
      \ "do_help":                         'このヘルプを表示',
      \ }

let s:keyboard = {}

function! s:keyboard.do_head() "{{{1
  let self.cursor = 0
endfunction

function! s:keyboard._timeout_second() "{{{1
  let conf = self.owner.conf
  return ( conf.auto_jump &&
        \ ( self.data_len() >= conf.auto_jump_min_input_length ))
        \ ? conf.auto_jump_timeout : -1
endfunction

function! s:keyboard.do_char_forward() "{{{1
  let self.cursor = min([self.cursor+1, self.data_len()])
endfunction

function! s:keyboard.do_char_backward() "{{{1
  let self.cursor = max([self.cursor-1, 0 ])
endfunction

function! s:keyboard.do_delete() "{{{1
  let after = self._after()
  call self.do_char_backward()
  let self.data = self._before() . after
endfunction

function! s:keyboard.do_kill_to_end() "{{{1
  let self._yanked = self._after()
  let self.data = self._before()
endfunction

function! s:keyboard.do_kill_line() "{{{1
  let self._yanked = self.data
  let self.data = ''
endfunction

function! s:keyboard.do_yank() "{{{1
  call self._set(self._yanked)
endfunction

function! s:keyboard.do_end() "{{{1
  let self.cursor = len(self.data)
endfunction

function! s:keyboard.do_special() "{{{1
  call self.msg("[S]", 'Statement')
  call self.show_prompt()
  let c = s:getchar()
  if c == "\<C-w>"
    call self.do_set_cword()
  endif
  redraw
endfunction

function! s:keyboard.do_set_cword() "{{{1
  call self._set(expand('<cword>'))
endfunction

function! s:keyboard.do_cancel() "{{{1
  throw 'CANCELED'
endfunction

function! s:keyboard.do_jump() "{{{1
  call call(self.owner.do_jump, [self.data], self.owner)
endfunction

function! s:keyboard.do_excursion() "{{{1
  call call(self.owner.do_excursion, [self], self.owner)
endfunction

function! s:keyboard.do_auto_excursion_toggle() "{{{1
  let self.owner.conf.auto_excursion = !self.owner.conf.auto_excursion
  let msg = printf("[auto_excurtion: %d] ", self.owner.conf.auto_excursion)
  call self.msg(msg, 'Statement')
endfunction

function! s:keyboard._action_missing(action) "{{{1
  let action = matchstr(a:action, '^do_excursion_with_\zs.*$')
  call call(self.owner.do_excursion, [self, action], self.owner)
endfunction

function! smalls#keyboard#cli#get_table() "{{{1
  return s:key_table
endfunction

function! smalls#keyboard#cli#extend_table(table) "{{{1
  call extend(s:key_table, a:table, 'force')
endfunction

function! smalls#keyboard#cli#replace_table(table) "{{{1
  let s:key_table = a:table
endfunction

function! smalls#keyboard#cli#new(owner) "{{{1
  let jump_trigger = get(g:, "smalls_jump_trigger", a:owner.conf.jump_keys[0])
  if ! has_key(s:key_table, jump_trigger)
    let s:key_table[jump_trigger] = 'do_jump'
  endif
  let keyboard = smalls#keyboard#base#new(a:owner,
        \ s:key_table, 'cli', "cli > ", s:help)
  return extend(keyboard, s:keyboard, 'force')
endfunction "}}}

" vim: foldmethod=marker
