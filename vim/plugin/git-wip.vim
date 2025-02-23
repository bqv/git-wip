" ---------------------------------------------------------------------------
" git wip stuff

if !exists('g:git_wip_verbose')
        let g:git_wip_verbose = 0
endif
if !exists('g:git_wip_disable_signing')
        let g:git_wip_disable_signing = 0
endif

let g:git_wip_status = 0  " 0 = unchecked, 1 = good, 2 = failed

function! GitWipSave()
        if expand("%") == ".git/COMMIT_EDITMSG"
            return
        endif
        if g:git_wip_status == 2
            augroup git-wip 2>&1 >/dev/null
                    autocmd!
            augroup END
            return
        endif
        if g:git_wip_status == 0
            silent! !git wip -h 2>&1 >/dev/null
            redraw
            if v:shell_error
                let g:git_wip_status = 2
                return
            else
                let g:git_wip_status = 1
            endif
        endif
        let wip_opts = '--editor'
        if g:git_wip_disable_signing
            let wip_opts .= ' --no-gpg-sign'
        endif
        let out = system('git rev-parse 2>&1')
        if v:shell_error
            return
        endif
        let dir = expand("%:p:h")
        let show_cdup = system('cd "' . dir . '" && git rev-parse --show-cdup 2>/dev/null </dev/null')
        if v:shell_error
            " We're not editing a file anywhere near a .git repository, so abort
            return
        endif
        let show_cdup_len = len( show_cdup )
        if show_cdup_len == 0
            " We're editing a file in the .git directory
            " (.git/EDIT_COMMITMSG, .git/config, etc.), so abort
            return
        endif
        let file = expand("%:t")
        let out = system('cd "' . dir . '" && git wip save "WIP from vim (' . file . ')" ' . wip_opts . ' -- "' . file . '" 2>&1 >/dev/null </dev/null& disown')
        let err = v:shell_error
        if err
                redraw
                echohl Error
                echo "git-wip: " . out
                echohl None
        elseif g:git_wip_verbose
                redraw
                echo "git-wip: " . out
        endif
endf

augroup git-wip
        autocmd!
        autocmd BufWritePost * :call GitWipSave()
augroup END
