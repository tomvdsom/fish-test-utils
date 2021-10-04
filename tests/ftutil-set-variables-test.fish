@echo === ftutil-set-variables ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-set-variables.fish"
source (dirname (status dirname))"/functions/ftutil-erase-variables.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl-err.fish"

ftutil-eval-nl --short-cmd
ftutil-eval-nl-err --short-cmd
set --global _tmpdir (mktemp -d)
set --local _out_and_err_output $_tmpdir/out-and-err
set --local _out_output $_tmpdir/out
set --local _err_output $_tmpdir/err

# Cleanup
function _ftutil_erase_variables_test_cleanup --on-event fish_exit
    set --erase --universal _ftutil_set_variables_test_a_variable _ftutil_set_variables_test_b_variable
    rm -r $_tmpdir
end

#
# Helpers (duplicated from: ftutil-erase-variables-test)
function _show-long
    set --local var_name $argv[1]
    set --local var_scope $argv[2] # local, global or universal
    set --local var_exported $argv[3]
    set --local var_values $argv[4..]

    set --local var_exported_str

    if test $var_exported = u
        set var_exported_str unexported
    else # x
        set var_exported_str exported
    end
    echo -n -- "\$$var_name: set in $var_scope scope, $var_exported_str"
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

function _erase-all-fixed --no-scope-shadowing
    for i in (seq 10)
        set --erase _ftutil_set_variables_test_a_variable _ftutil_set_variables_test_b_variable
    end

    set --erase --global -- _a_variable _b_variable _c_variable
    for i in (seq 9)
        set --erase --local -- _a_variable _b_variable _c_variable
    end
end

#
# Tests
@echo ' • basic usage: no setting'
@test 'No variables set when none given (1/3)' (en ftutil-set-variables 2>/dev/null | string collect) = ''
@test 'No variables set when none given (2/3)' (ene ftutil-set-variables 2>&1 >/dev/null | string collect) = ''
@test 'No variables set when none given (3/3)' (ftutil-set-variables) $status -eq 0

set --local in_stdin \ \t\n \n\n\  # All categories of :space: ... not that important they all work, just usual suspects of (accidental) formatting input.
set --local in_args "" "  " \ \n\n\t\  #           ... :space: ...
@test 'No variables set when non-variable empty-ish args or stdin (1/3)' (begin; echo -n $in_stdin | en ftutil-set-variables $in_args; end 2>/dev/null | string collect) = ''
@test 'No variables set when non-variable empty-ish args or stdin (2/3)' (begin; echo -n $in_stdin | ene ftutil-set-variables $in_args; end 2>&1 >/dev/null | string collect) = ''
@test 'No variables set when non-variable empty-ish args or stdin (3/3)' (begin; echo -n $in_stdin | ftutil-set-variables $in_args; end) $status -eq 0

@echo ' • basic usage: one variable set'
ftutil-set-variables '_a_variable|global|unexported|X' 2>&1 >$_out_and_err_output
set --local _status $status
@test 'Set a global (1/3) - as arg' $_status -eq 0
@test 'Set a global (2/3) - as arg' (begin; cat $_out_and_err_output; echo -n x; end | string collect --no-trim-newlines) = x
@test 'Set a global (3/3) - as arg' (en set --show --long _a_variable | string collect) = (_show-long _a_variable global u X | string collect)
_erase-all-fixed
echo -n '_a_variable|global|unexported|X' | ftutil-set-variables 2>&1 >$_out_and_err_output
set --local _status $status
@test 'Set a global (1/3) - via stdin' $_status -eq 0
@test 'Set a global (2/3) - via stdin' (begin; cat $_out_and_err_output; echo -n x; end | string collect --no-trim-newlines) = x
@test 'Set a global (3/3) - via stdin' (en set --show --long _a_variable | string collect) = (_show-long _a_variable global u X | string collect)
_erase-all-fixed

@test 'Set an universal (1/2)' (ftutil-set-variables '_ftutil_set_variables_test_a_variable|universal|exported|Y') $status -eq 0
@test 'Set an universal (2/2)' (en set --show --long _ftutil_set_variables_test_a_variable | string collect) = (_show-long _ftutil_set_variables_test_a_variable universal x Y | string collect)
_erase-all-fixed

@echo ' • multiple values'
@test 'Set multiple values (1/2)' (ftutil-set-variables '_a_variable|global|exported|X,Y,Zee') $status -eq 0
@test 'Set multiple values (2/2)' (en set --show --long _a_variable | string collect) = (_show-long _a_variable global x X Y Zee | string collect)
_erase-all-fixed

