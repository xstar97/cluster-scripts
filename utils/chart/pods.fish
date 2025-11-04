# Description: access pods shell or logs
# Example: pods or pods -l -s -h
function pods
    # --- Show help ---
    function pod_help
        echo "Usage:"
        echo "  pods                   # fully interactive mode"
        echo "  pods -s [namespace]    # open a shell in a pod"
        echo "  pods -l [namespace]    # view logs in a pod"
        echo "  pods -h                # show this help message"
    end

    # --- Check kubectl ---
    if not type -q kubectl
        echo "❌ kubectl not found. Please install it."
        return 1
    end

    # --- Parse args ---
    set mode ""
    set namespace ""

    for arg in $argv
        switch $arg
            case "-s" "--shell"
                set mode "shell"
            case "-l" "--logs"
                set mode "logs"
            case "-h" "--help"
                pod_help
                return 0
            case "*"
                if test -z "$namespace"
                    set namespace $arg
                end
        end
    end

    # --- Namespace selection ---
    while true
        if test -z "$namespace"
            set namespaces (kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers | sort)

            if test (count $namespaces) -eq 0
                echo "⚠️  No namespaces found."
                return 1
            end

            echo ""
            echo "Available namespaces:"

            # --- Determine display layout ---
            set cols 3  # default column count
            if set -q COLUMNS
                if test $COLUMNS -lt 80
                    set cols 2
                else if test $COLUMNS -gt 160
                    set cols 4
                end
            end

            # --- Determine column width (max namespace name length) ---
            set maxlen 0
            for ns in $namespaces
                set nslen (string length $ns)
                if test $nslen -gt $maxlen
                    set maxlen $nslen
                end
            end

            # Add padding for index and spacing
            set colwidth (math "$maxlen + 8")

            # --- Print namespaces in a clean table ---
            set total (count $namespaces)
            for i in (seq $total)
                set idx (printf "%3d) " $i)
                set name $namespaces[$i]
                printf "%s%-*s" "$idx" $colwidth $name

                if test (math "$i % $cols") -eq 0
                    echo ""
                end
            end
            echo ""
            echo "0) Exit"

            # --- Selection logic ---
            while true
                read -P "Select namespace: " ns_choice
                if test -z "$ns_choice"
                    echo "❌ Please enter a number."
                    continue
                end
                if test "$ns_choice" = "0"
                    echo "Exiting..."
                    return 0
                end
                if not string match -rq '^[0-9]+$' -- $ns_choice
                    echo "❌ Invalid input. Enter a number."
                    continue
                end
                if test "$ns_choice" -gt 0 -a "$ns_choice" -le (count $namespaces)
                    set namespace $namespaces[$ns_choice]
                    echo ""
                    echo "✅ Selected namespace: $namespace"
                    break
                else
                    echo "❌ Invalid selection. Try again."
                    continue
                end
            end
        end


        # --- Ask action ---
        if test -z "$mode"
            while true
                echo ""
                echo "Choose action:"
                echo "1) Open shell"
                echo "2) View logs"
                echo "0) Back to namespace selection"
                read -P "Select action: " action_choice
                switch $action_choice
                    case 1
                        set mode "shell"
                        break
                    case 2
                        set mode "logs"
                        break
                    case 0
                        set namespace ""
                        set mode ""
                        continue 2
                    case '*'
                        echo "❌ Invalid option."
                end
            end
        end

        # --- Pod selection ---
        while true
            set pods (kubectl get pods -n $namespace -o custom-columns=NAME:.metadata.name --no-headers | sort)
            if test (count $pods) -eq 0
                echo "❌ No pods in $namespace"
                set namespace ""
                set mode ""
                break
            end

            echo ""
            echo "Pods in '$namespace':"
            for i in (seq (count $pods))
                echo "$i) $pods[$i]"
            end
            echo "0) Back"
            read -P "Select pod: " pod_choice

            if test "$pod_choice" = "0"
                set mode ""
                break
            end

            if not string match -rq '^[0-9]+$' -- $pod_choice
                echo "❌ Invalid input."
                continue
            end
            if test "$pod_choice" -lt 1 -o "$pod_choice" -gt (count $pods)
                echo "❌ Invalid pod number."
                continue
            end
            set pod $pods[$pod_choice]

            # --- Container selection ---
            set containers (kubectl get pod $pod -n $namespace -o jsonpath='{range.spec.containers[*]}{.name}{"\n"}{end}' | sort)
            if test (count $containers) -eq 0
                echo "❌ No containers in $pod"
                continue
            end

            if test (count $containers) -eq 1
                set container $containers[1]
            else
                echo ""
                echo "Containers in '$pod':"
                for i in (seq (count $containers))
                    echo "$i) $containers[$i]"
                end
                echo "0) Back"
                read -P "Select container: " container_choice

                if test "$container_choice" = "0"
                    continue
                end

                if not string match -rq '^[0-9]+$' -- $container_choice
                    echo "❌ Invalid input."
                    continue
                end
                if test "$container_choice" -lt 1 -o "$container_choice" -gt (count $containers)
                    echo "❌ Invalid container number."
                    continue
                end
                set container $containers[$container_choice]
            end

            echo ""
            echo "Namespace: $namespace"
            echo "Pod:       $pod"
            echo "Container: $container"
            echo ""

            switch $mode
                case "logs"
                    read -P "How many log lines? (default 500, -1 for all): " lines
                    if test -z "$lines"
                        set lines 500
                    end
                    kubectl logs -n $namespace -c $container $pod --tail=$lines -f
                case "shell"
                    set found_shell ""
                    for s in bash sh ash
                        if kubectl exec -n $namespace $pod -c $container -- which $s >/dev/null 2>&1
                            set found_shell $s
                            break
                        end
                    end
                    if test -z "$found_shell"
                        echo "⚠️  No shell found (distroless?)."
                        echo "Try: kubectl exec -n $namespace $pod -c $container -- <cmd>"
                    else
                        echo "✅ Shell: $found_shell"
                        kubectl exec -n $namespace $pod -c $container -it -- $found_shell
                    end
            end

            echo ""
            read -P "Pick another pod in '$namespace'? (y/N): " again
            if not string match -rq '^[Yy]' $again
                set namespace ""
                set mode ""
                break
            end
        end
    end
end
