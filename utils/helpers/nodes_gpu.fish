# Description: List all nodes that have allocated gpus.
# Example: nodes_gpu [--gpu intel | nvidia (default) | customUrl]
function nodes_gpu
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
        set gpu_url "gpu\.intel\.com/i915"
    else if test $gpu_flag = "nvidia"
        set gpu_url "nvidia\.com/gpu"
    else
        set gpu_url $gpu_flag  # Allow custom GPU URL
    end

    # Fetch GPU allocation for nodes based on the GPU URL
    set gpu_allocations (kubectl get nodes -o=jsonpath="{range .items[*]}{.metadata.name}{': $gpu_flag: '}{.status.allocatable.$gpu_url}{'\n'}{end}")

    # Check if any GPU allocations are found
    for allocation in $gpu_allocations
        set node_name (string split ': ' $allocation)[1]
        set node_gpu (string split ': ' $allocation)[2]
        set node_gpu_count (string split ': ' $allocation)[3]
        # If the GPU count is missing or null
        if test -z $node_gpu_count
            echo "Error: No GPU allocation for provider $node_gpu on $node_name"
        # If the GPU count is 0
        else if test $node_gpu_count = "0"
            echo "$allocation - GPU available but not allocated (0)"
        else
            echo "$allocation"
        end
    end
end
