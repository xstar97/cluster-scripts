#!/bin/bash

# Set the base path for the cluster
BASE_PATH="$PWD"
yaml_file="$BASE_PATH/clusters/main/talos/talconfig.yaml"

# Generic function to update a CLI tool
update_cli_tool() {
    local cli_tool=$1
    local version=$2
    local download_url=$3

    echo "Updating $cli_tool to version $version..."

    # Extract the filename from the URL
    filename=$(basename "$download_url")

    # Download the file
    curl -LO "$download_url"
    if [[ $? -ne 0 ]]; then
        echo "Error downloading $cli_tool from $download_url"
        exit 1
    fi

    if [[ ! -f "$filename" ]]; then
        echo "Download failed or filename mismatch: $filename not found"
        exit 1
    fi

    # Make it executable and move it to /usr/local/bin
    chmod +x "$filename"
    sudo mv "$filename" /usr/local/bin/"$cli_tool"

    echo "$cli_tool updated to version $version"
}

# Get installed talosctl version
get_installed_talosctl_version() {
    talosctl version --short 2>/dev/null | awk '/^Talos / {print $2}'
}

# Get installed kubectl version
get_installed_kubectl_version() {
    kubectl version --client --client 2>/dev/null | awk -F ": " '/Client Version/ {print $2}' | tr -d '"' | tr -d '[:space:]'
}

# Update talosctl
update_talosctl() {
    talos_version=$(grep '^talosVersion:' "$yaml_file" | awk '{print $2}' | tr -d '"' | tr -d '[:space:]')
    [[ -z "$talos_version" ]] && { echo "Error: Talos version not found in $yaml_file"; exit 1; }

    echo "Talos version from config: $talos_version"

    installed_version=$(get_installed_talosctl_version)
    [[ -z "$installed_version" ]] && { echo "Error: Installed talosctl version not found"; exit 1; }

    echo "Installed talosctl version: $installed_version"

    if [[ "$talos_version" == "$installed_version" ]]; then
        echo "talosctl is up-to-date."
        exit 0
    fi

    download_url="https://github.com/siderolabs/talos/releases/download/$talos_version/talosctl-linux-amd64"
    update_cli_tool "talosctl" "$talos_version" "$download_url"
}

# Update kubectl
update_kubectl() {
    kubernetes_version=$(grep '^kubernetesVersion:' "$yaml_file" | awk '{print $2}' | tr -d '"' | tr -d '[:space:]')
    [[ -z "$kubernetes_version" ]] && { echo "Error: Kubernetes version not found in $yaml_file"; exit 1; }

    echo "Kubernetes version from config: $kubernetes_version"

    installed_version=$(get_installed_kubectl_version)
    [[ -z "$installed_version" ]] && { echo "Error: Installed kubectl version not found"; exit 1; }

    echo "Installed kubectl version: $installed_version"

    if [[ "$kubernetes_version" == "$installed_version" ]]; then
        echo "kubectl is up-to-date."
        exit 0
    fi

    download_url="https://dl.k8s.io/release/$kubernetes_version/bin/linux/amd64/kubectl"
    update_cli_tool "kubectl" "$kubernetes_version" "$download_url"
}

# Main handler
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [--kubectl | --talosctl]"
        exit 1
    fi

    case "$1" in
        --kubectl)
            update_kubectl
            ;;
        --talosctl)
            update_talosctl
            ;;
        *)
            echo "Invalid option: $1. Use --kubectl or --talosctl."
            exit 1
            ;;
    esac
}

main "$@"
