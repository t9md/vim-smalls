" Excurstion:
scriptencoding utf-8
let s:getchar   = smalls#util#import("getchar")
let s:is_visual = smalls#util#import('is_visual')

let s:key_table = {
      \   "\<C-g>": "do_cancel",
      \   "\<C-e>": "do_back_cli",
      \   "\<Esc>": "do_back_cli",
      \    "\<CR>": "do_jump",
      \        ";": "do_set",
      \        "n": "do_next",
      \   "\<Tab>": "do_next",
      \        "p": "do_prev",
      \ "\<S-Tab>": "do_prev",
      \       "gg": "do_first",
      \        "G": "do_last",
      \        "0": "do_line_head",
      \        "^": "do_line_head",
      \        "$": "do_line_tail",
      \        "k": "do_up",
      \        "j": "do_down",
      \        "h": "do_left",
      \        "l": "do_right",
      \   "\<C-d>": "do_delete",
      \        "d": "do_delete",
      \   "\<C-t>": "do_delete_till",
      \        "t": "do_delete_till",
      \        "D": "do_delete_line",
      \        "c": "do_change",
      \   "\<C-c>": "do_change",
      \   "\<C-y>": "do_yank",
      \        "y": "do_yank",
      \        "Y": "do_yank_line",
      \        "v": "do_select_v",
      \        "V": "do_select_V",
      \   "\<C-v>": "do_select_CTRL_V",
      \    "\<F1>": "do_help",
      \        "?": "do_help",
      \ }
      " \        "v": "do_select_v_with_set",
      " \        "V": "do_select_V_with_set",
      " \   "\<C-v>": "do_select_CTRL_V_with_set",

let s:help = {}
let s:help.en = {
      \ "do_cancel": 'Cancel',
      \ "do_back_cli": 'Back to CLI mode',
      \ "do_jump": 'Start jump',
      \ "do_set":  'Set cursor on current candidate and exit',
      \ "do_next": 'next candidate',
      \ "do_prev": 'prev candidate',
      \ "do_first": 'move to first candidate',
      \ "do_last":  'mode to last candidate',
      \ "do_line_head": 'move to first candidate of this line',
      \ "do_line_tail": 'move to last candidate of this line', 
      \ "do_up": 'move to cnadidate of one line up',
      \ "do_down": 'move to cnadidate of one line down',
      \ "do_left": 'move to left candidate',
      \ "do_right": 'move to right candidate',
      \ "do_delete": 'delete area from original pos to target pos',
      \ "do_delete_till": 'delete area from original pos to BEFORE tareget pos',
      \ "do_delete_line": 'delete linewise',
      \ "do_change": 'delete and start insert',
      \ "do_yank": 'yank area',
      \ "do_yank_line": 'yank linewise',
      \ "do_select_v": 'select area with char-wise (v)',
      \ "do_select_V": 'select area with line-wise (V)', 
      \ "do_select_CTRL_V": 'select area with block-wise (C-v)', 
      \ "do_help": 'show this help',
      \ "do_select_v_with_set": 'select with v and exit',
      \ "do_select_V_with_set": 'select with V and exit',
      \ "do_select_CTRL_V_with_set": 'select with C-v and exit',
      \ }
let s:help.ja = {
      \ "do_cancel": 'キャンセル',
      \ "do_back_cli": 'CLI モードに戻る',
      \ "do_jump": 'ジャンプを開始',
      \ "do_set":  '現在候補にカーソルをセット',
      \ "do_next": '次の候補へ',
      \ "do_prev": '前の候補へ',
      \ "do_first": '最初の候補へ',
      \ "do_last":  '最後の候補へ',
      \ "do_line_head": '現在行の最初の候補へ',
      \ "do_line_tail": '現在行の最後の候補へ', 
      \ "do_up": '1行上の候補へ',
      \ "do_down": '1行下の候補へ',
      \ "do_left": '現在行の左の候補へ',
      \ "do_right": '現在行の右の候補へ',
      \ "do_delete": '元位置からターゲットまでの範囲を削除',
      \ "do_delete_till": '元位置からターゲットの手前までの範囲を削除',
      \ "do_delete_line": '行を削除(linewise)',
      \ "do_change": '削除して、インサート開始',
      \ "do_yank": '範囲をヤンク',
      \ "do_yank_line": '行をヤンク(linewise)',
      \ "do_select_v": '文字を選択 (v)',
      \ "do_select_V": '行を選択 (V)', 
      \ "do_select_CTRL_V": 'ブロックを選択 (C-v)', 
      \ "do_help": 'ヘルプを表示',
      \ "do_select_v_with_set": '選択(v) して終了',
      \ "do_select_V_with_set": '選択(V) して終了',
      \ "do_select_CTRL_V_with_set": '選択(C-v) して終了',
      \ }

