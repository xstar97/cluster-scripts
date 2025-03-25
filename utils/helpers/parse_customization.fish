# Description: checks kustomization files for missing paths
# Example: parse_kustomization
function parse_kustomization
    set search_path "$BASE_PATH/clusters/main/kubernetes"
    set -l files (find $search_path -type f \( -name 'kustomization.yaml' -o -name 'ks.yaml' \))
    set -l error 0
    set -l missing_paths
    
    for file in $files
        echo "Processing: $file"
        
        set -l paths (grep -A 5 'spec:' $file | grep 'path:' | awk '{print $2}')
        
        for path in $paths
            if test -d $path
                echo "✅ Exists: $path"
            else
                echo "❌ Missing: $path"
                set missing_paths $missing_paths $path
                set error (math $error + 1)
            end
        end
    end
    
    if test $error -gt 0
        echo "Summary:"
        echo "❌ Total missing paths: $error"
        for missing in $missing_paths
            echo "  - $missing"
        end
    else
        echo "✅ All paths exist."
    end
    
    return $error
end
