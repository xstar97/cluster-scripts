# utils/gen_alias.fish

function gen_alias
    # Default YAML file path
    set yaml_file "$PWD/scripts/aliases.yaml"

    # Parse options
    for arg in $argv
        switch $arg
            case '--config'
                set yaml_file (string split '=' $argv[2]) # Fetch the config file path from the flag
                break
            case '*'
                # Handle other flags or arguments if necessary
                break
        end
    end

    check_command "yq"

    # Check if yq (YAML processor) is installed
    if not command -q yq
        echo "Error: 'yq' is required to parse YAML. Install it using 'brew install yq' or 'sudo apt install yq'"
        exit 1
    end

    # Read the YAML file and set aliases
    for key in (yq eval '.aliases | keys | .[]' $yaml_file)
        set value (yq eval ".aliases[\"$key\"]" $yaml_file)
        alias $key "$value" --save
    end

    echo "Aliases set, verify."

    alias
end
