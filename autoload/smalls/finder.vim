let s:plog = smalls#util#import("plog")

let f = {} | let s:f = f
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
  let targets = []
  if empty(a:word)
    return targets
  endif
  let [opt, stopline, fname, ope] =
        \ self.dir ==# 'bwd' ? [ 'b', self.env['w0'], 'foldclosed',    '-'] :
        \ self.dir ==# 'fwd' ? [ '' , self.env['w$'], 'foldclosedend', '+'] : 
        \ self.dir ==# 'all' ? [ 'c', self.env['w$'], 'foldclosedend', '+'] : throw
  try
    if self.dir ==# 'all'
      let firsttime = 1
      call cursor(0, col('.') + 1)
    endif
    while 1
      let word = '\V' . escape(a:word, '\')
      let pos = searchpos(word, opt, stopline)
      if pos == [0, 0]
        if self.dir ==# 'all'
          if firsttime
            call cursor(self.env['w0'], 1)
            let firsttime = !firsttime
            continue
          endif
        endif
        break
      endif

      " skip fold
      let linum = function(fname)(pos[0])
      if linum != -1
        if linum ==# self.env['w$'] || linum ==# self.env['w0']
          " avoid infinit loop
          break
        endif
        call cursor(eval('linum' . ope . '1') , 1)
        continue
      endif
      if one
        return pos
      endif

      if index(targets, pos) == -1
        call add(targets, pos)
      else
        break
      endif

      " FIXME need cleanup?
      if self.dir ==# 'all'
        if col('.') >= col('$') - 1
          if line('.') == self.env['w$']
            break
          endif
          normal! +
        endif
        call cursor(0, col('.') + 1)
      endif
    endwhile
  finally
    call self.env.p.set()
  endtry
  return targets
endfunction

function! smalls#finder#new(dir, env) "{{{1
  return s:f.new(a:dir, a:env)
endfunction
" vim: foldmethod=marker
