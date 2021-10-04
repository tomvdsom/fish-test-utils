@echo === ftutil-fn-var-cleanup-and-restore ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-erase-functions.fish" # No autoloading
source (dirname (status dirname))"/functions/ftutil-erase-variables.fish" # No autoloading
source (dirname (status dirname))"/functions/ftutil-set-variables.fish" # No autoloading
source (dirname (status dirname))"/functions/ftutil-fn-var-cleanup.fish"
source (dirname (status dirname))"/functions/ftutil-fn-var-cleanup-restore.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl-err.fish"

ftutil-eval-nl --short-cmd
ftutil-eval-nl-err --short-cmd
set --global _tmpdir (mktemp -d)
set --local _out_and_err_output $_tmpdir/out

# Cleanup
function _ftutil_fn_var_cleanup_and_restore_test_cleanup --on-event fish_exit
    set --erase --universal _ftutil_fn_var_cleanup_and_restore_test_a_variable _ftutil_fn_var_cleanup_and_restore_test_b_variable _ftutil_fn_var_cleanup_and_restore_test_c_variable
    rm -r $_tmpdir
end

#
# Tests
@echo ' • basics'
function be-gone
end
set --local _a_variable X
set --local _b_variable B
set --global _b_variable B2
set --local _ftutil_fn_var_cleanup_and_restore_test_a_variable nL
set --global _ftutil_fn_var_cleanup_and_restore_test_a_variable nG
set --universal _ftutil_fn_var_cleanup_and_restore_test_a_variable nU 2 3
set --universal _ftutil_fn_var_cleanup_and_restore_test_b_variable nUB
set --universal _ftutil_fn_var_cleanup_and_restore_test_c_variable do_not_erase

@test 'Cleanup (fns and vars) and restore (universal vars erased) (1/14)' (functions --query be-gone) $status -eq 0
@test 'Cleanup (fns and vars) and restore (universal vars erased) (2/14)' (set --query _a_variable _b_variable _ftutil_fn_var_cleanup_and_restore_test_a_variable _ftutil_fn_var_cleanup_and_restore_test_b_variable) $status -eq 0
@test 'Cleanup (fns and vars) and restore (universal vars erased) (3/14)' $_ftutil_fn_var_cleanup_and_restore_test_c_variable = do_not_erase

ftutil-fn-var-cleanup '^_._variable$' '^_ftutil_fn_var_cleanup_and_restore_test_[ab]_variable$' be-gone 2>&1 >$_out_and_err_output
@test 'Cleanup (fns and vars) and restore (universal vars erased) (4/14)' $status -eq 0
@test 'Cleanup (fns and vars) and restore (universal vars erased) (5/14)' (en cat $_out_and_err_output | string collect) = ''
@test 'Cleanup (fns and vars) and restore (universal vars erased) (6/14)' (functions --query be-gone) $status -eq 1
@test 'Cleanup (fns and vars) and restore (universal vars erased) (7/14)' (set --query _a_variable _b_variable _ftutil_fn_var_cleanup_and_restore_test_a_variable _ftutil_fn_var_cleanup_and_restore_test_b_variable) $status -eq 4
@test 'Cleanup (fns and vars) and restore (universal vars erased) (8/14)' $_ftutil_fn_var_cleanup_and_restore_test_c_variable = do_not_erase

ftutil-fn-var-cleanup-restore 2>&1 >$_out_and_err_output
@test 'Cleanup (fns and vars) and restore (universal vars erased) (9/14)' $status -eq 0
@test 'Cleanup (fns and vars) and restore (universal vars erased) (10/14)' (en cat $_out_and_err_output | string collect) = ''
@test 'Cleanup (fns and vars) and restore (universal vars erased) (11/14)' (functions --query be-gone) $status -eq 1
@test 'Cleanup (fns and vars) and restore (universal vars erased) (12/14)' (set --query _a_variable _b_variable _ftutil_fn_var_cleanup_and_restore_test_a_variable _ftutil_fn_var_cleanup_and_restore_test_b_variable) $status -eq 2
@test 'Cleanup (fns and vars) and restore (universal vars erased) (13/14)' (set --show --long _a_variable _b_variable _ftutil_fn_var_cleanup_and_restore_test_a_variable _ftutil_fn_var_cleanup_and_restore_test_b_variable | string collect) = '$_ftutil_fn_var_cleanup_and_restore_test_a_variable: set in universal scope, unexported, with 3 elements
$_ftutil_fn_var_cleanup_and_restore_test_a_variable[1]: |nU|
$_ftutil_fn_var_cleanup_and_restore_test_a_variable[2]: |2|
$_ftutil_fn_var_cleanup_and_restore_test_a_variable[3]: |3|
$_ftutil_fn_var_cleanup_and_restore_test_b_variable: set in universal scope, unexported, with 1 elements
$_ftutil_fn_var_cleanup_and_restore_test_b_variable[1]: |nUB|'
@test 'Cleanup (fns and vars) and restore (universal vars erased) (14/14)' $_ftutil_fn_var_cleanup_and_restore_test_c_variable = do_not_erase

ftutil-fn-var-cleanup-restore 2>&1 >$_out_and_err_output
@test 'Cleanup without cleanup gives nonzero exit status (1/2)' $status -eq 1
@test 'Cleanup without cleanup gives nonzero exit status (2/2)' (en cat $_out_and_err_output | string collect) = ''

# TODO more tests
