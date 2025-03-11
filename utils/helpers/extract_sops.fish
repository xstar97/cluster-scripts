# Description: Extracts a value from a key if its encrypted 
# Example: extract_sops /path/to/file KEY
function extract_sops
    set file "$argv[1]"
    set key "$argv[2]"
    if test -z "$file" -o -z "$key"
        echo "Usage: extract_sops <file> <key>" >&2
        return 1
    end

    if check_sops "$file" | grep -q "true"
        sops decrypt "$file" --extract "[\"$key\"]"
    else
        echo "File is not encrypted." >&2
        return 1
    end
end