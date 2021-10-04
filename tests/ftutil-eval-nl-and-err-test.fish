@echo '=== ftutil-eval-nl(-err) ==='
source (dirname (status dirname))"/functions/ftutil-eval-nl.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl-err.fish"
source (dirname (status dirname))"/functions/ftutil-echo-err.fish"
source (dirname (status dirname))"/functions/_ftutil-log-args.fish" # No indirect autoloading too.
source (dirname (status dirname))"/functions/ftutil-log-args.fish"
source (dirname (status dirname))"/functions/ftutil-log-args-err.fish"

ftutil-echo-err --short-cmd
ftutil-log-args --short-cmd
ftutil-log-args-err --short-cmd
set --global _tmp_dir (mktemp -d)

# Cleanup
function _ftutil_eval_nl_and_err_test_cleanup --on-event fish_exit
    rm -r $_tmp_dir
end

#
# Tests
@echo ' • Sanity check'
@test 'String collect right-trims consecutive newlines' (string escape --style=var -- (echo -ne '\nA\nnewline full string \t\n\n\n\n' | string collect)) = _0A_41_0A_newline_20_full_20_string_20_09_

@echo ' • Standalone behaviour'
@test '`⃨-nl` outputs a newline to stdout by itself (1/2)' (ftutil-eval-nl 2>/dev/null | string collect --no-trim-newlines) = \n
@test '`⃨-nl` outputs a newline to stdout by itself (2/2)' (begin; echo -n x >&2; ftutil-eval-nl; echo -n x >&2; end 2>&1 >/dev/null | string collect --no-trim-newlines) = xx
@test '`⃨-nl-err` outputs a newline to stderr by itself (1/2)' (ftutil-eval-nl-err 2>&1 >/dev/null | string collect --no-trim-newlines) = \n
@test '`⃨-nl-err` outputs a newline to stderr by itself (2/2)' (begin; echo -n x; ftutil-eval-nl-err; echo -n x; end 2>/dev/null | string collect --no-trim-newlines) = xx

@echo ' • Args eval(uated).'
set --local expected "1 t_20_w_20_o _0A_09_24_x"\n
@test '`⃨-nl` evaluates the original input arguments - as if entered by itself (1/2)' (log-args 1 "t w o" \n\t\$x | string collect --no-trim-newlines) = $expected
@test '`⃨-nl` evaluates the original input arguments - as if entered by itself (2/2)' (ftutil-eval-nl log-args 1 "t w o" \n\t\$x | string collect --no-trim-newlines) = "$expected"\n
@test '`⃨-nl-err` evaluates the original input arguments - as if entered by itself' (ftutil-eval-nl-err log-args 1 "t w o" \n\t\$x 2>/dev/null | string collect --no-trim-newlines) = $expected

@test '`⃨-nl` empty arguments kept (1/2)' (ftutil-eval-nl log-args '' '' | string collect) = "'' ''"
@test '`⃨-nl` empty arguments kept (2/2) - in between' (ftutil-eval-nl log-args In '' be '' '' tween | string collect) = "In '' be '' '' tween"
@test '`⃨-nl-err` empty arguments kept (1/2)' (ftutil-eval-nl-err log-args '' '' 2>/dev/null | string collect) = "'' ''"
@test '`⃨-nl-err` empty arguments kept (2/2) - in between' (ftutil-eval-nl-err log-args In '' be '' '' tween 2>/dev/null | string collect) = "In '' be '' '' tween"

@echo ' • Pass through stdout'
@test '`⃨-nl` stdout passed through (1/2)' (ftutil-eval-nl echo hi | string collect --no-trim-newlines) = hi\n\n
@test '`⃨-nl` stdout passed through (2/2)' (ftutil-eval-nl echo -e '\nhi' | string collect --no-trim-newlines) = \nhi\n\n
@test '`⃨-nl-err` stdout passed through (1/2)' (ftutil-eval-nl-err echo hi 2>/dev/null | string collect --no-trim-newlines) = hi\n
@test '`⃨-nl-err` stdout passed through (2/2)' (ftutil-eval-nl-err echo -e '\nhi' 2>/dev/null | string collect --no-trim-newlines) = \nhi\n

@echo ' • Pass through stderr'
@test '`⃨-nl` stderr passed through (1/2)' (ftutil-eval-nl echo-err hi 2>&1 >/dev/null | string collect --no-trim-newlines) = hi\n
@test '`⃨-nl` stderr passed through (2/2)' (ftutil-eval-nl echo-err -e '\nhi' 2>&1 >/dev/null | string collect --no-trim-newlines) = \nhi\n
@test '`⃨-nl-err` stderr passed through (1/2)' (ftutil-eval-nl-err echo-err hi 2>&1 >/dev/null | string collect --no-trim-newlines) = hi\n\n
@test '`⃨-nl-err` stderr passed through (2/2)' (ftutil-eval-nl-err echo-err -e '\nhi' 2>&1 >/dev/null | string collect --no-trim-newlines) = \nhi\n\n

@echo ' • `--` not interpreted'
@test '`⃨-nl(-err)` for -- usage (1/4)' (ftutil-eval-nl echo -- -- | string collect) = --
@test '`⃨-nl(-err)` for -- usage (2/4)' (ftutil-eval-nl log-args -- | string collect) = _2D_2D_
@test '`⃨-nl(-err)` for -- usage (3/4)' (ftutil-eval-nl-err echo-err -- -- 2>&1 >/dev/null | string collect) = --
@test '`⃨-nl(-err)` for -- usage (4/4)' (ftutil-eval-nl-err log-args-err -- 2>&1 >/dev/null | string collect) = _2D_2D_

