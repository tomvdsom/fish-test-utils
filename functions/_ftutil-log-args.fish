function _ftutil-log-args
    set --local count_argv (count $argv)
    if test $count_argv -gt 0
        for i in (seq $count_argv)
            switch $argv[$i]
                case ''
                    # Faking the empty string argument, this hack is not needed when using `--style=script`, but the output
                    # adds (a lot of) escaping chars.  Those make it hard to determine what $argv actually was.
                    # Encoded is horrible, but _is_ 1-to-1 the actual value-as-an-argument if (straightforwardly) decoded.
                    echo -n \'\'
                case '*'
                    string escape --style=var -- $argv[$i] | tr -d \n # Using `tr` instead of `string trim` or `string collect` since these add a newline.
            end
            if test $i -lt $count_argv
                # AKA `string join ' '` the hard way.
                echo -n ' '
            end
        end
    end
    echo # Add a newline to conclude args (so with `string collect` usable in `test` - without empty args, and thus command substitution - elided).
end
