# Description: Get clusterenv key's value; encrypted or not.
# Example: extract_clusterenv_key --key KEY
function extract_clusterenv_key
    # Check if required commands are installed
    check_command "yq" > /dev/null 2>&1
    check_command "jq" > /dev/null 2>&1

    set CONFIG "$BASE_PATH/clusters/main/clusterenv.yaml"
    
    # Parse arguments for --key option
    for i in (seq 1 (count $argv))
        if test "$argv[$i]" = "--key"
            set CLUSTER_KEY $argv[(math $i + 1)]
        end
    end

    echo "key: $CLUSTER_KEY" > /dev/null

    # Check if the YAML file exists
    if test ! -f "$CONFIG"
        echo "Error: $CONFIG not found!" >&2
        return 1
    end

    # Check if CONFIG is encrypted and extract values accordingly
    if sops_status "$CONFIG" | grep -q "true"
        set CLUSTER_KEY_VAL (sops_extract "$CONFIG" "$CLUSTER_KEY")
    else
        set CLUSTER_KEY_VAL (yq eval ".$CLUSTER_KEY" "$CONFIG")
    end

    # Check if the extracted value is empty
    if test -z "$CLUSTER_KEY_VAL"
        echo "Error: $CLUSTER_KEY not found!" >&2
        return 1
    end

    # Return the extracted value by echoing it
    echo $CLUSTER_KEY_VAL
end
