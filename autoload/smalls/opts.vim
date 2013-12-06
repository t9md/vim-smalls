let s:opts = {}

function! s:opts.new() "{{{1
  let self._opts = { 'global': {}, 'buffer': {}, 'window': {},}
  return self
endfunction

function! s:opts.prepare(opts, wins) "{{{1
  let self._request_opts = a:opts

  for winnr in a:wins
    let self._opts.window[winnr] = {}
    " let bufnr = bufname(winbufnr(winnr))
    let bufnr = winbufnr(winnr)
    if !has_key(self._opts.buffer, bufnr)
      let self._opts.buffer[bufnr] = {}
    endif
  endfor
  return self
endfunction

function! s:opts.save() "{{{1
  let req = self._request_opts

  let self._opts.global = self._get('global', req.global, bufnr(''))

  for bufnr in keys(self._opts.buffer)
    let bufnr = str2nr(bufnr)
    let self._opts.buffer[bufnr] = self._get('buffer', req.buffer, bufnr)
  endfor

  for winnr in keys(self._opts.window)
    let self._opts.window[winnr] = self._get('window', req.window, winnr)
  endfor
  return self
endfunction

function! s:opts.change() "{{{1
  call self._change_or_restore('change')
  return self
endfunction

function! s:opts.restore() "{{{1
  call self._change_or_restore('restore')
  return self
endfunction

function! s:opts._change_or_restore(req) "{{{1
  let req =
        \ a:req == 'change' ? self._request_opts : self._opts

  call self._set('global', req.global, bufname(''))

  for bufnr in keys(self._opts.buffer)
    let bufnr = str2nr(bufnr)
    let bufopts = a:req == 'change' ? req.buffer : req.buffer[bufnr]
    call self._set('buffer', bufopts, bufnr)
  endfor

  for winnr in keys(self._opts.window)
    let winopts = a:req == 'change' ? req.window : req.window[winnr]
    call self._set('window', winopts, winnr)
  endfor
endfunction

function! s:opts._get(scope, vars, where) "{{{1
  return self._get_or_set('get', a:scope, a:vars, a:where)
endfunction

function! s:opts._set(scope, vars, where) "{{{1
  call self._get_or_set('set', a:scope, a:vars, a:where)
endfunction

function! s:opts._get_or_set(ope, scope, vars, where) "{{{1
  " ope must be 'get' or 'set'
  let func = a:ope . (a:scope ==# 'window' ? 'winvar' : 'bufvar')
  let v = {}
  for [var, val] in items(a:vars)
    let args = a:ope ==# 'get' ? [ a:where, var ] : [ a:where, var, val ] 
    let v[var] = call(func, args)
    unlet var val
  endfor
  return v
endfunction

function! smalls#opts#new() "{{{1
  return s:opts.new()
endfunction
"}}}

finish
" Sample {{{1
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
