function ftutil-echo-err --description 'Same as `echo`, but to stderr.  Identical to `echo ... >&2` - but the intention is readable in the command, and not miles of characters away, after a linewrap in your editor you didn\'t notice.  Short optional command `echo-err` available after calling `futil-echo-err --short-cmd` in a fish process.'
    if test (count $argv) = 1
        and test $argv[1] = --short-cmd
        function echo-err --description 'Short command for `ftutil-echo-err`.'
            ftutil-echo-err $argv
        end
        return 0
    end
    echo $argv >&2
end
