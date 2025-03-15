# Description: access pods shell or logs
# Example: pods [chart]
function pods
    # Check if kubectl is installed
    check_command "kubectl"
    
    # Get the current script's directory
    set script_dir (dirname (status --current-filename))

    # Source the pods.sh script from the utils/chart directory
    "$script_dir/utils/chart/pods.sh" $argv
end