@echo ' • Exit status of evaluated args'

@test '`⃨-nl(-err)` evaluated args exit status (1/4)' (ftutil-eval-nl false >/dev/null) $status -eq 1
@test '`⃨-nl(-err)` evaluated args exit status (2/4)' (ftutil-eval-nl true >/dev/null) $status -eq 0
@test '`⃨-nl(-err)` evaluated args exit status (3/4)' (ftutil-eval-nl-err false 2>/dev/null) $status -eq 1
@test '`⃨-nl(-err)` evaluated args exit status (4/4)' (ftutil-eval-nl-err true 2>/dev/null) $status -eq 0

@echo ' • Scoping is a bit different (1/2) - not "inline" evaluated, but in another context; no lispy macros unfortunately.'
# Though `--no-scope-shadowing` works wonders for reading & setting local variables, creating in the correct (calling) local-variable-context in impossible ...
# ... you'll have to use the `begin; builtin-that-sets ...; echo; end` syntax "template" for that (with an `>&2` after the echo for stderr).

set --local _a_variable A
@test '`⃨-nl(-err)` local scope-inspecting (1/3)' (set --show --long _a_variable | string collect) = \$_a_variable:\ set\ in\ local\ scope,\ unexported,\ with\ 1\ elements\n\$_a_variable\[1\]:\ \|A\|
@test '`⃨-nl(-err)` local scope-inspecting (2/3)' (ftutil-eval-nl set --show --long _a_variable | string collect) = \$_a_variable:\ set\ in\ local\ scope,\ unexported,\ with\ 1\ elements\n\$_a_variable\[1\]:\ \|A\|
@test '`⃨-nl(-err)` local scope-inspecting (3/3)' (ftutil-eval-nl-err set --show --long _a_variable 2>/dev/null | string collect) = \$_a_variable:\ set\ in\ local\ scope,\ unexported,\ with\ 1\ elements\n\$_a_variable\[1\]:\ \|A\|

@echo ' • Scoping is a bit different (2/2) - multiple shadowed local scopes can exist, but not inspected via `set --show` (fish limitation)'
begin
    set --local _b_variable b1
    function _test --no-scope-shadowing
        set --local _b_variable b2
        begin
            set --local _b_variable b3
            @test '`⃨-nl(-err)` multiple local scopes (1/9) - erase' $_b_variable = b3
            @test '`⃨-nl(-err)` multiple local scopes (2/9) - erase' (ftutil-eval-nl set --erase --long _b_variable | string collect) = ''
            @test '`⃨-nl(-err)` multiple local scopes (3/9) - erase' (set --show --long _b_variable | string collect) = '$_b_variable: set in local scope, unexported, with 1 elements
$_b_variable[1]: |b2|'
            @test '`⃨-nl(-err)` multiple local scopes (4/9) - set' (ftutil-eval-nl set _b_variable X >/dev/null) $status -eq 0
            @test '`⃨-nl(-err)` multiple local scopes (5/9) - set' (set --show --long _b_variable | string collect) = '$_b_variable: set in local scope, unexported, with 1 elements
$_b_variable[1]: |X|'
            @test '`⃨-nl(-err)` multiple local scopes (6/9) - show' (ftutil-eval-nl set --show --long _b_variable | string collect) = '$_b_variable: set in local scope, unexported, with 1 elements
$_b_variable[1]: |X|'
            @test '`⃨-nl(-err)` multiple local scopes (7/9) - create local, does not (usefully)' (ftutil-eval-nl set --local _b_variable NOT_VISIBLE | string collect) = ''
            @test '`⃨-nl(-err)` multiple local scopes (8/9) - create local, does not (usefully)' (set --show --long _b_variable | string collect) = '$_b_variable: set in local scope, unexported, with 1 elements
$_b_variable[1]: |X|'
        end
    end
    _test
    @test '`⃨-nl(-err)` multiple local scopes (9/9) - outer scope unaffected' (set --show --long _b_variable | string collect) = '$_b_variable: set in local scope, unexported, with 1 elements
$_b_variable[1]: |b1|'
end

@echo ' • Short command'
@test 'short command (1/10)' (functions --query en) $status -eq 1
@test 'short command (2/10)' (functions --query ene) $status -eq 1
set --local _short_cmd_1_out_and_err_output $_tmp_dir/out1
ftutil-eval-nl --short-cmd 2>&1 >$_short_cmd_1_out_and_err_output
set --local _short_cmd_1_status $status
set --local _short_cmd_2_out_and_err_output $_tmp_dir/out2
ftutil-eval-nl-err --short-cmd 2>&1 >$_short_cmd_2_out_and_err_output
set --local _short_cmd_2_status $status
@test 'short command (3/10)' $_short_cmd_1_status -eq 0
@test 'short command (4/10)' $_short_cmd_2_status -eq 0
@test 'short command (5/10)' (begin; cat "$_short_cmd_1_out_and_err_output"; echo -n x; end | string collect --no-trim-newlines) = x
@test 'short command (6/10)' (begin; cat "$_short_cmd_2_out_and_err_output"; echo -n x; end | string collect --no-trim-newlines) = x
@test 'short command (7/10)' (functions --query en) $status -eq 0
@test 'short command (8/10)' (functions --query ene) $status -eq 0
@test 'short command (9/10)' (en echo hello | string collect) = hello
@test 'short command (10/10)' (ene echo-err hello 2>&1 >/dev/null | string collect) = hello
