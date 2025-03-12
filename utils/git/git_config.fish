# Description: Sets the user and email for git if the variables are set in clusterenv.yaml
# Example: git_config
function git_config

    # Check if required commands are installed
    check_command "yq"
    check_command "git"

    # Check if CONFIG is encrypted and extract values accordingly
    set GITHUB_USER (extract_clusterenv_key --key "GITHUB_USER")
    set GITHUB_EMAIL (extract_clusterenv_key --key "GITHUB_EMAIL")

    # Check if the values are empty
    if test -z "$GITHUB_USER" -o -z "$GITHUB_EMAIL"
        echo "Error: GitHub username or email is missing in the YAML file!"
        exit 1
    end

    # Echo the values to confirm
    echo "Setting Git username to: $GITHUB_USER"
    echo "Setting Git email to: $GITHUB_EMAIL"

    # Set the Git username and email globally
    git config --global user.name "$GITHUB_USER"
    git config --global user.email "$GITHUB_EMAIL"

    echo "Git username and email have been set successfully!"
end
