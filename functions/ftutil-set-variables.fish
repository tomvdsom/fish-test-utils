function _ftutil-set-variables_set-quad --argument-names quad
    set --local name
    set --local scope
    set --local exported
    set --local exported_flag
    set --local values
    set --local unescaped_values

    # Match & validate input to quad pattern
    string match --regex --quiet -- '^(?<name>[^|]+)\|(?<scope>[^|]+)\|(?<exported>[^|]+)\|(?<values>[^|]*)$' $quad
    if test $status -ne 0
        echo "ftutil-set-variables: Error: invalid variable quad: $quad" >&2
        return 1
    end

    # Assert & destructure triple
    if not string match --regex --quiet -- '^[0-9_A-Za-z]+$' $name
        echo "ftutil-set-variables: Error: invalid name `$name` mentioned in variable quad: $quad" >&2
        return 1
    end

    if not string match --regex --quiet -- '^(local|global|universal)$' $scope
        echo "ftutil-set-variables: Error: unknown scope `$scope` mentioned in variable quad: $quad" >&2
        return 1
    end
    if test $scope = local
        echo "ftutil-set-variables: Error: local scope not allowed, because it cannot be (usefully) set; mentioned in variable quad: $quad" >&2
        return 1
    end

    if not string match --regex --quiet -- '^(exported|unexported)$' $exported
        echo "ftutil-set-variables: Error: unknown exported state `$exported` mentioned in variable quad: $quad" >&2
        return 1
    else if test $exported = exported
        set -- exported_flag --export
    end

    if not string match --regex --quiet -- '^[0-9_A-Za-z,]*$' $values
        echo "ftutil-set-variables: Error: invalid values `$values` mentioned in variable quad: $quad" >&2
        return 1
    end
    for val in (string split -- \, $values)
        set --local val_unescaped (string unescape --style=var -- $val | string collect)
        if test (string length "$val") -ne 0
            and test (string length "$val_unescaped") -eq 0
            echo "ftutil-set-variables: Error: invalid encoded value `$val` in value `$values` mentioned in variable quad: $quad" >&2
            return 1
        end
        set --append unescaped_values $val_unescaped
    end

    # Set var from triple
    set "--$scope" $exported_flag -- $name $unescaped_values
    return 0
end

function ftutil-set-variables --description "Set variables from a \"list\" of concatenated quads (name, scope, (un)exported and escaped-value(s)); setting is supported for global and universal scopes."
    argparse h/help -- $argv # argparse is unhappy without at least one option ...
    or return 1

    # Process options, args and stdin
    set --local var_quads
    set --local stdin_lines
    set --local maybe_var_quads
    if not isatty
        read -z --delimiter=\n --list stdin_lines
    end
    for mvq in $argv
        set --append maybe_var_quads $mvq
    end
    set --erase argv
    for mvq in $stdin_lines
        set --append maybe_var_quads $mvq
    end
    set --erase stdin_lines
    for mvq in $maybe_var_quads
        for i in (string split --no-empty -- \n $mvq)
            if not string match --regex --quiet -- '^[[:space:]]*$' $i
                set --append var_quads (string replace --all --regex -- '[[:space:]]+' '' $i)
            end
        end
    end
    # echo 'Count maybe_var_quads: '(count $maybe_var_quads) # >&2
    # echo 'maybe_var_quads, escaped: '(string escape --style=var -- $maybe_var_quads) # >&2
    set --erase _flag_h _flag_help maybe_var_quads

    # echo 'Count quads: '(count $var_quads) # >&2
    for quad in $var_quads
        _ftutil-set-variables_set-quad $quad
        set --local _status $status
        if test $_status -ne 0
            return $_status
        end
    end

    return 0
end
