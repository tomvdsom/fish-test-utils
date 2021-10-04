function ftutil-random-string --description "Outputs a random string, currently alphanumeric and 22 chars long."
    LC_ALL=C tr -dc 0-9A-Za-z </dev/urandom | read -n 22
end
