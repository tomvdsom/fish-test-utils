# `mktemp -t ...` templating is not as cross-platform as you would hope.  OSX Ignores the X's, and Linux refuses a template without X's...
set --global fish_test_utils_tempdir_mktemp_template fish_test_utils_tempdir_XXXXXXXXXXXX

# side-effect to determine the system temp dir for mktemp.
set --local _temp (mktemp -d -t $fish_test_utils_tempdir_mktemp_template)
set --global fish_test_utils_tempdir_mktemp_paths_glob ""(dirname $_temp)"/"(string replace --all X '' -- $fish_test_utils_tempdir_mktemp_template)"*"
rmdir $_temp

function ftutil-tempdir --description "Like `mktemp -d`, but with cleanup on fish exit."
    if not functions --query _fish_test_utils_tempdir_ensure_cleanup
        function _fish_test_utils_tempdir_ensure_cleanup --description "Internal cleanup function: using ftutil-tempdir mktemp template, on fish_exit." --on-event fish_exit
            if eval count $fish_test_utils_tempdir_mktemp_paths_glob >/dev/null
                # there must be 1...n matches, or globbing fails (noise), see: https://fishshell.com/docs/current/language.html#wildcards-globbing
                eval rm -rf $fish_test_utils_tempdir_mktemp_paths_glob
            end
        end
    end

    mktemp -d -t $fish_test_utils_tempdir_mktemp_template
    return $status
end
