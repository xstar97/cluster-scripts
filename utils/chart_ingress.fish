# Description: Get domain URLs from a chart.
# Example: chart_ingress chart [namespace]
function chart_ingress
    check_command "kubectl"
    
    set app_names $argv

    # Get all ingresses
    if test (count $app_names) -eq 0
        set ingresses (kubectl get ingress --no-headers -A | sort -u)
    else
        set pattern (string join '|' $app_names)
        set ingresses (kubectl get ingress --no-headers -A | grep -E "^($pattern)[[:space:]]" | sort -u)
    end

    if test -z "$ingresses"
        echo "No ingresses found"
        return 1
    end

    set output ""

    # Iterate through each ingress
    for ingress in (string split "\n" $ingresses)
        set namespace (echo $ingress | awk '{print $1}')
        set ingress_name (echo $ingress | awk '{print $2}')
        set hosts (echo $ingress | awk '{print $4}')

        # Print namespace header only when it changes
        if test "$namespace" != "$prev_namespace"
            set output "$output\n$namespace:"
        end
        
        # Split hosts and prepend 'https://' to each host
        for host in (string split "," $hosts)
            set https_host "https://$host"
            set output "$output\n  $https_host"
        end

        # Update previous namespace for comparison
        set prev_namespace "$namespace"
    end

    # Format and display the output
    echo -e (string trim -c ' ' $output)
end
