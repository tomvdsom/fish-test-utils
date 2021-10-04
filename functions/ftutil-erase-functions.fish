function ftutil-erase-functions --description "Erase functions, matching given regexes.  Optionally outputs the origin of the erased functions with --save-origin (filepaths of the to `source` files, this obviously only works for autoloaded or `source`'d files)."
    set --local save_origin false
    set --local fn_regexes
    set --local fps_origins

    argparse s/save-origin -- $argv
    or return 1

    # Process options and args
    set fn_regexes $argv
    if count $_flag_save_origin >/dev/null
        set save_origin true
    end

    for f in (functions --all)
        for re in $fn_regexes
            if string match --regex --quiet -- $re $f
                set --local _fn_erased_fp (functions --details -- $f)
                # Later: below fns and join/slice trick nice for a verbose / logging mode, or for only reloading autoloaded fns for example.
                # set --local _fn_erased_autoloaded (functions --details --verbose -- $f | string join0 | string split0 -f2)

                functions --erase -- $f

                switch $_fn_erased_fp
                    case stdin
                    case -
                    case n/a # Most likely erased ...
                    case '*' # AKA: reloadable
                        if test $save_origin = true
                            if not contains $_fn_erased_fp $fps_origins
                                set --append fps_origins $_fn_erased_fp
                            end
                        end
                end
            end
        end
    end

    if test $save_origin = true
        and count $fps_origins >/dev/null
        echo -n $fps_origins
    end
    return 0
end