@echo ' • locally scoped'
@test 'Setting a local-scoped variable is not allowed (1/4)' (ftutil-set-variables '_a_variable|local|unexported|' >/dev/null 2>&1) $status -eq 1
@test 'Setting a local-scoped variable is not allowed (2/4)' (ftutil-set-variables '_a_variable|local|exported|' 2>&1 >/dev/null | string collect) = 'ftutil-set-variables: Error: local scope not allowed, because it cannot be (usefully) set; mentioned in variable quad: _a_variable|local|exported|'
@test 'Setting a local-scoped variable is not allowed (3/4)' (ftutil-set-variables '_a_variable|local|unexported|X' 2>&1 | string collect) = 'ftutil-set-variables: Error: local scope not allowed, because it cannot be (usefully) set; mentioned in variable quad: _a_variable|local|unexported|X'
@test 'Setting a local-scoped variable is not allowed (4/4)' (en set --show --long _a_variable | string collect) = ''
_erase-all-fixed

@echo ' • values are escaped'
@test '(Non var-compatible) values are escaped (1/2)' (ftutil-set-variables '_a_variable|global|unexported|h_20_i') $status -eq 0
@test '(Non var-compatible) values are escaped (2/2)' (en set --show --long _a_variable | string collect) = (_show-long _a_variable global u 'h i' | string collect)
_erase-all-fixed

