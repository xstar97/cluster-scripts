# Description: Update cli tools manually.
# Example: update_cli_tools [arg]
function update_cli_tools
    check_command "kubectl"
    set script_dir (dirname (status --current-filename))  # Get the directory of the current script
    $script_dir/updateCliTools.sh $argv  # Source the pods.sh script from the same directory
end
