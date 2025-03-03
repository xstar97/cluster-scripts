# Description: Get unique external IPs from LoadBalancer services.
# Example: load_balancer_ips [namespace]
function load_balancer_ips
    check_command "kubectl"
    
    set app_names $argv

    # Get all LoadBalancer services with external IPs
    if test (count $app_names) -eq 0
        set services (kubectl get svc -A --no-headers | awk '$3 == "LoadBalancer" && $5 != "<none>"' | sort -u)
    else
        set pattern (string join '|' $app_names)
        set services (kubectl get svc -A --no-headers | awk '$3 == "LoadBalancer" && $5 != "<none>"' | grep -E "^($pattern)[[:space:]]" | sort -u)
    end

    if test -z "$services"
        echo "No LoadBalancer services with external IPs found"
        return 1
    end

    set output ""

    # Iterate through each service and store unique IPs per namespace
    set seen_ips

    for service in (string split "\n" $services)
        set namespace (echo $service | awk '{print $1}')
        set external_ip (echo $service | awk '{print $5}')

        # Ensure we only add unique IPs per namespace
        if not contains $external_ip $seen_ips
            if test "$namespace" != "$prev_namespace"
                set output "$output\n$namespace:"
                set -e seen_ips # Reset seen IPs for the new namespace
            end

            set output "$output\n  $external_ip"
            set -a seen_ips $external_ip
        end

        set prev_namespace "$namespace"
    end

    # Format and display the output
    echo -e (string trim -c ' ' $output)
end
