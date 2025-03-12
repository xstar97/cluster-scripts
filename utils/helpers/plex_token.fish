# Description: Get auth token from plex user. 
# Example: plex_token [--url custom_url]
function plex_token
    
    # Check if required commands are installed
    check_command "yq"
    check_command "curl"
    check_command "jq"

    # Default Plex URL
    set PLEX_URL "https://plex.tv"

    # Parse arguments for --url option
    for i in (seq 1 (count $argv))
        if test "$argv[$i]" = "--url"
            set PLEX_URL $argv[(math $i + 1)]
        end
    end

    echo "url: $PLEX_URL"

    # Check if CONFIG is encrypted and extract values accordingly
    set PLEX_USER (extract_clusterenv_key --key "PLEX_USER")
    set PLEX_PASS (extract_clusterenv_key --key "PLEX_PASS")

    # Ensure credentials are present
    if test -z "$PLEX_USER" -o -z "$PLEX_PASS"
        echo "Error: Missing PLEX_USER or PLEX_PASS in $CONFIG"
        return 1
    end

    # Authenticate with Plex and retrieve token
    set PLEX_TOKEN (curl -s -X POST "$PLEX_URL/users/sign_in.json" \
        -H "X-Plex-Client-Identifier: plex-token-script" \
        -H "X-Plex-Product: Plex-Token-Getter" \
        -H "X-Plex-Version: 1.0" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "user[login]=$PLEX_USER" \
        --data-urlencode "user[password]=$PLEX_PASS" | jq -r .user.authToken)

    # Check if token was retrieved
    if test -z "$PLEX_TOKEN" -o "$PLEX_TOKEN" = "null"
        echo "Error: Failed to get Plex token"
        return 1
    end

    echo "token: $PLEX_TOKEN"

end