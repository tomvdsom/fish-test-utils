function ftutil-log-args-err
    if test (count $argv) -eq 1
        and test $argv[1] = --short-cmd
        function log-args-err --description 'Short command for `ftutil-log-args-err`.'
            _ftutil-log-args $argv >&2
        end
        return 0
    end
    _ftutil-log-args $argv >&2
end
