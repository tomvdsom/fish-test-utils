@echo === ftutil-source-files ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-source-files.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl-err.fish"

ftutil-eval-nl --short-cmd
ftutil-eval-nl-err --short-cmd
set --global _tmpdir (mktemp -d)

# Cleanup
function _ftutil-source-files-test_fn-cleanup --on-event fish_exit
    rm -r "$_tmpdir"
end

#
# Tests
@test 'No sources, no sourcing' (en ftutil-source-files | string collect) = ''

set --local src_file_1 "$_tmpdir/file1.fish"
echo 'echo "Sourcy?"' >"$src_file_1"
@test '1 file given, 1 sourced' (en ftutil-source-files "$src_file_1" | string collect) = 'Sourcy?'

set --local src_file_2 "$_tmpdir/file2"
echo "echo 'Filey!'" >"$src_file_2"
@test 'More files, more sourced - in given order' (en ftutil-source-files $src_file_1 $src_file_2 | string collect) = "Sourcy?
Filey!"

set --local src_file_3 "$_tmpdir/file3 with spaces.fish"
echo "echo 'Spacey...'" >"$src_file_3"
@test 'File with spaces' (en ftutil-source-files $src_file_3 | string collect) = 'Spacey...'

@test 'Skip empty string arguments (1/4)' (en ftutil-source-files '' | string collect) = ''
@test 'Skip empty string arguments (2/4)' (ene ftutil-source-files '' 2>&1 >/dev/null | string collect) = ''
@test 'Skip empty string arguments (3a/4)' (en ftutil-source-files $src_file_1 '' $src_file_2 '' '' $src_file_3 2>/dev/null | string collect) = 'Sourcy?
Filey!
Spacey...'
# Verify helper does not change semantics (1/2 - e).
@test 'Skip empty string arguments (3b/4)' (begin; ftutil-source-files $src_file_1 '' $src_file_2 '' '' $src_file_3; echo; end 2>/dev/null | string collect) = 'Sourcy?
Filey!
Spacey...'
@test 'Skip empty string arguments (4a/4)' (ene ftutil-source-files $src_file_1 '' $src_file_2 '' '' $src_file_3 2>&1 >/dev/null | string collect) = ''
# Verify helper does not change semantics (2/2 - ee).
@test 'Skip empty string arguments (4b/4)' (begin; echo >&2 ; ftutil-source-files $src_file_1 '' $src_file_2 '' '' $src_file_3; end 2>&1 >/dev/null | string collect) = ''
@test 'Source doesn\'t like made-up paths (1a)' (ene ftutil-source-files '/this/path/surely/does/not/exist' 2>&1 >/dev/null | string collect) = 'source: Error encountered while sourcing file \'/this/path/surely/does/not/exist\':
source: No such file or directory'
# Verify helper does not change semantics (2/2), will fail horribly if no output is generated at all.
@test 'Source doesn\'t like made-up paths (1b)' (ftutil-source-files '/this/path/surely/does/not/exist' 2>&1 >/dev/null | string collect) = 'source: Error encountered while sourcing file \'/this/path/surely/does/not/exist\':
source: No such file or directory'
