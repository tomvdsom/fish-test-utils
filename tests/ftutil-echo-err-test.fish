@echo '=== ftutil-echo-err ==='
source (dirname (status dirname))"/functions/ftutil-echo-err.fish"

set --global _tmp_dir (mktemp -d)

# Cleanup
function _ftutil_echo_err_test_cleanup --on-event fish_exit
    rm -r $_tmp_dir
end

#
# Tests
@test 'Not to stdout (1/2' (begin; echo -n x; ftutil-echo-err; echo -n x; end | string collect --no-trim-newlines) = xx
@test 'Not to stdout (2/2)' (begin; echo -n x; ftutil-echo-err; echo -n x; end 2>&1 >/dev/null | string collect --no-trim-newlines) = \n
@test 'To stderr (1/2)' (ftutil-echo-err hi 2>&1 | string collect --no-trim-newlines) = hi\n
@test 'To stderr (2/2)' (begin; echo -n x; ftutil-echo-err hi; echo -n x; end 2>/dev/null | string collect --no-trim-newlines) = xx
@test 'Echo args passed through' (ftutil-echo-err -en 'x\n\t\\x' 2>&1 | string collect) = x\n\t\\x

@test 'short command (1/5)' (functions --query echo-err) $status -eq 1
set --local _short_cmd_out_and_err_output $_tmp_dir/out
ftutil-echo-err --short-cmd 2>&1 >$_short_cmd_out_and_err_output
set --local _short_cmd_status $status
@test 'short command (2/5)' $_short_cmd_status -eq 0
@test 'short command (3/5)' (begin; cat "$_short_cmd_out_and_err_output"; echo -n x; end | string collect --no-trim-newlines) = x
@test 'short command (4/5)' (functions --query echo-err) $status -eq 0
@test 'short command (5/5)' (echo-err hello 2>&1 >/dev/null | string collect) = hello
