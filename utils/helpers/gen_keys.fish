# Description: Generates keys
# Example: gen_keys [--jwt] [--hex] 32
function gen_keys
    set -l type ''
    set -l length 32

    # Parse arguments
    for arg in $argv
        switch $arg
            case --jwt
                set type base64
            case --hex
                set type hex
            case '*'
                if string match -rq '^[0-9]+$' -- $arg
                    set length $arg
                else
                    echo "Unknown argument: $arg"
                    return 1
                end
        end
    end

    if test -z "$type"
        echo "Usage: gen_keys [--jwt|--hex] [length]"
        return 1
    end

    switch $type
        case base64
            openssl rand -base64 $length
        case hex
            openssl rand -hex $length
    end
end
