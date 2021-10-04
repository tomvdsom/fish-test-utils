function ftutil-empty-variables --no-scope-shadowing --description "Set empty variables for variables matching given regexes. Overrides a global or local, universal variables are shadowed, but untouched."
    #
    # Local names are namespaced to prevent accidental matching variable regexes.
    #
    set --local _ftutil_empty_variables_var_regexes

    argparse h/help -- $argv # argparse is unhappy without at least one option ...
    or return 1
    set --erase --local _flag_h _flag_help

    # Process options and args
    set _ftutil_empty_variables_var_regexes $argv

    for _ftutil_empty_variables_name in (set --names)
        for _ftutil_empty_variables_var_re in $_ftutil_empty_variables_var_regexes
            if string match --regex --quiet -- $_ftutil_empty_variables_var_re $_ftutil_empty_variables_name
                if set --query --local $_ftutil_empty_variables_name
                    # Actually, function scope too ("looks like" local scope).
                    set $_ftutil_empty_variables_name # Override with empty list, don't add `--local`
                end
                if set --query --global $_ftutil_empty_variables_name
                    set --global $_ftutil_empty_variables_name
                else if set --query --universal $_ftutil_empty_variables_name
                    set --global $_ftutil_empty_variables_name # Shadow with empty list
                end
            end
        end
    end

    return 0
end
