function _ftutil-erase-variables-collect-encoded-values
    # Duplicated from _ftutil-log-args, with exceptions:
    #  - No --short-cmd option (like ftutil-log-args(-err), the other implementations, do have);
    #  - Empty input (or empty string) -> nothing
    #  - ',' instead of space as join-char;
    #  - no newline at end-of-encoded-values.
    set --local count_argv (count $argv)
    if test $count_argv -gt 0
        for i in (seq $count_argv)
            switch $argv[$i]
                case ''
                case '*'
                    string escape --style=var -- $argv[$i] | tr -d \n # Using `tr` instead of `string trim` or `string collect` since these add a newline.
            end
            if test $i -lt $count_argv
                echo -n ','
            end
        end
    end
end

function ftutil-erase-variables --no-scope-shadowing --description "Erase variables for variables matching given regexes.  Optionally outputs the erased variables as a \"list\" (newline separated) of concatenated quads (name, scope, (un)exported and escaped-value(s)) with -s / --save-variables (re-set quads with ftutil-set-variables) defaults to universal variables.  To save other scopes, add the desired scope(s), comma separated.  Scopes are currently: `universal`, `global` or `local`; also supports `none` and `all` for no saving or all scopes respectively."
    #
    # Local names are namespaced to prevent accidental matching or shadowing existing variable(s) - most likely in the calling scope (due to `--no-scope-shadowing` needed for local-scoped variables erasing).
    #
    set --local _ftutil_erase_variables_save_variable_scopes
    set --local _ftutil_erase_variables_var_regexes
    set --local _ftutil_erase_variables_saved

    argparse 's/save-variables=?' -- $argv
    or return 1

    # Process options and args
    set _ftutil_erase_variables_var_regexes $argv
    if count $_flag_save_variables >/dev/null
        set --local flag_save_vals (string split ',' $_flag_save_variables)
        if test (count $flag_save_vals) -eq 1
            and contains -- $flag_save_vals none n
            # For $flag_save_vals values `none` / `n`: Leaving _ftutil_erase_variables_save_variable_scopes empty, therefor nothing is saved.
        else
            for i in $flag_save_vals
                switch $i
                    case local l
                        contains local $_ftutil_erase_variables_save_variable_scopes
                        or set --append _ftutil_erase_variables_save_variable_scopes local
                    case global g
                        contains global $_ftutil_erase_variables_save_variable_scopes
                        or set --append _ftutil_erase_variables_save_variable_scopes global
                    case universal u
                        contains universal $_ftutil_erase_variables_save_variable_scopes
                        or set --append _ftutil_erase_variables_save_variable_scopes universal
                    case all a
                        set _ftutil_erase_variables_save_variable_scopes local global universal
                    case none n
                        echo (status function)": Error, flag `--save-variables` (comma separated) values, cannot combine n / none with any other value.\n  Values: $_flag_save_variables" >&2
                        return 1
                    case '*'
                        echo (status function)": Error, flag `--save-variables` (comma separated) value is not of type: l / local, g / global or u / universal - or a / all (shortcut for `l,g,u`) or n / none.\n  Values: $_flag_save_variables" >&2
                        return 1
                end
            end
        end
    else
        set _ftutil_erase_variables_save_variable_scopes universal
    end
    set --erase --local _flag_s _flag_save_variables

    for _ftutil_erase_variables_name in (set --names)
        for _ftutil_erase_variables_var_re in $_ftutil_erase_variables_var_regexes
            if string match --regex --quiet -- $_ftutil_erase_variables_var_re $_ftutil_erase_variables_name
                # Erase from innermost scope outwards to be able to read & save the (possibly) shadowed same-name-different-scope variables.
                set --local _ftutil_erase_variables_var_categorized false

                if set --query --local $_ftutil_erase_variables_name
                    set _ftutil_erase_variables_var_categorized true
                    while set --query --local $_ftutil_erase_variables_name
                        # Actually, function scope too ("looks like" local scope).
                        if contains local $_ftutil_erase_variables_save_variable_scopes
                            # - capturing the current value must be duplicated (multiple shadowed (possibly existing) Nx local scopes, 1x global and/or 1x universal scope)
                            # - Set value **must** be a variable (NO command substitution - those split on newline)!
                            eval set --local _ftutil_erase_variables_var_value \$$_ftutil_erase_variables_name
                            set --local _ftutil_erase_variables_var_exported (set --query --export $_ftutil_erase_variables_name; and echo -n exported; or echo -n unexported)
                            set --local _ftutil_erase_variables_var_encoded_value (_ftutil-erase-variables-collect-encoded-values $_ftutil_erase_variables_var_value)
                            set --append _ftutil_erase_variables_saved "$_ftutil_erase_variables_name|local|$_ftutil_erase_variables_var_exported|$_ftutil_erase_variables_var_encoded_value"
                        end
                        set --erase $_ftutil_erase_variables_name
                    end
                end
                if set --query --global $_ftutil_erase_variables_name
                    set _ftutil_erase_variables_var_categorized true
                    if contains global $_ftutil_erase_variables_save_variable_scopes
                        eval set --local _ftutil_erase_variables_var_value \$$_ftutil_erase_variables_name
                        set --local _ftutil_erase_variables_var_exported (set --query --export $_ftutil_erase_variables_name; and echo -n exported; or echo -n unexported)
                        set --local _ftutil_erase_variables_var_encoded_value (_ftutil-erase-variables-collect-encoded-values $_ftutil_erase_variables_var_value)
                        set --append _ftutil_erase_variables_saved "$_ftutil_erase_variables_name|global|$_ftutil_erase_variables_var_exported|$_ftutil_erase_variables_var_encoded_value"
                    end
                    set --erase $_ftutil_erase_variables_name
                end
                if set --query --universal $_ftutil_erase_variables_name
                    set _ftutil_erase_variables_var_categorized true
                    if contains universal $_ftutil_erase_variables_save_variable_scopes
                        eval set --local _ftutil_erase_variables_var_value \$$_ftutil_erase_variables_name
                        set --local _ftutil_erase_variables_var_exported (set --query --export $_ftutil_erase_variables_name; and echo -n exported; or echo -n unexported)
                        set --local _ftutil_erase_variables_var_encoded_value (_ftutil-erase-variables-collect-encoded-values $_ftutil_erase_variables_var_value)
                        set --append _ftutil_erase_variables_saved "$_ftutil_erase_variables_name|universal|$_ftutil_erase_variables_var_exported|$_ftutil_erase_variables_var_encoded_value"
                    end
                    set --erase $_ftutil_erase_variables_name
                end
                if test $_ftutil_erase_variables_var_categorized = false
                    # Note: --function scope may come later in fish explicitly...
                    echo (status function)": Error, variable `$_ftutil_erase_variables_name` is not of type: local, global or universal." >&2
                    return 1
                end
            end
        end
    end

    if count $_ftutil_erase_variables_saved >/dev/null
        echo -- (string join \n $_ftutil_erase_variables_saved | string collect)
    end
    return 0
end
