# Description: Get pod descriptions and logs for all pods in a namespace.
# Example: chart_get_pods [--save /path/to/dir] [--skip-pods "pod1-* pod2-*"] <namespace>
function chart_get_pods
    check_command "kubectl"

    set save_dir ""
    set skip_pattern "volsync-*"
    set namespace ""

    # Parse flags
    for i in (seq 1 (count $argv))
        if test $argv[$i] = "--save"
            set save_dir $argv[(math $i + 1)]
        else if test $argv[$i] = "--skip-pods"
            set skip_pattern $argv[(math $i + 1)]
        end
    end

    # The last argument is assumed to be the namespace
    set namespace $argv[(count $argv)]

    # Ensure namespace is provided
    if test -z "$namespace"
        echo "Error: Namespace must be provided as the last argument."
        echo "Usage: chart_get_pods [--save /path/to/dir] [--skip-pods <pattern>] <namespace>"
        return 1
    end

    # Ensure pod names are handled correctly
    set pods (kubectl get pods -n $namespace -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')

    # Skip pods matching the skip pattern
    set filtered_pods
    for pod in $pods
        if not string match -q -- "$skip_pattern" "$pod"
            set filtered_pods $filtered_pods $pod
        end
    end

    # Set save directory if needed
    if test -n "$save_dir"
        set namespace_dir "$save_dir/$namespace"
        mkdir -p "$namespace_dir"
    end

    for pod in $filtered_pods
        if test -n "$save_dir"
            set pod_desc_file "$namespace_dir/$pod-description.txt"
            echo "Saving pod description to $pod_desc_file"
            kubectl describe pod $pod -n $namespace > $pod_desc_file 2>&1

            # Get container names
            set containers (kubectl get pod $pod -n $namespace -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n')

            for container in $containers
                set pod_logs_file "$namespace_dir/$pod-$container-logs.txt"
                echo "Saving logs to $pod_logs_file"
                kubectl logs $pod -n $namespace -c $container > $pod_logs_file 2>&1
            end
        else
            # Print output to shell if no --save option
            echo "============================="
            echo "Pod: $pod"
            echo "============================="
            echo "--- Pod Description ---"
            kubectl describe pod $pod -n $namespace

            set containers (kubectl get pod $pod -n $namespace -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n')
            for container in $containers
                echo "--- Logs for Container: $container ---"
                kubectl logs $pod -n $namespace -c $container
                echo "-------------------------"
            end
            echo "========================================"
        end
    end
end
