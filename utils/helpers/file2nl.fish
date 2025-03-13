# Description: inputs a file and outputs to shell a single line with \n
# Example: file2nl /path/to/file
function file2nl
    # Usage function
    function usage
        echo "Usage: file2nl --file <filename>"
        exit 1
    end

    # Parse arguments
    set FILE ""
    while test (count $argv) -gt 0
        switch $argv[1]
            case '--file'
                set FILE $argv[2]
                set argv (string split -m 2 ' ' (string join ' ' $argv[3..-1]))
            case '*'
                usage
        end
    end

    # Validate file
    if test -z "$FILE" -o ! -e "$FILE"
        echo "Error: File not found or not specified."
        exit 1
    end

    # Read file, replace newlines with \n, and output as a single line
    cat $FILE | string join '\\n'
end
