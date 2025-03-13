# Description: Finds dupe volsync secrets
# Example: find_volsync_dupes
function find_volsync_dupes
    echo "...searching for volsync secrets..."
    set -l secrets (kubectl get secrets -A | awk '$2 ~ /-volsync/ {print $1, $2}')
    set -l seen
    set -l duplicates

    for line in $secrets
        set -l namespace (echo $line | awk '{print $1}')
        set -l pvc (echo $line | awk '{print $2}' | sed 's/-volsync.*//')
        set -l key "$namespace $pvc"

        echo "Found volsync secret: $namespace $pvc"

        if contains -- "$key" $seen
            set duplicates $duplicates "$key"
        else
            set seen $seen "$key"
        end
    end

    echo ""
    if test (count $duplicates) -gt 0
        echo "Duplicates found:"
        for item in $duplicates
            echo $item
        end
    else
        echo "No duplicates found."
    end
end