let s:keyboard = {}

function! s:keyboard.init(word, poslist) "{{{1
  let self.index       = 0
  let self._count      = ''
  let self.data        = self.owner.keyboard_cli.data
  let self.cursor      = len(self.data)
  let self._sorted     = []
  let self.word        = a:word
  let self.poslist     = a:poslist
  let self.poslist_max = len(a:poslist)
  return self
endfunction

function! s:keyboard._is_normal_key(c)
  return !has_key(self._table, a:c) || a:c == '0' && !empty(self._count)
endfunction

function! s:keyboard.do_jump() "{{{1
  call self.owner.keyboard_cli.call_action('do_jump')
endfunction

function! s:keyboard.do_cancel() "{{{1
  throw 'CANCELED'
endfunction

function! s:keyboard.do_back_cli() "{{{1
  throw 'BACK_CLI'
endfunction

function! s:keyboard.line() "{{{1
  return self.pos()[0]
endfunction

function! s:keyboard.col() "{{{1
  return self.pos()[1]
endfunction

function! s:keyboard.pos() "{{{1
  return self.poslist[self.index]
endfunction

function! s:keyboard.do_up() "{{{1
  call self._do_ud('prev')
endfunction

function! s:keyboard.do_down() "{{{1
  call self._do_ud('next')
endfunction

function! s:keyboard.do_last() "{{{1
  let self.index = index(self.poslist, self.sorted()[-1])
endfunction

function! s:keyboard.do_first() "{{{1
  let self.index = index(self.poslist, self.sorted()[0])
endfunction

function! s:keyboard.sorted()
  if empty(self._sorted) " cache
    let self._sorted = sort(copy(self.poslist), self._sortfunc, self)
  endif
  return self._sorted
endfunction

