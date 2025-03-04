function status_badges
    set -l config_file "./status-badges.yaml"
    set -l save_file "./status-badges.md"

    argparse "c/config=" "s/save=" -- $argv

    if test -n "$_flag_config"
        set config_file "$_flag_config"
    end

    if test -n "$_flag_save"
        set save_file "$_flag_save"
    end

    if not test -f "$config_file"
        echo "Error: Config file not found: $config_file"
        return 1
    end

    echo "### Status Badges" > $save_file
    echo "<div align='center'>" >> $save_file  # Wrap entire section in div

    for category in (yq e '.badges | keys | .[]' "$config_file")
        echo "<h4>$category</h4>" >> $save_file  # Print the category heading
        echo "<div style='display: flex; gap: 20px; justify-content: center;'>" >> $save_file  # Flex container for horizontal badges

        for badge in (yq e ".badges.$category | keys | .[]" "$config_file")
            # Get badge name and badge URL
            set badge_name (yq e ".badges.$category.$badge | keys | .[0]" "$config_file")
            set badge_url (yq e ".badges.$category.$badge.badge.url" "$config_file")
            set queries (yq e ".badges.$category.$badge.badge.queries" "$config_file")

            # Initialize the query string
            set query_string ""

            # Check if there are any query parameters
            if test -n "$queries"
                set first_query true
                for query_key in (yq e ".badges.$category.$badge.badge.queries | keys | .[]" "$config_file")
                    set query_value (yq e ".badges.$category.$badge.badge.queries.$query_key" "$config_file")

                    # Replace spaces with %20 for the query value
                    set query_value (string replace -a " " "%20" $query_value)

                    # Append the first query with a ?, and subsequent queries with &
                    if test "$first_query" = "true"
                        set query_string "?$query_key=$query_value"
                        set first_query false
                    else
                        set query_string "$query_string&$query_key=$query_value"
                    end
                end
            end

            # Combine URL and query string if it's not empty
            if test -n "$query_string"
                set full_url "$badge_url$query_string"
            else
                set full_url "$badge_url"
            end

            # Get redirect URL
            set redirect_url (yq e ".badges.$category.$badge.redirect" "$config_file")

            # Add badge with proper spacing and ensure the URL is correct
            if test -n "$full_url" -a -n "$redirect_url"
                echo "<div>" >> $save_file
                echo "<a href='$redirect_url'>" >> $save_file
                echo "<img src='$full_url' alt='$badge_name'>" >> $save_file  # Display badge with redirect
                echo "</a>" >> $save_file
                echo "</div>" >> $save_file
            end
        end

        echo "</div>" >> $save_file  # Close the flex container
    end

    echo "</div>" >> $save_file  # Close the div
    echo "Generated $save_file"
end
