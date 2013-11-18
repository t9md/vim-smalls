let s:plog = smalls#util#import("plog")

let f = {} | let s:f = f
function! f.new(env) "{{{1
  let self.env = a:env
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
  try
    let firsttime = 1
    call cursor(0, col('.') + 1)
    while 1
      let word = '\V' . escape(a:word, '\')
      let pos = searchpos(word, 'c', self.env['w$'])
      if pos == [0, 0]
        if firsttime
          call cursor(self.env['w0'], 1)
          let firsttime = !firsttime
          continue
        endif
        break
      endif

      " skip fold
      let linum = foldclosedend(pos[0])
      if linum != -1
        if linum ==# self.env['w$']
          if ! firsttime
            break
          else
            call cursor(self.env['w0'], 1)
            let firsttime = !firsttime
            continue
          endif
        endif
        call cursor(linum + 1 , 1)
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
      if col('.') >= col('$') - 1
        let cl = line('.')
        if cl == self.env['w$']
          break
        endif
        call cursor(cl+1, 1)
      else
        call cursor(0, col('.') + 1)
      endif
    endwhile
  finally
    call self.env.p.set()
  endtry
  return targets
endfunction

function! smalls#finder#new(env) "{{{1
  return s:f.new(a:env)
endfunction
" vim: foldmethod=marker
