function ftutil-log-args
    if test (count $argv) -eq 1
        and test $argv[1] = --short-cmd
        function log-args --description 'Short command for `ftutil-log-args`.'
            _ftutil-log-args $argv
        end
        return 0
    end
    _ftutil-log-args $argv
end