echo '_a_variable|global|unexported|'(string escape --style=var \t\n\ ,\\\'☃️) | ftutil-set-variables
@test 'Complex escaped values are set correctly (1/3)' (string escape --style=var \t\n\ ,\\\'☃️) = _09_0A_20_2C_5C_27_E2_98_83_EF_B8_8F_
@test 'Complex escaped values are set correctly (2/3)' (en set --show --long _a_variable | string collect) = "\$_a_variable: set in global scope, unexported, with 1 elements
\$_a_variable[1]: |\\t\\n ,\\\\\'☃️|"
@test 'Complex escaped values are set correctly (3/3)' (echo -n -- $_a_variable | string collect) = \t\n\ ,\\\'☃️
_erase-all-fixed

@test 'Set values surrounded by whitespace (1/4)' (echo \ \ \ _a_variable\|global\|unexported\|A\t\ \n\t\ _b_variable\|global\|exported\|B,e,e\t\t | ftutil-set-variables) $status -eq 0
@test 'Set values surrounded by whitespace (2/4)' (en set --show --long _a_variable _b_variable | string collect) = '$_a_variable: set in global scope, unexported, with 1 elements
$_a_variable[1]: |A|
$_b_variable: set in global scope, exported, with 3 elements
$_b_variable[1]: |B|
$_b_variable[2]: |e|
$_b_variable[3]: |e|'
_erase-all-fixed
@test 'Set values surrounded by whitespace (3/4)' (ftutil-set-variables \ \ \ _a_variable\|global\|unexported\|A\t\ \n\t\ _b_variable\|global\|exported\|B,e,e\t\t ) $status -eq 0
@test 'Set values surrounded by whitespace (4/4)' (en set --show --long _a_variable _b_variable | string collect) = '$_a_variable: set in global scope, unexported, with 1 elements
$_a_variable[1]: |A|
$_b_variable: set in global scope, exported, with 3 elements
$_b_variable[1]: |B|
$_b_variable[2]: |e|
$_b_variable[3]: |e|'
_erase-all-fixed

@echo ' • multiple variables'
echo '
_a_variable|global|unexported|A
_a_variable|global|exported|A2
_ftutil_set_variables_test_a_variable|global|unexported|nA' | ftutil-set-variables '_a_variable|global|unexported|A3' '_b_variable|global|unexported|B'\n'_ftutil_set_variables_test_a_variable|universal|exported|nA2'\n'_ftutil_set_variables_test_b_variable|universal|unexported|n,Bee' 2>&1 >$_out_and_err_output
set --local _status $status
@test 'multiple variables set via stdin and args (1/3)' $_status -eq 0
@test 'multiple variables set via stdin and args (2/3)' (begin; cat $_out_and_err_output; echo -n x; end | string collect --no-trim-newlines) = x
@test 'multiple variables set via stdin and args (3/3)' (en set --show --long _a_variable _b_variable _c_variable _ftutil_set_variables_test_a_variable _ftutil_set_variables_test_b_variable | string collect) = '$_a_variable: set in global scope, exported, with 1 elements
$_a_variable[1]: |A2|
$_b_variable: set in global scope, unexported, with 1 elements
$_b_variable[1]: |B|
$_ftutil_set_variables_test_a_variable: set in global scope, unexported, with 1 elements
$_ftutil_set_variables_test_a_variable[1]: |nA|
$_ftutil_set_variables_test_a_variable: set in universal scope, exported, with 1 elements
$_ftutil_set_variables_test_a_variable[1]: |nA2|
$_ftutil_set_variables_test_b_variable: set in universal scope, unexported, with 2 elements
$_ftutil_set_variables_test_b_variable[1]: |n|
$_ftutil_set_variables_test_b_variable[2]: |Bee|'
_erase-all-fixed

@echo ' • erase & set round-trip'
set --global _a_variable 🌨️☃️🌨️
set --global _b_variable B
set --global _c_variable Cee
set value (ftutil-erase-variables -sg '_._variable' | string collect)
@test 'Erase and set round-trip (1/3)' (en set --show --long _a_variable _b_variable _c_variable | string collect) = ''
@test 'Erase and set round-trip (2/3)' (ftutil-set-variables $value 2>&1) $status -eq 0
@test 'Erase and set round-trip (3/3)' (en set --show --long _a_variable _b_variable _c_variable | string collect) = '$_a_variable: set in global scope, unexported, with 1 elements
$_a_variable[1]: |🌨️☃️🌨️|
$_b_variable: set in global scope, unexported, with 1 elements
$_b_variable[1]: |B|
$_c_variable: set in global scope, unexported, with 1 elements
$_c_variable[1]: |Cee|'
_erase-all-fixed

@echo ' • error handling'
@test 'Exist status of helper fn propagated' (ftutil-set-variables 'invalid_var' >$_out_output 2>$_err_output) $status -eq 1
@test 'Variable not set if exist status of helper fn non-zero' (en set --show --long invalid_var | string collect) = ''
@test 'Invalid variable quad (1/2)' (en cat $_out_output | string collect) = ''
@test 'Invalid variable quad (2/2)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: invalid variable quad: invalid_var'

ftutil-set-variables 'invalid-var|global|unexported|' >$_out_output 2>$_err_output
@test 'Invalid name (1/2)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid name (2/2)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: invalid name `invalid-var` mentioned in variable quad: invalid-var|global|unexported|'

ftutil-set-variables 'invalid_var|scopy|unexported|' >$_out_output 2>$_err_output
@test 'Invalid scope (1/2)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid scope (2/2)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: unknown scope `scopy` mentioned in variable quad: invalid_var|scopy|unexported|'

ftutil-set-variables 'invalid_var|local|unexported|' >$_out_output 2>$_err_output
@test 'Valid scope, but local is disallowed (1/2)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Valid scope, but local is disallowed (2/2)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: local scope not allowed, because it cannot be (usefully) set; mentioned in variable quad: invalid_var|local|unexported|'

ftutil-set-variables 'invalid_var|global|xported|' >$_out_output 2>$_err_output
@test 'Invalid exported (1/2)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid exported (2/2)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: unknown exported state `xported` mentioned in variable quad: invalid_var|global|xported|'

ftutil-set-variables 'invalid_var|global|unexported|-invalid-value' >$_out_output 2>$_err_output
@test 'Invalid values (1/4)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid values (2/4)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: invalid values `-invalid-value` mentioned in variable quad: invalid_var|global|unexported|-invalid-value'

ftutil-set-variables 'invalid_var|global|unexported|x,-invalid-value' >$_out_output 2>$_err_output
@test 'Invalid values (3/4)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid values (4/4)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: invalid values `x,-invalid-value` mentioned in variable quad: invalid_var|global|unexported|x,-invalid-value'

ftutil-set-variables 'invalid_var|global|unexported|_XX_' >$_out_output 2>$_err_output
@test 'Invalid value-in-values (1/4)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid value-in-values (2/4)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: invalid encoded value `_XX_` in value `_XX_` mentioned in variable quad: invalid_var|global|unexported|_XX_'

ftutil-set-variables 'invalid_var|global|unexported|x,☃️' >$_out_output 2>$_err_output
@test 'Invalid value-in-values (3/4)' (test $status -eq 1; and test (en cat $_out_output | string collect) = '') $status -eq 0
@test 'Invalid value-in-values (4/4)' (en cat $_err_output | string collect) = 'ftutil-set-variables: Error: invalid values `x,☃️` mentioned in variable quad: invalid_var|global|unexported|x,☃️'

@test 'Verify all invalid-vars have been tested as invalid and not set (last error-handling test)' (en set --show --long invalid_var | string collect) = ''

#
# Helpers
@echo ' • _erase-all: dependency-less erase a variable in all (shadowed) scopes'
set --local _a_variable X
set --local _b_variable X
set --local _c_variable X
set --local _ftutil_set_variables_test_a_variable X
set --local _ftutil_set_variables_test_b_variable X
set --global _ftutil_set_variables_test_a_variable X
set --global _ftutil_set_variables_test_b_variable X
set --universal _ftutil_set_variables_test_a_variable X
set --universal _ftutil_set_variables_test_b_variable X
begin
    set --local _c_variable X
    set --local _ftutil_set_variables_test_a_variable X
    @test 'Erases named variables (2 namespaced universal too) (1/2)' (en string length -- (set --show --long _a_variable _b_variable _c_variable _ftutil_set_variables_test_a_variable _ftutil_set_variables_test_b_variable | string collect) | string collect) = 1068
    _erase-all-fixed
    @test 'Erases named variables (2 namespaced universal too) (2/2)' (en string length -- (set --show --long _a_variable _b_variable _c_variable _ftutil_set_variables_test_a_variable _ftutil_set_variables_test_b_variable | string collect) | string collect) = ''
end
