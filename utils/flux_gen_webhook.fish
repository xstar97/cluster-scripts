# Description: Generates a webhook for GitHub with configurable namespace, receiver, and ingress
# Example: flux_gen_webhook [-n custom-namespace] [-r custom-receiver] [-i custom-ingress]
function flux_gen_webhook
    check_command "kubectl"
    check_command "flux"

    # Default values
    set NAMESPACE "flux-system"
    set RECEIVER_NAME "github-receiver"
    set INGRESS_NAME "webhook-receiver"

    # Parse options
    for i in (seq (count $argv))
        switch $argv[$i]
            case '-n' '--namespace'
                set NAMESPACE $argv[(math $i + 1)]
            case '-r' '--receiver'
                set RECEIVER_NAME $argv[(math $i + 1)]
            case '-i' '--ingress'
                set INGRESS_NAME $argv[(math $i + 1)]
        end
    end

    # Retrieve the ingress URL (address or host)
    set BASE_URL (kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].host}')

    if test -z "$BASE_URL"
        # Fallback to address if host is not defined
        set BASE_URL (kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    end

    if test -z "$BASE_URL"
        echo "Error: Could not retrieve the ingress URL for '$INGRESS_NAME' in namespace '$NAMESPACE'."
        exit 1
    end

    # Retrieve the webhook path
    set WEBHOOK_PATH (kubectl -n "$NAMESPACE" get receiver "$RECEIVER_NAME" -o jsonpath='{.status.webhookPath}')

    # Output the full webhook URL
    if test -n "$WEBHOOK_PATH"
        echo "The webhook URL is: https://$BASE_URL$WEBHOOK_PATH"
    else
        echo "Error: Could not retrieve the webhook path for receiver '$RECEIVER_NAME' in namespace '$NAMESPACE'."
        exit 1
    end
end
