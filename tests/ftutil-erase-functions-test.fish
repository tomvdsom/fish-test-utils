@echo === ftutil-erase-functions ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-erase-functions.fish"

# Cleanup
set --global _tmpdir (mktemp -d)
function _ftutil-erase-functions-test_fn-cleanup --on-event fish_exit
    rm -r "$_tmpdir"
end

#
# Tests
function begone-ye-annoying-function-here
end

@test "A function to remove exists" (functions --query begone-ye-annoying-function-here) $status -eq 0
set --local nr_of_public_fns (count (functions))
ftutil-erase-functions begone-ye-annoying-function-here
@test "A function is removed (1/2)" (functions --query begone-ye-annoying-function-here) $status -eq 1
@test "A function is removed (2/2)" (math $nr_of_public_fns - (count (functions))) -eq 1

function begone-ye-annoying-function-one
end
function begone-ye-annoying-function-two
end
set --local nr_of_public_fns (count (functions))

ftutil-erase-functions '^begone-.*-annoying-function-.*$'
@test "Regex match remove functions" (math $nr_of_public_fns - (count (functions))) -eq 2

function begone-ye-annoying-function-one
end
function begone-ye-annoying-function-two
end
function begone-ye-very-annoying-function-three
end
function begone-yo-fn-x
end
set --local nr_of_public_fns (count (functions))

ftutil-erase-functions 'begone-ye-annoying-.*' 'begone-ye-very-annoying-.*'
@test "Multiple regexes remove functions" (math $nr_of_public_fns - (count (functions))) -eq 3
ftutil-erase-functions begone-yo-fn-x
@test "Previous erase didn't erase yo'fn" (math $nr_of_public_fns - (count (functions))) -eq 4

set --local nr_of_all_fns (count (functions --all))
echo 'function begone-ye-annoying-function-one
end
function _begone-ye-annoying-fn-helper
end' >"$_tmpdir/b-y-a-£-🕐️.fish"
echo 'function begone-ye-annoying-function-two
end' >"$_tmpdir/begone-ye-annoying-function-two.fish"
source "$_tmpdir/b-y-a-£-🕐️.fish"
source "$_tmpdir/begone-ye-annoying-function-two.fish"

@test "Functions sourced succesfully from file (1/4)" (math (count (functions --all)) - $nr_of_all_fns) -eq 3
@test "Functions sourced succesfully from file (2/4)" (functions --query begone-ye-annoying-function-one) $status -eq 0
@test "Functions sourced succesfully from file (3/4)" (functions --query begone-ye-annoying-function-two) $status -eq 0
@test "Functions sourced succesfully from file (4/4)" (functions --query _begone-ye-annoying-fn-helper) $status -eq 0

ftutil-erase-functions '_*begone-ye.*'
@test "And sourced functions erased again" (math (count (functions --all)) - $nr_of_all_fns) -eq 0

source "$_tmpdir/b-y-a-£-🕐️.fish"
source "$_tmpdir/begone-ye-annoying-function-two.fish"
@test "Functions sourced succesfully from file again" (math (count (functions --all)) - $nr_of_all_fns) -eq 3
# Test assumes functions --all output is always sorted
@test "Re-source-able functions output when --save-origin flag given (1/2)" (ftutil-erase-functions --save-origin '_*begone-ye.*') = "$_tmpdir/b-y-a-£-🕐️.fish $_tmpdir/begone-ye-annoying-function-two.fish"
@test "Re-source-able functions output when --save-origin flag given (2/2)" (math (count (functions --all)) - $nr_of_all_fns) -eq 0

echo 'function begone-ye-annoying-function-four
end' >"$_tmpdir/begone ye annoying function\tfour.fish"
@test "A function with whitespace (_no_ newline) in the function filename (1/4)" (functions --query begone-ye-annoying-function-four) $status -eq 1
source "$_tmpdir/begone ye annoying function\tfour.fish"
@test "A function with whitespace (_no_ newline) in the function filename (2/4)" (functions --query begone-ye-annoying-function-four) $status -eq 0
@test "A function with whitespace (_no_ newline) in the function filename (3/4)" (ftutil-erase-functions -s begone-ye-annoying-function-four) = "$_tmpdir/begone ye annoying function\tfour.fish"
@test "A function with whitespace (_no_ newline) in the function filename (4/4)" (functions --query begone-ye-annoying-function-four) $status -eq 1
