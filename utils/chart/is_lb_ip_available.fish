# Description: Checks if the IP is available and within the metallb range. 
# Example: is_lb_ip_available IP
function is_lb_ip_available
    set CONFIG "$BASE_PATH/clusters/main/clusterenv.yaml"
    set user_ip "$argv[1]"

    # Ensure an IP is provided
    if test -z "$user_ip"
        echo "Usage: is_lb_ip_available <IP>" >&2
        return 1
    end

    # Check if CONFIG is encrypted and extract values accordingly
    if check_sops "$CONFIG" | grep -q "true"
        echo "$CONFIG is encrypted; temp decrypting to extract range values"
        set METALLB_RANGE (extract_sops "$CONFIG" "METALLB_RANGE")
    else
        echo "$CONFIG is not encrypted....extracting range values"
        set METALLB_RANGE (yq eval '.METALLB_RANGE' "$CONFIG")
    end

    # Extract LoadBalancer IPs
    set lb_ips (kubectl get svc -A --no-headers | awk '$3 == "LoadBalancer" && $5 != "<none>" {print $5}' | sort -u)

    # Parse METALLB_RANGE (assumes format "start-end")
    set start_ip (echo $METALLB_RANGE | cut -d'-' -f1)
    set end_ip (echo $METALLB_RANGE | cut -d'-' -f2)

    # Function to convert IP to integer
    function ip_to_int
        echo $argv[1] | awk -F'.' '{print ($1 * 16777216) + ($2 * 65536) + ($3 * 256) + $4}'
    end

    set start_int (ip_to_int $start_ip)
    set end_int (ip_to_int $end_ip)

    # Check if user-specified IP is in use
    if contains $user_ip $lb_ips
        echo "IP $user_ip is already in use"
        return 1
    end

    # Check if user-specified IP is within range
    set user_ip_int (ip_to_int $user_ip)
    if test $user_ip_int -ge $start_int -a $user_ip_int -le $end_int
        echo "IP $user_ip is within METALLB_RANGE and available"
        return 0
    else
        echo "IP $user_ip is outside of METALLB_RANGE"
        return 1
    end
end