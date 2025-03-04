# Description: Generates a markdown file for uptime-kuma badges
# Example: gen_badges [--config /path/to/badges.yaml] [--save /path/to/badges.md]
function gen_badges
    set -l default_config "./badges.yaml"
    set -l default_save "./badges.md"
    set -l config_file "$default_config"
    set -l save_file "$default_save"

    argparse "c/config=" "s/save=" -- $argv

    if test -n "$_flag_config"
        set config_file "$_flag_config"
        echo "Using custom config file: $config_file"
    else
        echo "Using default config file: $default_config"
    end

    if test -n "$_flag_save"
        set save_file "$_flag_save"
    end

    # Check if config file exists
    if not test -f "$config_file"
        echo "Error: Config file not found: $config_file"
        return 1
    end

    echo "Parsing config file: $config_file"
    cat "$config_file"  # Show the contents of the config file
    echo ""
    echo ""
    # Validate YAML structure
    set invalid false
    set category_count 0
    set badge_count 0

    for category in (yq e '.badges | keys | .[]' "$config_file")
        set category_count (math $category_count + 1)
        echo "Processing category: $category"

        for badge in (yq e ".badges.$category | keys | .[]" "$config_file")
            set badge_name (yq e ".badges.$category.$badge | keys | .[0]" "$config_file")
            set badge_url (yq e ".badges.$category.$badge.badge.url" "$config_file")
            set redirect_url (yq e ".badges.$category.$badge.redirect" "$config_file")

            if test -z "$badge_name" -o "$badge_name" = "null"
                echo "Error: Missing badge name under '$category/$badge'"
                set invalid true
            end

            if test -z "$badge_url" -o "$badge_url" = "null"
                echo "Error: Missing badge URL under '$category/$badge'"
                set invalid true
            end

            if test -z "$redirect_url" -o "$redirect_url" = "null"
                echo "Error: Missing redirect URL under '$category/$badge'"
                set invalid true
            end

            set badge_count (math $badge_count + 1)
            echo "✔ Created badge: $badge_name"
        end
    end

    if test "$invalid" = "true"
        echo "Error: Invalid YAML structure. Please fix the errors above."
        return 1
    end
    
    echo ""
    echo "Generating markdown file: $save_file"
    echo "### Status Badges" > $save_file
    echo "<div align='center'>" >> $save_file

    for category in (yq e '.badges | keys | .[]' "$config_file")
        echo "<h4>$category</h4>" >> $save_file
        echo "<div style='display: flex; gap: 20px; justify-content: center;'>" >> $save_file

        for badge in (yq e ".badges.$category | keys | .[]" "$config_file")
            set badge_name (yq e ".badges.$category.$badge | keys | .[0]" "$config_file")
            set badge_url (yq e ".badges.$category.$badge.badge.url" "$config_file")
            set queries (yq e ".badges.$category.$badge.badge.queries" "$config_file")
            set redirect_url (yq e ".badges.$category.$badge.redirect" "$config_file")

            # Construct query string
            set query_string ""
            if test -n "$queries" -a "$queries" != "null"
                set first_query true
                for query_key in (yq e ".badges.$category.$badge.badge.queries | keys | .[]" "$config_file")
                    set query_value (yq e ".badges.$category.$badge.badge.queries.$query_key" "$config_file")
                    set query_value (string replace -a " " "%20" $query_value)
                    if test "$first_query" = "true"
                        set query_string "?$query_key=$query_value"
                        set first_query false
                    else
                        set query_string "$query_string&$query_key=$query_value"
                    end
                end
            end

            # Final badge URL
            set full_url "$badge_url$query_string"

            # Generate badge markdown
            echo "<div>" >> $save_file
            echo "<a href='$redirect_url'>" >> $save_file
            echo "<img src='$full_url' alt='$badge_name'>" >> $save_file
            echo "</a>" >> $save_file
            echo "</div>" >> $save_file
        end

        echo "</div>" >> $save_file
    end

    echo "</div>" >> $save_file

    echo "✅ Generated $save_file with $category_count categories and $badge_count badges."
end
