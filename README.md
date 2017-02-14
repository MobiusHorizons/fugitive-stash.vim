# fugitive-gitlab.vim

fugitive.vim is undoubtedly the best Git wrapper of all time.

This plugin allows you to use it with private stash instances.

Install it as you would install fugitive.vim.

To use private stash repositories add the follow to your .vimrc

    let g:fugitive_stash_domains = ['http://mystash', 'http://mystash.mydomain.com']

fugitive command :Gbrowse will now work with stash URLs.

## Requirements

fugitive-stash.vim requires [fugitive.vim](https://github.com/tpope/vim-fugitive) 2.1 or higher to function.
