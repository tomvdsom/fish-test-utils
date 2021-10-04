@echo === ftutil-tempdir ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-tempdir.fish"

set --global _tmp_dir (mktemp -d)

# Cleanup
function _ftutil_tempdir_test_cleanup --on-event fish_exit
    rmdir $_tmp_dir
end

#
# Tests
set --local --export _tmp_basedir (dirname $_tmp_dir)
set --local _tempdir_1 (ftutil-tempdir)
@test "Creates a tempdir, in the correct system basedir (1/2)" (dirname $_tempdir_1) = $_tmp_basedir
@test "Creates a tempdir, in the correct system basedir (2/2)" -d $_tempdir_1
@test "Tempdir is a fullpath (1/2)" (string match '/*' -- $_tempdir_1 >/dev/null) $status -eq 0
pushd $_tempdir_1
@test "Tempdir is a fullpath (2/2)" (pwd) = $_tempdir_1
popd
@test "No 2 tempdirs are the same (1/2)" (set _tempdir_2 (ftutil-tempdir)) $_tempdir_2 != $_tempdir_1
@test "No 2 tempdirs are the same (2/2)" (set _tempdir_3 (ftutil-tempdir)) (test $_tempdir_3 != $_tempdir_2; and test $_tempdir_3 != $_tempdir_1) $status -eq 0
@test "Cleanup on fish_exit (1/2)" (fish -c 'set --universal _ftutil_tempdir_test_tmpdir_cleanup (ftutil-tempdir); and test -d $_ftutil_tempdir_test_tmpdir_cleanup; and test (dirname $_ftutil_tempdir_test_tmpdir_cleanup) = $_tmp_basedir; and echo "OK"') = OK
@test "Cleanup on fish_exit (2/2)" ! -e $_ftutil_tempdir_test_tmpdir_cleanup
@test "Cleanup removes all (glob-matching) tempdirs, so mainly useful for unittests (1/2)" (test ! -e $_tempdir_1; and test ! -e $_tempdir_2; and test ! -e $_tempdir_3) $status -eq 0
@test "Cleanup removes all (glob-matching) tempdirs, so mainly useful for unittests (2/2)" -d $_tmp_dir
