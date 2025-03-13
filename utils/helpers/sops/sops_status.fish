# Description: Checks if the file is encrypted or not. 
# Example: sops_status /path/to/fie
function sops_status
    set file "$argv[1]"
    if test -z "$file"
        echo "Usage: sops_status <file>" >&2
        return 1
    end

    set sops_status (sops filestatus "$file" | jq -r .encrypted)
    echo $sops_status
end
