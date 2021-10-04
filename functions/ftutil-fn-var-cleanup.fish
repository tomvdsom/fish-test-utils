function ftutil-fn-var-cleanup --no-scope-shadowing
    if not functions --query _ftutil-fn-var-cleanup_ensure-cleanup
        function _ftutil-fn-var-cleanup_ensure-cleanup --on-event fish_exit
            if set --query --global -- _ftutil_fn_var_cleanup_to_restore
                and test (count $_ftutil_fn_var_cleanup_to_restore) -ne 0
                echo $_ftutil_fn_var_cleanup_to_restore | ftutil-set-variables
            end
        end
    end

    ftutil-erase-functions -- $argv
    set --append --global -- _ftutil_fn_var_cleanup_to_restore (ftutil-erase-variables -- $argv | string collect)
end
