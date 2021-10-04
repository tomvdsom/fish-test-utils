@echo === ftutil-empty-variables ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-empty-variables.fish"

# Cleanup
function _ftutil-empty-variables-test_fn-cleanup --on-event fish_exit
    set --erase --universal _ftutil_empty_variables_test_a_universal_variable
    set --erase --universal _ftutil_empty_variables_test_a_universal_variable2
end

#
# Helpers
function _show-long
    set --local var_name $argv[1]
    set --local var_scope $argv[2] # local, global or universal
    set --local var_values $argv[3..]
    echo -n -- "\$$var_name: set in $var_scope scope, unexported"
    if count $var_values >/dev/null
        and test (string length -- $var_values[1]) -ne 0
        echo -- ", with "(count $var_values)" elements"
        set --local index 0
        for v in $var_values
            set index (math $index + 1)
            echo -- "\$$var_name"'['"$index"']: |'"$v"'|'
        end
    else
        echo -- ', with 0 elements'
    end
end

#
# Tests
function _ftutil-empty-variables-test_basic_fn
    set a_fn_local fn
    set --local a_normal_local normal
    set --global a_global glo
    set --universal _ftutil_empty_variables_test_a_universal_variable uni
    @echo ' • basic usage: one regex, one var, one value'

    @test "A function local var, is set" (set --show --long a_fn_local | string collect) = (_show-long a_fn_local local fn | string collect)
    ftutil-empty-variables '^a_fn_local$'
    @test "A function local var, is emptied" (set --show --long a_fn_local | string collect) = (_show-long a_fn_local local | string collect)

    @test "A normal local var, is set" (set --show --long a_normal_local | string collect) = (_show-long a_normal_local local normal | string collect)
    ftutil-empty-variables a_normal_local
    @test "A normal local, is emptied" (set --show --long a_normal_local | string collect) = (_show-long a_normal_local local | string collect)

    @test "A global var, is set" (set --show --long a_global | string collect) = (_show-long a_global global glo | string collect)
    ftutil-empty-variables a_global
    @test "A global var, is emptied" (set --show --long a_global | string collect) = (_show-long a_global global | string collect)

    @test "An universal var, is set" (set --show --long _ftutil_empty_variables_test_a_universal_variable | string collect) = '$_ftutil_empty_variables_test_a_universal_variable: set in universal scope, unexported, with 1 elements
$_ftutil_empty_variables_test_a_universal_variable[1]: |uni|'
    ftutil-empty-variables _ftutil_empty_variables_test_a_universal_variable
    @test "An universal var, is _still there_ - but a global shadows it" (set --show --long _ftutil_empty_variables_test_a_universal_variable | string collect) = '$_ftutil_empty_variables_test_a_universal_variable: set in global scope, unexported, with 0 elements
$_ftutil_empty_variables_test_a_universal_variable: set in universal scope, unexported, with 1 elements
$_ftutil_empty_variables_test_a_universal_variable[1]: |uni|'
end

function _ftutil-empty-variables-test_multivalued_fn
    set --local a_local2 n1 n2
    set --universal _ftutil_empty_variables_test_a_universal_variable2 uni1 uni2 uni3
    @echo ' • multivalued variables'

    @test "Multi-valued variables fully emptied (1/4)" (set --show --long a_local2 | string collect) = '$a_local2: set in local scope, unexported, with 2 elements
$a_local2[1]: |n1|
$a_local2[2]: |n2|'
    ftutil-empty-variables a_local2
    @test "Multi-valued variables fully emptied (2/4)" (set --show --long a_local2 | string collect) = (_show-long a_local2 local)

    @test "Multi-valued variables fully emptied (3/4)" (set --show --long _ftutil_empty_variables_test_a_universal_variable2 | string collect) = '$_ftutil_empty_variables_test_a_universal_variable2: set in universal scope, unexported, with 3 elements
$_ftutil_empty_variables_test_a_universal_variable2[1]: |uni1|
$_ftutil_empty_variables_test_a_universal_variable2[2]: |uni2|
$_ftutil_empty_variables_test_a_universal_variable2[3]: |uni3|'
    ftutil-empty-variables _ftutil_empty_variables_test_a_universal_variable2
    @test "Multi-valued variables fully emptied (4/4)" (set --show --long _ftutil_empty_variables_test_a_universal_variable2 | string collect) = '$_ftutil_empty_variables_test_a_universal_variable2: set in global scope, unexported, with 0 elements
$_ftutil_empty_variables_test_a_universal_variable2: set in universal scope, unexported, with 3 elements
$_ftutil_empty_variables_test_a_universal_variable2[1]: |uni1|
$_ftutil_empty_variables_test_a_universal_variable2[2]: |uni2|
$_ftutil_empty_variables_test_a_universal_variable2[3]: |uni3|'
end

function _ftutil-empty-variables-test_regexes_fn
    set --local a_local_postfix1 p1
    set --local a_local_another_postfix p2
    set --local totally_different p3
    @echo ' • multiple regexes, more than one match for a regex'

    @test "Multiple variable-matching regexes - before (1/6)" (set --show --long a_local_postfix1 | string collect) = (_show-long a_local_postfix1 local p1 | string collect)
    @test "Multiple variable-matching regexes - before (2/6)" (set --show --long a_local_another_postfix | string collect) = (_show-long a_local_another_postfix local p2 | string collect)
    @test "Multiple variable-matching regexes - before (3/6)" (set --show --long totally_different | string collect) = (_show-long totally_different local p3 | string collect)

    ftutil-empty-variables '^._local_.*$' 'totally_d.*ff.*'

    @test "Multiple variable-matching regexes - after (4/6)" (set --show --long a_local_postfix1 | string collect) = (_show-long a_local_postfix1 local | string collect)
    @test "Multiple variable-matching regexes - after (5/6)" (set --show --long a_local_another_postfix | string collect) = (_show-long a_local_another_postfix local | string collect)
    @test "Multiple variable-matching regexes - after (6/6)" (set --show --long totally_different | string collect) = (_show-long totally_different local | string collect)
end

#
# Run tests
_ftutil-empty-variables-test_basic_fn
_ftutil-empty-variables-test_multivalued_fn
_ftutil-empty-variables-test_regexes_fn
