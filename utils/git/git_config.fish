# Description: Sets the user and email for git if the variables are set in clusterenv.yaml
# Example: git_config
function git_config
    set CONFIG "$BASE_PATH/clusters/main/clusterenv.yaml"

    # Check if required commands are installed
    check_command "yq"
    check_command "git"

    # Check if the YAML file exists
    if test ! -f "$CONFIG"
        echo "Error: $CONFIG not found!"
        exit 1
    end

    # Check if CONFIG is encrypted and extract values accordingly
    if check_sops "$CONFIG" | grep -q "true"
        echo "$CONFIG is encrypted; temp decrypting to extract github values"
        set GITHUB_USER (extract_sops "$CONFIG" "GITHUB_USER")
        set GITHUB_EMAIL (extract_sops "$CONFIG" "GITHUB_EMAIL")
    else
        echo "$CONFIG is not encrypted....extracting github values"
        set GITHUB_USER (yq eval '.GITHUB_USER' "$CONFIG")
        set GITHUB_EMAIL (yq eval '.GITHUB_EMAIL' "$CONFIG")
    end

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
