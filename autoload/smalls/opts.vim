let s:opts = {}

function! s:opts.new() "{{{1
  let self._opts = { 'global': {}, 'buffer': {}, 'window': {},}
  return self
endfunction

function! s:opts.prepare(opts, wins) "{{{1
  let self._request_opts = a:opts
  let self._request_wins = a:wins

  for winnr in a:wins
    let self._opts.window[winnr] = {}
    let bufnr = bufname(winbufnr(winnr))
    " let bufnr = winbufnr(winnr)
    if !has_key(self._opts.buffer, bufnr) | let self._opts.buffer[bufnr] = {} | endif
  endfor
endfunction

function! s:opts.save() "{{{1
  let req = self._request_opts

  let self._opts.global = self._save('global', req.global, bufname(''))

  for bufname in keys(self._opts.buffer)
    let self._opts.buffer[bufname] = self._save('buffer', req.buffer, bufname)
  endfor

  for winnr in keys(self._opts.window)
    let self._opts.window[winnr] = self._save('window', req.window, winnr)
  endfor
endfunction

function! s:opts.change() "{{{1
  call self._change_or_restore('change')
endfunction

function! s:opts.restore() "{{{1
  call self._change_or_restore('restore')
endfunction

function! s:opts._change_or_restore(req) "{{{1
  let req =
        \ a:req == 'change' ? self._request_opts : self._opts

  call self._change('global', req.global, bufname(''))

  for bufnr in keys(self._opts.buffer)
    let bufopts = a:req == 'change' ? req.buffer : req.buffer[bufnr]
    call self._change('buffer', bufopts, bufnr)
  endfor

  for winnr in keys(self._opts.window)
    let winopts = a:req == 'change' ? req.window : req.window[winnr]
    call self._change('window', winopts, winnr)
  endfor
endfunction

function! s:opts._save(scope, vars, where) "{{{1
  let v = {}
  for [var, val] in items(a:vars)
    if a:scope !=# 'window'
      let v[var] = getbufvar(a:where, var)
    else
      let v[var] = getwinvar(a:where, var)
    endif
    unlet var val
  endfor
  return v
endfunction

function! s:opts._change(scope, vars, where) "{{{1
  for [var, val] in items(a:vars)
    if a:scope !=# 'window'
      call setbufvar(a:where, var, val)
    else
      call setwinvar(a:where, var, val)
    endif
    unlet var val
  endfor
endfunction

function! smalls#opts#new() "{{{1
  return s:opts.new()
endfunction

finish
let opts = smalls#opts#new()
let global =  {
      \ '&scrolloff':  0 }
let buffer    = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0, }
let window    = {
      \ '&cursorline': 0,
      \ '&spell':      0, }

let wins = range(1, winnr('$'))
echo wins
call opts.prepare({'global': global, 'buffer': buffer, 'window': window }, wins)
call opts.save()
echo 'before --------------------'
PP opts._opts
call opts.change()
call opts.restore()
echo 'after --------------------'
PP opts._opts
" call opts.restore()
" vim: foldmethod=marker
