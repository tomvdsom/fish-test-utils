function ftutil-eval-nl-err --no-scope-shadowing --description 'Like ftutil-eval-nl, but unconditionally append a newline to stderr.  Short optional command `ene` available after calling `futil-eval-nl-err --short-cmd` in a fish process.'
    if test (count $argv) -eq 1
        and test $argv[1] = --short-cmd
        function ene --no-scope-shadowing --description 'Short command for `ftutil-eval-nl-err`.'
            ftutil-eval-nl-err $argv
        end
        return 0
    end
    eval (string escape -- $argv)
    set --local _ftutil_eval_nl_err_status $status
    echo >&2
    return $_ftutil_eval_nl_err_status
end
