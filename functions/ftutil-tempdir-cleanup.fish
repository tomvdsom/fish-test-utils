function ftutil-tempdir-cleanup --description "Explicity cleaning up after ftutil-tempdir (not required, happens automatically on fish exit - and only when needed)"
    if functions --query _fish_test_utils_tempdir_ensure_cleanup
        _fish_test_utils_tempdir_ensure_cleanup
        functions --erase _fish_test_utils_tempdir_ensure_cleanup
        return 0
    end
    return 1
end
