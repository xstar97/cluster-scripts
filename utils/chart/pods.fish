# Description: access pods shell or logs
# Example: pods [chart]
function pods
    check_command "kubectl"
    set script_dir (dirname (status --current-filename))  # Get the directory of the current script
    $script_dir/utils/chart/pods.sh $argv  # Source the pods.sh script from the same directory
end
