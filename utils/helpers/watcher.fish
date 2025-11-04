# Description: Repeats a script for X seconds using viddy (falls back to watch)
# Example: watcher 2 "kubectl get pods -n sonarr"
function watcher
    # Ensure viddy is installed, fallback to watch if not
    if not check_command "viddy"
        echo "viddy not found, falling back to watch"
        set USE_WATCH 1
    end

    # Require at least one argument (the command)
    if test (count $argv) -lt 1
        echo "Usage: watcher [interval] <command...>"
        return 1
    end

    # Default refresh interval
    set INTERVAL 5

    # If first arg is a number, treat it as interval
    if echo $argv[1] | grep -qE '^[0-9]+$'
        set INTERVAL $argv[1]
        set argv (tail -n +2 $argv)
    end

    # Run the command using viddy if installed, otherwise use watch
    if test -n "$USE_WATCH"
        # Fall back to watch if viddy is not available
        watch -n $INTERVAL $argv
    else
        # Use viddy if available
        viddy -n $INTERVAL -- $argv
    end
end
