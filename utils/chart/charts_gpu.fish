# Description: List all charts that have an allocated gpu.
# Example: charts_gpu [--gpu intel | nvidia (default) | customUrl]
function charts_gpu
    # Default GPU provider is "nvidia"
    set gpu_flag "nvidia"

    # Check if the --gpu flag is provided and handle its argument correctly
    for i in (seq 1 (count $argv))
        if test $argv[$i] = "--gpu"
            # Check if the next argument exists and assign it to gpu_flag
            if test (count $argv) -gt $i
                set gpu_flag $argv[(math $i + 1)]
            else
                echo "Error: Please specify a GPU provider after --gpu."
                return 1
            end
        end
    end

    # Set the correct GPU URL based on the --gpu flag
    if test $gpu_flag = "intel"
        set gpu_url "gpu.intel.com/i915"
    else if test $gpu_flag = "nvidia"
        set gpu_url "nvidia.com/gpu"
    else
        set gpu_url $gpu_flag  # Allow custom GPU URL
    end

    # Get pod details and filter GPU usage using jq for the desired output format
    kubectl get pods --all-namespaces -o=json | jq -r \
        ".items[] | select(.spec.containers[].resources.requests[\"$gpu_url\"] != null) | 
        \"\(.metadata.name):\n   $gpu_url: \(.spec.containers[].resources.requests[\"$gpu_url\"])\""
end
