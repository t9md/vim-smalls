# First of all

Specially thanks to Lokaltog who created great [vim-easymotion](https://github.com/Lokaltog/vim-easymotion).
Without his former work, I don't think I could create smalls from scratch.

# What is this?
Yet another cursor movement plugin.
Search and jump with easymotion style.

## Features
* jump directly with easymotion style.
* support all, forward, backward direction. but 'all' is always best I believe.
* skip fold.
* work for normal, operator, visual mode.
* highlight selected area in operator and visual mode, it helps you know area to be deleted or yanked.
* move around candidate with hkjl(excursion-mode)
* full customizable keybinding in excursion-mode and cli-mode
* auto-show-up easymotion style jump key at specified timeout.
* auto-show-up timeout wouldn't be triggered until it exceed specified type length.
* color customizable.
* always ignore case for jump key(easy to type).

# Movie
![Movie](https://github.com/t9md/t9md/commit/556e4cdd54739eae646ae80632dbee626dce193b#diff-edade7341519b30c11f8dc2a33fdac5a)

# Configuration example

    " map normal-mode 's' for simple search
    nmap s <Plug>(smalls)
    " if you want to use smalls in visual/operator or both mode.
    omap s <Plug>(smalls)
    xmap s <Plug>(smalls)

    " [NOTE] optionally it might be comfortable if you enable 'smartcase'
    " comment-in following line if you want to.
    " set ignorecase smartcase



# Related work
If you don't like this plugin? It's ok, there are a lot of plugins like bellow.  

* [easymotion](https://github.com/Lokaltog/vim-easymotion)
* [clever-f](https://github.com/rhysd/clever-f.vim)
* [sneak](https://github.com/justinmk/vim-sneak)
