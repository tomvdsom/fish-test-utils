@echo '=== ftutil-log-args(-err) ==='
source (dirname (status dirname))"/functions/_ftutil-log-args.fish" # No indirect autoloading too.
source (dirname (status dirname))"/functions/ftutil-log-args.fish"
source (dirname (status dirname))"/functions/ftutil-log-args-err.fish"

set --global _tmp_dir (mktemp -d)

# Cleanup
function _ftutil_log_args_and_err_test_cleanup --on-event fish_exit
    rm -r $_tmp_dir
end

#
# Tests
@test empty (ftutil-log-args | string collect --no-trim-newlines) = \n
@test '1 arg' (ftutil-log-args one | string collect --no-trim-newlines) = one\n
@test 'logs to stdout, nothing to stderr' (begin; ftutil-log-args one 2>&1 >/dev/null; echo -n x; end | string collect --no-trim-newlines) = x
@test 'N arg' (ftutil-log-args one two three | string collect) = one\ two\ three
@test 'whitespace & newlines' (ftutil-log-args o\ n\ e t\nwo \tthree | string collect) = 'o_20_n_20_e t_0A_wo _09_three'
@test 'empty args (1/2) - as an arg' (ftutil-log-args '' | string collect) = "''"
@test 'empty args (2/2) - in between' (ftutil-log-args be '' tween | string collect) = "be '' tween"
@test 'two-single-quotes (1/2) - as an arg' (ftutil-log-args \'\') = _27_27_
@test 'two-single-quotes (1/2) - in between' (ftutil-log-args one \'\' three) = 'one _27_27_ three'
@test 'newline (1/2) - as arg' (ftutil-log-args \n) = _0A_
@test 'newline (2/2) - in between' (ftutil-log-args one \n three) = "one _0A_ three"
set --local expected (ftutil-log-args one '' \n f\ o\ u\ r figh\t | string collect --no-trim-newlines)
@test 'ftutil-log-args-err same behaviour as ftutil-log-args, but to stderr (1/2)' $expected = "one '' _0A_ f_20_o_20_u_20_r figh_09_"\n
@test 'ftutil-log-args-err same behaviour as ftutil-log-args, but to stderr (2/2)' (ftutil-log-args-err one '' \n f\ o\ u\ r figh\t 2>&1 >/dev/null | string collect --no-trim-newlines) = $expected

@echo ' • Short command'
@test 'short command (1/10)' (functions --query log-args) $status -eq 1
@test 'short command (2/10)' (functions --query log-args-err) $status -eq 1
set --local _short_cmd_1_out_and_err_output $_tmp_dir/out1
ftutil-log-args --short-cmd 2>&1 >$_short_cmd_1_out_and_err_output
set --local _short_cmd_1_status $status
set --local _short_cmd_2_out_and_err_output $_tmp_dir/out2
ftutil-log-args-err --short-cmd 2>&1 >$_short_cmd_2_out_and_err_output
set --local _short_cmd_2_status $status
@test 'short command (3/10)' $_short_cmd_1_status -eq 0
@test 'short command (4/10)' $_short_cmd_2_status -eq 0
@test 'short command (5/10)' (begin; cat "$_short_cmd_1_out_and_err_output"; echo -n x; end | string collect --no-trim-newlines) = x
@test 'short command (6/10)' (begin; cat "$_short_cmd_2_out_and_err_output"; echo -n x; end | string collect --no-trim-newlines) = x
@test 'short command (7/10)' (functions --query log-args) $status -eq 0
@test 'short command (8/10)' (functions --query log-args-err) $status -eq 0
set --local expected "lo_20_g '' me_0A_ _21_"
@test 'short command (9/10)' (log-args lo\ g '' me\n \! | string collect) = $expected
@test 'short command (10/10)' (log-args-err lo\ g '' me\n \! 2>&1 >/dev/null | string collect) = $expected
