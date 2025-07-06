#!/bin/bash

# App Update Monitor Script
# Monitors popular apps across Google Play Store and Apple App Store
# Now uses the updated Python scraper with google-play-scraper
# Author: Generated for app monitoring
# Date: $(date +%Y-%m-%d)

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/app_config.json"
LOG_FILE="$SCRIPT_DIR/app_monitor.log"
OUTPUT_FILE="$SCRIPT_DIR/app_updates_$(date +%Y%m%d_%H%M%S).json"
TEMP_DIR="/tmp/app_monitor_$$"
PYTHON_SCRAPER="$SCRIPT_DIR/app_scraper.py"

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
    
    # Check if Python scraper exists
    if [[ ! -f "$PYTHON_SCRAPER" ]]; then
        log "ERROR: Python scraper not found at $PYTHON_SCRAPER"
        exit 1
    fi
    
    # Check Python dependencies
    if ! python3 -c "import requests, google_play_scraper" &> /dev/null; then
        log "WARNING: Python dependencies not installed. Install with: pip install -r requirements.txt"
        log "Falling back to basic scraping (less reliable)"
    fi
}

# Fetch app info using Python scraper
fetch_app_info() {
    local store="$1"
    local app_id="$2"
    local app_name="$3"
    
    log "Fetching $store info for $app_name ($app_id)"
    
    # Use Python scraper
    local result=$(python3 "$PYTHON_SCRAPER" "$store" "$app_id" "$app_name" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$result" ]]; then
        # Save result to temporary file
        local filename="${store}_${app_id//[^a-zA-Z0-9]/_}"
        echo "$result" > "$TEMP_DIR/${filename}.json"
        
        # Check if scraping was successful
        local status=$(echo "$result" | jq -r '.status // "unknown"')
        if [[ "$status" == "success" ]]; then
            log "SUCCESS: $app_name data fetched successfully"
        else
            local error=$(echo "$result" | jq -r '.error // "Unknown error"')
            log "WARNING: $app_name fetch had issues: $error"
        fi
    else
        log "ERROR: Failed to fetch data for $app_name ($app_id)"
        
        # Create error record
        local filename="${store}_${app_id//[^a-zA-Z0-9]/_}"
        cat << EOF > "$TEMP_DIR/${filename}.json"
{
    "app_name": "$app_name",
    "app_id": "$app_id",
    "store": "$store",
    "version": "N/A",
    "last_updated": "N/A",
    "size": "N/A",
    "fetch_time": "$(date -Iseconds)",
    "status": "error",
    "error": "Failed to execute scraper"
}
EOF
    fi
}

# Process all apps
process_apps() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR: Configuration file $CONFIG_FILE not found"
        log "Creating sample configuration file..."
        create_sample_config
        log "Please edit $CONFIG_FILE and run again"
        exit 1
    fi
    
    log "Starting app monitoring process"
    
    # Read configuration and process each app
    local app_count=0
    while IFS= read -r line; do
        local store=$(echo "$line" | jq -r '.store')
        local id=$(echo "$line" | jq -r '.id')
        local name=$(echo "$line" | jq -r '.name')
        
        if [[ "$store" != "null" && "$id" != "null" && "$name" != "null" ]]; then
            fetch_app_info "$store" "$id" "$name"
            ((app_count++))
            
            # Rate limiting to avoid being blocked
            sleep 2
        fi
    done < <(jq -c '.apps[]' "$CONFIG_FILE")
    
    log "Processed $app_count apps"
}

# Create sample configuration file
create_sample_config() {
    cat << 'EOF' > "$CONFIG_FILE"
{
    "apps": [
        {
            "store": "playstore",
            "id": "com.flipkart.android",
            "name": "Flipkart"
        },
        {
            "store": "playstore",
            "id": "com.amazon.mShop.android.shopping",
            "name": "Amazon Shopping"
        },
        {
            "store": "appstore",
            "id": "1059655371",
            "name": "Instagram"
        },
        {
            "store": "appstore",
            "id": "310633997",
            "name": "WhatsApp"
        },
        {
            "store": "playstore",
            "id": "com.whatsapp",
            "name": "WhatsApp"
        },
        {
            "store": "playstore",
            "id": "com.instagram.android",
            "name": "Instagram"
        }
    ]
}
EOF
}

# Combine results
combine_results() {
    log "Combining results"
    
    echo "{" > "$OUTPUT_FILE"
    echo "  \"monitoring_time\": \"$(date -Iseconds)\"," >> "$OUTPUT_FILE"
    echo "  \"total_apps\": $(find "$TEMP_DIR" -name "*.json" | wc -l)," >> "$OUTPUT_FILE"
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
    
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        log "ERROR: Output file not found"
        return 1
    fi
    
    local total_apps=$(jq '.total_apps // 0' "$OUTPUT_FILE")
    local successful=$(jq '.apps | map(select(.status == "success")) | length' "$OUTPUT_FILE")
    local failed=$(jq '.apps | map(select(.status == "error")) | length' "$OUTPUT_FILE")
    
    echo "=== App Update Monitor Summary ===" | tee -a "$LOG_FILE"
    echo "Monitoring Time: $(date)" | tee -a "$LOG_FILE"
    echo "Total Apps Monitored: $total_apps" | tee -a "$LOG_FILE"
    echo "Successful Fetches: $successful" | tee -a "$LOG_FILE"
    echo "Failed Fetches: $failed" | tee -a "$LOG_FILE"
    echo "Success Rate: $(( successful * 100 / (total_apps > 0 ? total_apps : 1) ))%" | tee -a "$LOG_FILE"
    echo "Output File: $OUTPUT_FILE" | tee -a "$LOG_FILE"
    
    # Show some sample results
    if [[ $successful -gt 0 ]]; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== Sample Results ===" | tee -a "$LOG_FILE"
        jq -r '.apps[] | select(.status == "success") | "\(.app_name) (\(.store)): v\(.version) - \(.last_updated)"' "$OUTPUT_FILE" | head -5 | tee -a "$LOG_FILE"
    fi
    
    # Show errors if any
    if [[ $failed -gt 0 ]]; then
        echo "" | tee -a "$LOG_FILE"
        echo "=== Failed Apps ===" | tee -a "$LOG_FILE"
        jq -r '.apps[] | select(.status == "error") | "\(.app_name) (\(.store)): \(.error)"' "$OUTPUT_FILE" | tee -a "$LOG_FILE"
    fi
    
    echo "=================================" | tee -a "$LOG_FILE"
}

# Send notification (optional)
send_notification() {
    if command -v mail &> /dev/null && [[ -n "$NOTIFICATION_EMAIL" ]]; then
        log "Sending email notification"
        {
            echo "App monitoring completed at $(date)"
            echo ""
            echo "Results summary:"
            jq -r '.apps[] | select(.status == "success") | "\(.app_name): \(.version) (\(.last_updated))"' "$OUTPUT_FILE"
            echo ""
            echo "Full report: $OUTPUT_FILE"
        } | mail -s "App Update Monitor Report - $(date +%Y-%m-%d)" "$NOTIFICATION_EMAIL"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --config FILE    Use custom configuration file"
    echo "  -o, --output FILE    Custom output file path"
    echo "  -e, --email EMAIL    Email address for notifications"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Configuration file format (JSON):"
    echo "{"
    echo "  \"apps\": ["
    echo "    {"
    echo "      \"store\": \"playstore\","
    echo "      \"id\": \"com.example.app\","
    echo "      \"name\": \"Example App\""
    echo "    }"
    echo "  ]"
    echo "}"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -e|--email)
                NOTIFICATION_EMAIL="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"
    
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