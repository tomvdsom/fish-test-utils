function ftutil-fn-var-cleanup-restore
    if functions --query _ftutil-fn-var-cleanup_ensure-cleanup
        _ftutil-fn-var-cleanup_ensure-cleanup
        functions --erase _ftutil-fn-var-cleanup_ensure-cleanup
        return 0
    end
    return 1
end
