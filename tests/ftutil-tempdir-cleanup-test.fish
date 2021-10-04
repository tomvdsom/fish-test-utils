@echo === ftutil-tempdir ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-tempdir.fish"
source (dirname (status dirname))"/functions/ftutil-tempdir-cleanup.fish"

set --local _tempdir_1 (ftutil-tempdir)
set --local _tempdir_2 (ftutil-tempdir)

@test "Cleaning up before fish_exit event (1/2)" (test -d $_tempdir_1; and test -d $_tempdir_2) $status -eq 0
ftutil-tempdir-cleanup
@test "Cleaning up before fish_exit event (2/2)" (test ! -e $_tempdir_1; and test ! -e $_tempdir_2) $status -eq 0
