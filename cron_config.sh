#!/bin/bash

# Cron Job Configuration for App Monitor
# This file contains various cron job examples for different monitoring frequencies

# =============================================================================
# CRON JOB EXAMPLES
# =============================================================================

# Every 6 hours (recommended for most use cases)
# 0 */6 * * * cd /home/user/app-monitor && ./app_monitor.sh > /dev/null 2>&1

# Every 12 hours (twice daily)
# 0 */12 * * * cd /home/user/app-monitor && ./app_monitor.sh > /dev/null 2>&1

# Daily at 2 AM
# 0 2 * * * cd /home/user/app-monitor && ./app_monitor.sh > /dev/null 2>&1

# Every 3 hours during business hours (9 AM to 6 PM)
# 0 9,12,15,18 * * * cd /home/user/app-monitor && ./app_monitor.sh > /dev/null 2>&1

# Weekly on Sundays at 3 AM
# 0 3 * * 0 cd /home/user/app-monitor && ./app_monitor.sh > /dev/null 2>&1

# Monthly on the 1st at 1 AM
# 0 1 1 * * cd /home/user/app-monitor && ./app_monitor.sh > /dev/null 2>&1

# =============================================================================
# INSTALLATION COMMANDS
# =============================================================================

# To install a cron job:
# 1. Edit your crontab: crontab -e
# 2. Add one of the above lines (uncommented)
# 3. Save and exit

# To view current cron jobs:
# crontab -l

# To remove all cron jobs:
# crontab -r

# =============================================================================
# AUTOMATED CRON INSTALLATION SCRIPT
# =============================================================================

install_cron_job() {
    local script_path="$1"
    local schedule="$2"
    local email="$3"
    
    if [[ -z "$script_path" ]]; then
        echo "Usage: install_cron_job <script_path> [schedule] [email]"
        echo "Example: install_cron_job /home/user/app-monitor '0 */6 * * *' user@example.com"
        return 1
    fi
    
    # Default schedule: every 6 hours
    schedule=${schedule:-"0 */6 * * *"}
    
    # Create cron job command
    cron_command="$schedule cd $(dirname "$script_path") && ./$(basename "$script_path")"
    
    # Add email notification if provided
    if [[ -n "$email" ]]; then
        cron_command="$cron_command && echo 'App monitoring completed at \$(date)' | mail -s 'App Monitor Report - \$(date +%Y-%m-%d)' $email"
    fi
    
    # Add logging
    cron_command="$cron_command >> $(dirname "$script_path")/cron.log 2>&1"
    
    # Install cron job
    (crontab -l 2>/dev/null; echo "$cron_command") | crontab -
    
    echo "Cron job installed successfully:"
    echo "$cron_command"
}

# =============================================================================
# CRON JOB MANAGEMENT FUNCTIONS
# =============================================================================

# Function to remove app monitor cron jobs
remove_app_monitor_cron() {
    crontab -l 2>/dev/null | grep -v "app_monitor.sh" | crontab -
    echo "App monitor cron jobs removed"
}

# Function to check if cron service is running
check_cron_service() {
    if systemctl is-active --quiet cron || systemctl is-active --quiet crond; then
        echo "Cron service is running"
        return 0
    else
        echo "Cron service is not running"
        echo "To start cron service:"
        echo "  Ubuntu/Debian: sudo systemctl start cron"
        echo "  CentOS/RHEL/Fedora: sudo systemctl start crond"
        return 1
    fi
}

# Function to view cron logs
view_cron_logs() {
    echo "Checking cron logs..."
    
    # Different log locations for different systems
    if [[ -f /var/log/cron ]]; then
        echo "=== Recent cron activity (CentOS/RHEL) ==="
        tail -20 /var/log/cron | grep -i "app_monitor\|cron"
    elif [[ -f /var/log/cron.log ]]; then
        echo "=== Recent cron activity (Ubuntu/Debian) ==="
        tail -20 /var/log/cron.log | grep -i "app_monitor\|cron"
    else
        echo "=== Checking syslog for cron activity ==="
        tail -20 /var/log/syslog | grep -i "cron"
    fi
}

# =============================================================================
# EXAMPLE USAGE
# =============================================================================

# Uncomment and modify the following line to install a cron job:
# install_cron_job "/home/user/app-monitor/app_monitor.sh" "0 */6 * * *" "user@example.com"

# =============================================================================
# QUICK SETUP COMMANDS
# =============================================================================

# One-liner to add daily monitoring at 2 AM:
# (crontab -l 2>/dev/null; echo "0 2 * * * cd /home/user/app-monitor && ./app_monitor.sh >> /home/user/app-monitor/cron.log 2>&1") | crontab -

# One-liner to add 6-hourly monitoring with email:
# (crontab -l 2>/dev/null; echo "0 */6 * * * cd /home/user/app-monitor && ./app_monitor.sh && echo 'App monitoring completed' | mail -s 'App Monitor Report' user@example.com") | crontab -

# =============================================================================
# TROUBLESHOOTING
# =============================================================================

troubleshoot_cron() {
    echo "=== Cron Troubleshooting ==="
    
    echo "1. Checking if cron service is running:"
    check_cron_service
    
    echo ""
    echo "2. Current cron jobs:"
    crontab -l 2>/dev/null || echo "No cron jobs found"
    
    echo ""
    echo "3. Checking cron logs:"
    view_cron_logs
    
    echo ""
    echo "4. Common issues:"
    echo "   - Ensure script has executable permissions: chmod +x app_monitor.sh"
    echo "   - Use absolute paths in cron jobs"
    echo "   - Check script location and permissions"
    echo "   - Verify email configuration if using mail notifications"
    echo "   - Check system timezone: timedatectl status"
}

# Run troubleshooting if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        install)
            shift
            install_cron_job "$@"
            ;;
        remove)
            remove_app_monitor_cron
            ;;
        check)
            check_cron_service
            ;;
        logs)
            view_cron_logs
            ;;
        troubleshoot)
            troubleshoot_cron
            ;;
        *)
            echo "Usage: $0 {install|remove|check|logs|troubleshoot}"
            echo ""
            echo "Commands:"
            echo "  install <script_path> [schedule] [email] - Install cron job"
            echo "  remove                                   - Remove app monitor cron jobs"
            echo "  check                                    - Check if cron service is running"
            echo "  logs                                     - View recent cron logs"
            echo "  troubleshoot                             - Run troubleshooting checks"
            ;;
    esac
fi