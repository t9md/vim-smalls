let s:getchar = smalls#util#import("getchar")
let s:plog    = smalls#util#import("plog")

let s:excursion_table = {
      \ "\<C-c>": "do_cancel",
      \ "\<Esc>": "do_cancel",
      \ }

let keyboard = {}
let s:keyboard = keyboard

function! s:keyboard.do_cancel()
  throw 'Canceled'
endfunction

function! s:keyboard.do_down()
  throw 'Canceled'
endfunction
function! s:keyboard.do_up()
  throw 'Canceled'
endfunction
function! s:keyboard.do_right()
  throw 'Canceled'
endfunction
function! s:keyboard.do_left()
  throw 'Canceled'
endfunction
function! s:keyboard.do_next()
  throw 'Canceled'
endfunction
function! s:keyboard.do_prev()
  throw 'Canceled'
endfunction
function! s:keyboard.do_jump()
  throw 'Canceled'
endfunction

function! s:smalls.do_excursion(kbd) "{{{1
  " very exprimental feature and won't document
  let word = a:kbd.data
  if empty(word) | return [] | endif
  let poslist  = self.finder.all(word)
  let max = len(poslist)
  let index = 0
  let [key_l, key_r, key_u, key_d, key_n, key_p ] = self.dir ==# 'bwd'
        \ ? [ 'l', 'h', 'j', 'k', 'p', 'n' ]
        \ : [ 'h', 'l', 'k', 'j', 'n', 'p' ]
  while 1
    let c = s:getchar()
    if     c == key_n | let index = (index +  1) % max
    elseif c == key_p | let index = ((index - 1) + max ) % max
    elseif c == "\<Tab>" | let index = (index +  1) % max
    elseif c == "\<S-Tab>" | let index = ((index - 1) + max ) % max
    elseif c =~ 'j\|k'
      let cl = poslist[index][0]
      while 1
        let index = c ==# key_d ? (index + 1) % max : ((index - 1) + max ) % max
        let nl = poslist[index][0]
        if cl != nl
          break
        endif
      endwhile
    elseif c =~ 'h\|l'
      let [cl, cc] = poslist[index]
      while 1
        let index = c ==# key_r ? (index + 1) % max : ((index - 1) + max ) % max
        let [nl, nc] = poslist[index]
        if cl == nl
          break
        endif
      endwhile
    elseif c == ';'
      let pos_new = smalls#pos#new(poslist[index])
      call self.adjust_col(pos_new)
      call pos_new.jump(self._is_visual())
      break
    endif
    call self.hl.clear('SmallsCurrent', 'SmallsCursor', 'SmallsCandidate')
    call self.hl.candidate(word, poslist[index])
    redraw
  endwhile
  let self._break = 1
endfunction

function! smalls#keyboard#excursion#new(owner) "{{{1
  let keyboard = smalls#keyboard#base#new(a:owner, s:cli_table, "[E]> ")
  return extend(keyboard, s:keyboard, 'force')
endfunction "}}}
