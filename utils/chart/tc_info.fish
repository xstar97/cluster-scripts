# Description: Gets the Chart and value data for a TC helm repo chart.
# Example: tc_info plex
function tc_info
    echo "Initializing..."
    
    # Ensure necessary commands are available
    check_command "yq"
    check_command "helm"

    if test (count $argv) -lt 1
        echo "Error: Chart name is required."
        echo "Usage: tc_info <chart_name> [--repo <repo_url>] [--values]"
        return 1
    end

    set chart_name $argv[1]
    set repo_url "oci://tccr.io/truecharts"  # Default repo URL
    set show_values 0  # Default to not show values

    # Parse arguments
    for arg in $argv[2..-1]  # Skip the chart_name argument
        switch $arg
            case "--repo"
                echo "Custom repository URL detected..."
                set repo_url $argv[(math (count $argv) - 1)]
            case "--values"
                echo "Values flag detected, will display chart values..."
                set show_values 1
            case "--help"
                echo "Displaying help information..."
                echo "Usage: tc_info <chart_name> [--repo <repo_url>] [--values]"
                echo "Options:"
                echo "  --repo <repo_url>  The repository URL (defaults to oci://tccr.io/truecharts)"
                echo "  --values           Show the default values of the chart"
                return 0
            case '*'
                echo "Error: Unknown option '$arg'"
                echo "Usage: tc_info <chart_name> [--repo <repo_url>] [--values]"
                return 1
        end
    end

    # Fetch chart details
    echo "Fetching chart details for '$chart_name' from repository '$repo_url'..."
    set chart_info (helm show chart $repo_url/$chart_name | yq -o json)

    echo "Parsing chart information..."
    set chart_name (echo $chart_info | yq '.name')
    set chart_version (echo $chart_info | yq '.version')
    set chart_description (echo $chart_info | yq '.description')
    set chart_home (echo $chart_info | yq '.home')
    set chart_sources (echo $chart_info | yq '.sources[]')

    # Display chart information
    echo "------------------------------------"
    echo "Chart Information:"
    echo "------------------------------------"
    echo "Name:          $chart_name"
    echo "Version:       $chart_version"
    echo "Description:   $chart_description"
    echo "Home:          $chart_home"
    echo "Sources:"
    
    for source in $chart_sources
        echo "  - $source"
    end

    echo "------------------------------------"

    # Show values if the flag is set
    if test $show_values -eq 1
        echo "Fetching chart values..."
        echo "Values Information:"
        echo "------------------------------------"
        helm show values $repo_url/$chart_name
        echo "------------------------------------"
    else
        echo "Skipping values display as '--values' flag was not set."
    end

end
