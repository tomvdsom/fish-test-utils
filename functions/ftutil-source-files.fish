function ftutil-source-files --description "Source given files"
    for f in $argv
        switch $f
            case ''
            case '*'
                source $f
        end
    end
end
