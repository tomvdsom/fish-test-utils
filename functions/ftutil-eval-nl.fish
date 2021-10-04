function ftutil-eval-nl --no-scope-shadowing --description 'Prevent eliding of command substitution argument when no stdout output happens by using `ftutil-eval-nl` prepended as a command.  Functionally ~identical to: `begin; cmd-under-test arg1 arg2 ...; echo; end` (unconditionally append a newline to stdout) but shorter for better test readability.  Short optional command `en` available after calling `futil-eval-nl --short-cmd` in a fish process.'
    # Goal: prevent "test: Missing argument at index N", effectively testing: `test = "<expected>"` i.s.o. `test "" = "<expected>"`
    #
    # Eliding of arguments happens in fish and therefor Fishtape's `if test $argv`-implementation on command substitution
    # without any output.
    #
    # However, when using `string collect` anyway, by not specifying --no-trim-newlines,
    # this fine "add a newline at-the-end" hack works nicely.
    #
    # Example usage:
    #   - With `test`: `test (ftutil-eval-nl cmd-under-test arg1 arg2 ... | string collect) = 'expected'`
    #   - With Fishtapes `@test`: `@test 'Beautifully descriptive description' (ftutil-eval-nl cmd-under-test arg1 arg2 ... | string collect) = 'expected'`
    if test (count $argv) -eq 1
        and test $argv[1] = --short-cmd
        function en --no-scope-shadowing --description 'Short command for `ftutil-eval-nl`.'
            ftutil-eval-nl $argv
        end
        return 0
    end
    eval (string escape -- $argv)
    set --local _ftutil_eval_nl_status $status
    echo
    return $_ftutil_eval_nl_status
end
