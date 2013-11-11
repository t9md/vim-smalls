let s:U = smalls#util#use([ "escape", 'plog' ])

let f = {}
let s:f = f
function! f.new(dir, env) "{{{1
  let self.env = a:env
  let self.dir = a:dir
  return self
endfunction

function! f.one(word) "{{{1
  return self.all(a:word, 1)
endfunction

function! f.all(word, ...) "{{{1
  let one = a:0
  let word = s:U.escape(a:word)
  let targets = []

  if empty(word)
    return targets
  endif
  "A

  let [opt, stopline, fname, ope] =
        \ self.dir ==# 'backward' ? [ 'b', self.env['w0'], 'foldclosed',    '-'] :
        \ self.dir ==# 'forward' ?  [ '' , self.env['w$'], 'foldclosedend', '+'] : 
        \ self.dir ==# 'all'     ?  [ 'c' , self.env['w$'], 'foldclosedend', '+'] : throw

  try
    if self.dir ==# 'all'
      call cursor(self.env['w0'], 1)
    endif
    while 1
      let pos = searchpos('\v'. prefix . word, opt, stopline)
      if pos == [0, 0] | break | endif

      let linum = function(fname)(pos[0])
      if linum != -1
        if linum ==# self.env['w$'] || linum ==# self.env['w0']
          " avoid infinit loop
          break
        endif
        call cursor(eval('linum' . ope . '1') , pos[1])
        continue
      endif
      call add(targets, pos)
      if one
        return pos
      endif
      if self.dir ==# 'all'
        call cursor(0, col('.') + 1)
        if col('.') == col('$') - 1
          if line('.') == self.env['w$']
            break
          else
            normal! +
          endif
        endif
      endif
    endwhile
  finally
    call self.env.p.set(1)
  endtry
  return targets
endfunction

function! smalls#finder#one(word) "{{{1
  return s:f.one(a:word)
endfunction

function! smalls#finder#all(word) "{{{1
  return s:f.all(a:word)
endfunction

function! smalls#finder#new(dir, env) "{{{1
  return s:f.new(a:dir, a:env)
endfunction
" vim: foldmethod=marker
