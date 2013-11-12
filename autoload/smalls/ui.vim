let s:ensure  = smalls#util#import("ensure")
let s:getchar = smalls#util#import("getchar")
" let s:plog    = smalls#util#import("plog")

" UI:
let ui = {} | let s:ui = ui
function! ui.setlines(lines, key) "{{{1
  try
    " Try to join changes with previous undo block
    undojoin
  catch
  endtry

  " key is 'orig' or 'marker'
  for line_num in sort(keys(a:lines))
    call setline(line_num, a:lines[line_num][a:key])
  endfor
endfunction

function! ui.show_jumpscreen() "{{{1
  call self.setup_tareget_hl()
  call self.setlines(self.lines, 'marker')
  redraw
endfunction

function! ui.revert_screen() "{{{1
  call self.setlines(self.lines, 'orig')
  if has_key(self, "target_hl_id")
    call matchdelete(self.target_hl_id)
  endif
  redraw
endfunction

function! ui.prepare_display_lines(groups) "{{{1
  let lines = {}

  for pos in self.sorted_pos
    let target_key = self.pos2tgt[pos]
    let [line_num, col_num] = split(pos, ',')
    let line_num = str2nr(line_num)
    let col_num  = str2nr(col_num)

    if ! has_key(lines, line_num)
      let current_line = getline(line_num)
      let lines[line_num] = { 'orig': current_line, 'marker': current_line, 'mb_compensation': 0 }
    endif
    let target_char_len = strlen(matchstr(lines[line_num]['marker'], '\%' . col_num . 'c.'))
    let target_key_len = strlen(target_key)

    let col_num -= lines[line_num]['mb_compensation']
    if strlen(lines[line_num]['marker']) > 0
      let lines[line_num]['marker'] = substitute(lines[line_num]['marker'], '\%' . col_num . 'c.', target_key, '')
    else
      let lines[line_num]['marker'] = target_key
    endif
    let lines[line_num]['mb_compensation'] += (target_char_len - target_key_len)
  endfor
  return lines
endfunction

function! ui.setup_tareget_hl() "{{{1
  let hl_expr =  join(map(map(self.sorted_pos, 'split(v:val, ",")'), 
        \ "'\\%' . v:val[0] . 'l\\%' . v:val[1] . 'c'"), '\|')
  let self.target_hl_id = matchadd("SmallsJumpTarget", hl_expr , 200)
endfunction

function! ui.gen_pos2tgt(tgt2pos, ...) "{{{1
  " From       ->  To
  " tgt : pos      pos         : tgt    
  "  a: [1,2] -->  00001,00002 : a      
  "  b: [2,3]      00002,00003 : b      
  let result = {}
  let tgt_nested = a:0 == 1 ? a:1 : ''

  " tgt, pos => ex) a: [1, 2]
  for [tgt, pos] in items(a:tgt2pos)
    let tgt = !empty(tgt_nested) ? tgt_nested : tgt
    if type(pos) == type([])
      let result[printf('%05d,%05d', pos[0], pos[1])] = tgt
    elseif type(pos) == type({})
      call extend(result, self.gen_pos2tgt(pos, tgt))
    else
      throw "NEVER HAPPEN"
    endif
    unlet pos
  endfor
  return result
endfunction

function! ui.start(tgt2pos) "{{{1
  let poss = values(a:tgt2pos)
  if len(poss) == 1
    redraw
    return smalls#pos#new(poss[0])
  endif
  let self.pos2tgt = self.gen_pos2tgt(a:tgt2pos)
  let self.sorted_pos = sort(keys(self.pos2tgt))
  let self.lines = self.prepare_display_lines(a:tgt2pos)

  try
    call self.show_jumpscreen()
    " " return
    let tgt = s:getchar()
    call s:ensure(!empty(tgt), "Cancelled")
    " if c == "\<Esc>"
      " throw "CANCELLED"
    " endif
    let up_tgt = toupper(tgt)
    call s:ensure(has_key(a:tgt2pos, up_tgt), "Invalid target" )
  finally
    call self.revert_screen()
  endtry

  let pos = a:tgt2pos[up_tgt]
  return type(pos) == type([])
        \ ? smalls#pos#new(pos)
        \ : self.start(pos)
endfunction

function! smalls#ui#start(tgt2pos) "{{{1
  return  s:ui.start(a:tgt2pos)
endfunction

" vim: foldmethod=marker
