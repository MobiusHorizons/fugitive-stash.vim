" fugitive-stash.vim - stash support for fugitive.vim
" Maintainer:   Paul Martin <https://github.com/MobiusHorizons>
" Version:      0.9.0
"
" Based off of the work of fugitive-gitlab by Steven Humphrey (https://github.com/shumphrey/fugitive-gitlab.vim).

" Plugs in to fugitive.vim and provides a stash hook for :Gbrowse
" Relies on fugitive.vim by tpope <http://tpo.pe>
" See fugitive.vim for more details
" Requires fugitive.vim 2.1 or greater
"
" If using a private stash, you need to specify the stash domains for your
" stash instance.
" e.g.
"   let g:fugitive_stash_domains = ['http://stash.mydomain.com','https://stash.mydomain.com']
"

if exists('g:loaded_fugitive_stash')
    finish
endif
let g:loaded_fugitive_stash = 1

if !exists('g:fugitive_browse_handlers')
    let g:fugitive_browse_handlers = []
endif

function! s:stash_fugitive_handler(opts, ...)
    let path   = substitute(get(a:opts, 'path', ''), '^/', '', '')
    let line1  = get(a:opts, 'line1')
    let line2  = get(a:opts, 'line2')
    let remote = get(a:opts, 'remote')

    let domains = exists('g:fugitive_stash_domains') ? g:fugitive_stash_domains : []
    let rel_path = {}

    let domain_pattern = ''
    for domain in domains
        let domain = escape(split(domain, '://')[-1], '.')
        let domain_path = matchstr(domain, '/')
        if domain_path ==# '/'
            let domain_path = substitute(domain,'^[^/]*/','','')
        else
            let domain_path = ''
        endif
        let domain_root = split(domain, '/')[0]
        if domain_pattern == ''
          let domain_pattern = domain_root
        else 
          let domain_pattern .= '\|' . domain_root
        endif
        let rel_path[domain_root] = domain_path
    endfor

    " Try and extract a domain name from the remote
    " See https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols for the types of protocols.
    " If we can't extract the domain, we don't understand this protocol.
    " git://domain:path
    " https://domain/path
    let repo = matchstr(remote,'^\%(https\=://\|git://\|git@\)\=\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
    " ssh://user@domain:port/path.git
    if repo ==# ''
        let repo = matchstr(remote,'^\%(ssh://\%(\w*@\)\=\)\zs\('.domain_pattern.'\).\{-\}\ze\%(\.git\)\=$')
        let repo = substitute(repo, ':[0-9]\+', '', '')
    endif
    if repo ==# ''
        return ''
    endif

    let repo = substitute(repo, '^\('.domain_pattern.'\)/\([-A-Za-z0-9]\+\)/\([-A-Za-z0-9]\+\)$', '\1/projects/\U\2\e/repos/\3', '')

    " look for http:// + repo in the domains array
    " if it exists, prepend http, otherwise https
    " git/ssh URLs contain : instead of /, http ones don't contain :
    let repo_root = escape(split(split(repo, '://')[-1],':')[0], '.')
    let repo_path = get(rel_path, repo_root, '')
    if repo_path ==# ''
        let repo = substitute(repo,':','/','')
    else
        let repo = substitute(repo,':','/' . repo_path . '/','')
    endif
    if index(domains, 'http://' . matchstr(repo, '^[^:/]*')) >= 0
        let root = 'http://' . repo 
    else
        let root = 'https://' . repo 
    endif

    " work out what branch/commit/tag/etc we're on
    " if file is a git/ref, we can go to a /commits stash url
    " If the branch/tag doesn't exist upstream, the URL won't be valid
    " Could check upstream refs?
    if path =~# '^\.git/refs/heads/'
        return root . '/commits/' . path[16:-1]
    elseif path =~# '^\.git/refs/tags/'
        return root . '/tags/' . path[15:-1]
    elseif path =~# '^\.git/refs/.'
        return root . '/commits/' . path[10:-1]
    elseif path =~# '^\.git\>'
        return root
    endif

    " Work out the commit
    if a:opts.commit =~# '^\d\=$'
        let commit = a:opts.repo.rev_parse('HEAD')
    else
        let commit = a:opts.commit
    endif

    if get(a:opts, 'type', '') ==# 'tree' || a:opts.path =~# '/$'
        let url = substitute(root . '/browse/' . path . '?at='. commit,'/$','',''); 
    elseif get(a:opts, 'type', '') ==# 'blob' || a:opts.path =~# '[^/]$'
        let url = root . "/browse/" . path . '?at='. commit 
        if line2 && line1 == line2
            let url .= '#'.line1
        elseif line2
            let url .= '#' . line1 . '-' . line2
        endif
    else
        let url = root . '/commits/' . commit
    endif

    return url
endfunction

call insert(g:fugitive_browse_handlers, function('s:stash_fugitive_handler'))

" vim: set ts=4 sw=4 et
