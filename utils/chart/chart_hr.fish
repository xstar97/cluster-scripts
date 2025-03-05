# Description: Find a chart locally
# Example: chart_hr [chart]
function chart_hr
    set search_path "$BASE_PATH/clusters/main/kubernetes"
    set search_file "helm-release.yaml"
    # If no arguments are provided, list all search_file files
    if test (count $argv) -lt 1
        echo "Listing all $search_file files in $search_path"
        set matches (find "$search_path" -type f -path "*/$search_file")

        if test (count $matches) -eq 0
            echo "No $search_file files found."
            exit 1
        end

        # Display all found files
        for i in (seq (count $matches))
            echo "$matches[$i]"
        end

        return
    end

    # Handle chart name if provided
    set chart_name $argv[1]

    echo "Searching for $chart_name in: $search_path"

    # Search for search_file files in the specified path
    set matches (find "$search_path" -type f -path "*/$search_file" | grep -E "/$chart_name/")

    # Check if any matches were found
    if test (count $matches) -eq 0
        echo "No $search_file found for chart: $chart_name"
        exit 1
    end

    # List the matches
    for i in (seq (count $matches))
        echo "$matches[$i]"
    end
end
