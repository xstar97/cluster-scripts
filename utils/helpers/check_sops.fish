# Description: Checks if the file is encrypted or not. 
# Example: check_sops /path/to/fie
function check_sops
    set file "$argv[1]"
    if test -z "$file"
        echo "Usage: check_sops <file>" >&2
        return 1
    end

    set sops_status (sops filestatus "$file" | jq -r .encrypted)
    echo $sops_status
end