function! s:keyboard._sortfunc(pos1, pos2)
  let r = a:pos1[0] - a:pos2[0]
  return ( r ==# 0 ) ? a:pos1[1] - a:pos2[1] : r
endfunction

function! s:keyboard.do_right() "{{{1
    call self._do_lr('next')
endfunction

function! s:keyboard.do_left() "{{{1
    call self._do_lr('prev')
endfunction

function! s:keyboard.do_line_head() "{{{1
  call self._do_head_tail('head')
endfunction

function! s:keyboard.do_line_tail() "{{{1
  call self._do_head_tail('tail')
endfunction

function! s:keyboard._do_head_tail(which) "{{{1
  let l = self.line()
  let [search, adjust]
        \ = a:which ==# 'tail' ? ['next', 'prev'] : ['prev', 'next' ]
  call self['do_' . search](1)
  while l == self.line()
    call self['do_' . search](1)
  endwhile
  call self['do_' . adjust](1)
endfunction

function! s:keyboard._do_ud(dir) "{{{1
  let fn = 'do_' . a:dir

  for n in range(self.count())
    let [l, c] = self.pos()
    call self[fn](1)
    while l == self.line() && c != self.col()
      call self[fn](1)
    endwhile
  endfor
  call self.count_reset()
endfunction

function! s:keyboard._do_lr(dir) "{{{1
  let fn = 'do_' . a:dir

  for n in range(self.count())
    let l = self.line()
    call self[fn](1)
    while l != self.line()
      call self[fn](1)
    endwhile
  endfor
  call self.count_reset()
endfunction

function! s:keyboard.do_next(...) "{{{1
  let ignore_count = a:0 ? 1 : 0
  for n in range(self.count())
    let self.index = (self.index + 1) % self.poslist_max
    if ignore_count
      return
    endif
  endfor
  call self.count_reset()
endfunction

function! s:keyboard.do_prev(...) "{{{1
  let ignore_count = a:0 ? 1 : 0
  for n in range(self.count())
    let self.index = ((self.index - 1) + self.poslist_max ) % self.poslist_max
    if ignore_count
      return
    endif
  endfor
  call self.count_reset()
endfunction

function! s:keyboard.do_set() "{{{1
  call smalls#pos#new(self.owner, self.pos()).jump()
  throw 'SUCCESS'
endfunction

function! s:keyboard.count() "{{{1
  return empty(self._count) ? 1 : str2nr(self._count)
endfunction

function! s:keyboard.count_reset() "{{{1
  let self._count = ''
endfunction

function! s:keyboard._setchar(c) "{{{1
  if empty(self._count) && a:c ==# '0'
    return ''
  endif

  if a:c !~ '\d'
    call self.count_reset()

    " support upto 2char keymap
    let last_2_char = join(self.input_history[-2:], '')
    if has_key(self._table, last_2_char)
      call self.execute(last_2_char)
    endif

    let lastchar_cli = self.owner.keyboard_cli.data[-1:]
    if lastchar_cli ==# a:c "same char entered to excursion mode
      call self.do_next()
    elseif lastchar_cli ==# tolower(a:c) " upper char for backward movement
      call self.do_prev()
    endif
  else
    let self._count .= a:c
  endif
  return ''
endfunction

function! s:keyboard._action_missing(action) "{{{1
  let [ first_action, next_action ] = split(a:action, '_with_')
  call self[first_action]()
  call self['do_' . next_action ]()
endfunction

function! s:keyboard.do_select_v(...) "{{{1
  call self._do_select('v')
endfunction

function! s:keyboard.do_select_V(...) "{{{1
  call self._do_select('V')
endfunction

function! s:keyboard.do_select_CTRL_V(...) "{{{1
  call self._do_select("\<C-v>")
endfunction

function! s:keyboard.do_delete() "{{{1
  call self._do_normal('d', 'v')
endfunction

function! s:keyboard.do_delete_till() "{{{1
  let self.owner.conf.adjust = 'till'
  call self._do_normal('d', 'v')
endfunction

function! s:keyboard.do_delete_line() "{{{1
  call self._do_normal('d', 'V', 1)
endfunction

function! s:keyboard.do_yank() "{{{1
  call self._do_normal('y', 'v')
endfunction

function! s:keyboard.do_yank_line() "{{{1
  call self._do_normal('y', 'V', 1)
endfunction

function! s:keyboard.do_change() "{{{1
  " FIXME need robust change to support 'c' precisely
  " need <expr> map, but <expr> don't allow buffer change within expression
  " ,means need to give-up easy motion style jump.
  call self._do_normal('c', 'v')
endfunction

function! s:keyboard._do_normal(key, wise, ...)
  let force_wise = !empty(a:000)

  if force_wise || ! s:is_visual(self.owner.mode())
    call self._do_select(a:wise, force_wise)
  endif
  let self.owner.operation = {
        \ 'normal':      a:key ==# 'c' ? 'd' : a:key,
        \ 'startinsert': a:key ==# 'c',
        \ }
  call self.do_set()
endfunction

function! s:keyboard._do_select(key, ...) "{{{1
  " only emulate select, so set to env.mode
  " highlighter will refresh screen based on env.mode
  let force_wise = !empty(a:000) && a:1
  if force_wise
    let self.owner.env.mode = a:key
  else
  let self.owner.env.mode =
        \ self.owner.env.mode ==# a:key 
        \  ? self.owner.env.mode_org
        \  : a:key
  endif
endfunction

function! smalls#keyboard#excursion#get_table() "{{{1
  return s:key_table
endfunction

function! smalls#keyboard#excursion#extend_table(table) "{{{1
  call extend(s:key_table, a:table, 'force')
endfunction

function! smalls#keyboard#excursion#replace_table(table) "{{{1
  let s:key_table = a:table
endfunction

function! smalls#keyboard#excursion#new(owner, word, poslist) "{{{1
  let keyboard = smalls#keyboard#base#new(a:owner, 
        \ s:key_table, 'EXC', s:help)
  call extend(keyboard, s:keyboard, 'force')
  return keyboard.init(a:word, a:poslist)
endfunction "}}}

" vim: foldmethod=marker
