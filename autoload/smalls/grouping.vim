let s:libname = expand("<sfile>:t:r")
function! smalls#grouping#SCTree(targets, keys)  "{{{1
  " Single-key/closest target priority tree
  " This algorithm tries to assign one-key jumps to all the targets closest to the cursor.
  " It works recursively and will work correctly with as few keys as two.
  " Prepare variables for working
  let targets_len = len(a:targets)
  let keys_len = len(a:keys)

  let groups = {}

  let keys = reverse(copy(a:keys))

  " Semi-recursively count targets {{{
  " We need to know exactly how many child nodes (targets) this branch will have
  " in order to pass the correct amount of targets to the recursive function.

  " Prepare sorted target count list {{{
  " This is horrible, I know. But dicts aren't sorted in vim, so we need to
  " work around that. That is done by having one sorted list with key counts,
  " and a dict which connects the key with the keys_count list.

  let keys_count = []
  let keys_count_keys = {}

  let i = 0
  for key in keys
    call add(keys_count, 0)

    let keys_count_keys[key] = i

    let i += 1
  endfor
  " }}}

  let targets_left = targets_len
  let level = 0
  let i = 0

  while targets_left > 0
    " Calculate the amount of child nodes based on the current level
    let childs_len = (level == 0 ? 1 : (keys_len - 1) )

    for key in keys
      " Add child node count to the keys_count array
      let keys_count[keys_count_keys[key]] += childs_len

      " Subtract the child node count
      let targets_left -= childs_len

      if targets_left <= 0
        " Subtract the targets left if we added too many too
        " many child nodes to the key count
        let keys_count[keys_count_keys[key]] += targets_left

        break
      endif

      let i += 1
    endfor

    let level += 1
  endwhile
  " }}}
  " Create group tree {{{
  let i = 0
  let key = 0

  call reverse(keys_count)

  for key_count in keys_count
    if key_count > 1
      " We need to create a subgroup
      " Recurse one level deeper
      let groups[a:keys[key]] = smalls#{s:libname}#SCTree(a:targets[i : i + key_count - 1], a:keys)

    elseif key_count == 1
      " Assign single target key
      let groups[a:keys[key]] = a:targets[i]
    else
      " No target
      continue
    endif

    let key += 1
    let i += key_count
  endfor
  " }}}

  " Finally!
  return groups
endfunction


function! smalls#grouping#Original(targets, keys) "{{{1
  " Split targets into groups (1 level)
  let targets_len = len(a:targets)
  let keys_len = len(a:keys)

  let groups = {}

  let i = 0
  let root_group = 0
  try
    while root_group < targets_len
      let groups[a:keys[root_group]] = {}

      for key in a:keys
        let groups[a:keys[root_group]][key] = a:targets[i]

        let i += 1
      endfor

      let root_group += 1
    endwhile
  catch | endtry

  " Flatten the group array
  if len(groups) == 1
    let groups = groups[a:keys[0]]
  endif

  return groups
endfunction
" vim: foldmethod=marker
