#!/usr/bin/env fish

# Description: Show etcd DB usage per node and optionally run defrag
# Usage: show_etcd_status
function show_etcd_status
    echo ""
    echo "etcd disk usage per node"
    echo "------------------------------------------------------------"

    # Print a clean header
    printf "%-15s %-12s %-20s\n" "NODE" "DB SIZE" "IN USE"

    talosctl etcd status | tail -n +2 | while read -l line
        # Use awk to extract full size fields with units
        set node    (echo $line | awk '{print $1}')
        set db_size (echo $line | awk '{print $3" "$4}')
        set in_use  (echo $line | awk '{print $5" "$6" "$7}')

        printf "%-15s %-12s %-20s\n" $node $db_size $in_use
    end

    echo "------------------------------------------------------------"
    echo ""

    read -P "Run 'talosctl etcd defrag'? (y/n): " choice

    switch $choice
        case y Y yes YES
            echo ""
            echo "Running etcd defrag..."
            talosctl etcd defrag
            or begin
                echo "Error: etcd defrag failed."
                return 1
            end

            echo ""
            echo "Updated etcd status:"
            echo "------------------------------------------------------------"
            printf "%-15s %-12s %-20s\n" "NODE" "DB SIZE" "IN USE"

            talosctl etcd status | tail -n +2 | while read -l line
                set node    (echo $line | awk '{print $1}')
                set db_size (echo $line | awk '{print $3" "$4}')
                set in_use  (echo $line | awk '{print $5" "$6" "$7}')

                printf "%-15s %-12s %-20s\n" $node $db_size $in_use
            end

            echo "------------------------------------------------------------"

        case n N no NO
            echo "Skipping etcd defrag."

        case '*'
            echo "Invalid choice. Please answer y or n."
            return 1
    end
end