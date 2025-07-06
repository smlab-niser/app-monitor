#!/bin/bash

# App Update Monitor Script
# Monitors popular apps across Google Play Store and Apple App Store
# Author: Generated for app monitoring
# Date: $(date +%Y-%m-%d)

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/app_config.json"
LOG_FILE="$SCRIPT_DIR/app_monitor.log"
OUTPUT_FILE="$SCRIPT_DIR/app_updates_$(date +%Y%m%d_%H%M%S).json"
TEMP_DIR="/tmp/app_monitor_$$"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check dependencies
check_dependencies() {
    local deps=("curl" "jq" "python3")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "ERROR: $dep is not installed. Please install it first."
            exit 1
        fi
    done
}

# Fetch Google Play Store app info
fetch_playstore_info() {
    local package_id="$1"
    local app_name="$2"
    
    log "Fetching Play Store info for $app_name ($package_id)"
    
    # Using Google Play Store scraper API (you might need to use a service like https://serpapi.com/)
    # For demonstration, using a mock approach - in real implementation you'd use proper APIs
    
    local url="https://play.google.com/store/apps/details?id=$package_id&hl=en"
    local response=$(curl -s -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "$url")
    
    if [[ -z "$response" ]]; then
        log "ERROR: Failed to fetch data for $app_name"
        return 1
    fi
    
    # Extract version info using regex (basic approach)
    local version=$(echo "$response" | grep -oP 'Current Version.*?</span>.*?<span[^>]*>\K[^<]+' | head -1)
    local updated=$(echo "$response" | grep -oP 'Updated.*?</span>.*?<span[^>]*>\K[^<]+' | head -1)
    local size=$(echo "$response" | grep -oP 'Size.*?</span>.*?<span[^>]*>\K[^<]+' | head -1)
    
    # Create JSON object
    cat << EOF > "$TEMP_DIR/playstore_$package_id.json"
{
    "app_name": "$app_name",
    "package_id": "$package_id",
    "store": "Google Play Store",
    "version": "${version:-"N/A"}",
    "last_updated": "${updated:-"N/A"}",
    "size": "${size:-"N/A"}",
    "fetch_time": "$(date -Iseconds)",
    "status": "success"
}
EOF
}

# Fetch Apple App Store info
fetch_appstore_info() {
    local app_id="$1"
    local app_name="$2"
    
    log "Fetching App Store info for $app_name ($app_id)"
    
    # Using iTunes Search API
    local url="https://itunes.apple.com/lookup?id=$app_id"
    local response=$(curl -s "$url")
    
    if [[ -z "$response" ]]; then
        log "ERROR: Failed to fetch data for $app_name"
        return 1
    fi
    
    # Parse JSON response
    local version=$(echo "$response" | jq -r '.results[0].version // "N/A"')
    local updated=$(echo "$response" | jq -r '.results[0].currentVersionReleaseDate // "N/A"')
    local size=$(echo "$response" | jq -r '.results[0].fileSizeBytes // "N/A"')
    
    # Convert size to readable format
    if [[ "$size" != "N/A" && "$size" =~ ^[0-9]+$ ]]; then
        size=$(python3 -c "
size = $size
if size >= 1073741824:
    print(f'{size/1073741824:.1f} GB')
elif size >= 1048576:
    print(f'{size/1048576:.1f} MB')
elif size >= 1024:
    print(f'{size/1024:.1f} KB')
else:
    print(f'{size} bytes')
")
    fi
    
    # Create JSON object
    cat << EOF > "$TEMP_DIR/appstore_$app_id.json"
{
    "app_name": "$app_name",
    "app_id": "$app_id",
    "store": "Apple App Store",
    "version": "$version",
    "last_updated": "$updated",
    "size": "$size",
    "fetch_time": "$(date -Iseconds)",
    "status": "success"
}
EOF
}

# Process all apps
process_apps() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR: Configuration file $CONFIG_FILE not found"
        exit 1
    fi
    
    log "Starting app monitoring process"
    
    # Read configuration and process each app
    jq -r '.apps[] | "\(.store) \(.id) \(.name)"' "$CONFIG_FILE" | while read -r store id name; do
        case "$store" in
            "playstore")
                fetch_playstore_info "$id" "$name"
                ;;
            "appstore")
                fetch_appstore_info "$id" "$name"
                ;;
            *)
                log "WARNING: Unknown store type: $store"
                ;;
        esac
        
        # Rate limiting to avoid being blocked
        sleep 2
    done
}

# Combine results
combine_results() {
    log "Combining results"
    
    echo "{" > "$OUTPUT_FILE"
    echo "  \"monitoring_time\": \"$(date -Iseconds)\"," >> "$OUTPUT_FILE"
    echo "  \"apps\": [" >> "$OUTPUT_FILE"
    
    local first=true
    for file in "$TEMP_DIR"/*.json; do
        if [[ -f "$file" ]]; then
            if [[ "$first" = true ]]; then
                first=false
            else
                echo "," >> "$OUTPUT_FILE"
            fi
            sed 's/^/    /' "$file" >> "$OUTPUT_FILE"
        fi
    done
    
    echo "" >> "$OUTPUT_FILE"
    echo "  ]" >> "$OUTPUT_FILE"
    echo "}" >> "$OUTPUT_FILE"
    
    log "Results saved to $OUTPUT_FILE"
}

# Generate summary report
generate_summary() {
    log "Generating summary report"
    
    local total_apps=$(jq '.apps | length' "$OUTPUT_FILE")
    local successful=$(jq '.apps | map(select(.status == "success")) | length' "$OUTPUT_FILE")
    
    echo "=== App Update Monitor Summary ===" | tee -a "$LOG_FILE"
    echo "Monitoring Time: $(date)" | tee -a "$LOG_FILE"
    echo "Total Apps Monitored: $total_apps" | tee -a "$LOG_FILE"
    echo "Successful Fetches: $successful" | tee -a "$LOG_FILE"
    echo "Failed Fetches: $((total_apps - successful))" | tee -a "$LOG_FILE"
    echo "Output File: $OUTPUT_FILE" | tee -a "$LOG_FILE"
    echo "=================================" | tee -a "$LOG_FILE"
}

# Send notification (optional)
send_notification() {
    if command -v mail &> /dev/null && [[ -n "$NOTIFICATION_EMAIL" ]]; then
        log "Sending email notification"
        echo "App monitoring completed. Check $OUTPUT_FILE for details." | \
            mail -s "App Update Monitor Report - $(date +%Y-%m-%d)" "$NOTIFICATION_EMAIL"
    fi
}

# Main execution
main() {
    log "Starting App Update Monitor"
    
    check_dependencies
    process_apps
    combine_results
    generate_summary
    send_notification
    
    log "App Update Monitor completed successfully"
}

# Run main function
main "$@"