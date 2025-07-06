#!/bin/bash

# App Monitor Setup Script
# Sets up the app monitoring system with all dependencies

set -e

# Configuration
INSTALL_DIR="$HOME/app-monitor"
SERVICE_NAME="app-monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        error "Cannot detect OS"
        exit 1
    fi
    log "Detected OS: $OS $VERSION"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y curl jq python3 python3-pip cron mailutils
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum install -y curl jq python3 python3-pip crontabs mailx
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install -y curl jq python3 python3-pip crontabs mailx
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -S --needed curl jq python python-pip cronie mailutils
    else
        error "Unsupported package manager"
        exit 1
    fi
    
    # Install Python dependencies
    pip3 install --user requests
    
    log "Dependencies installed successfully"
}

# Create installation directory
create_install_dir() {
    log "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
}

# Download or create scripts
setup_scripts() {
    log "Setting up scripts..."
    
    # If scripts are not already present, create them
    if [[ ! -f "app_monitor.sh" ]]; then
        warn "app_monitor.sh not found. Please ensure you have the main script."
        exit 1
    fi
    
    if [[ ! -f "app_config.json" ]]; then
        warn "app_config.json not found. Please ensure you have the configuration file."
        exit 1
    fi
    
    if [[ ! -f "app_scraper.py" ]]; then
        warn "app_scraper.py not found. Please ensure you have the Python helper script."
        exit 1
    fi
    
    # Make scripts executable
    chmod +x app_monitor.sh
    chmod +x app_scraper.py
    
    log "Scripts configured successfully"
}

# Setup cron job
setup_cron() {
    log "Setting up cron job..."
    
    # Default schedule: Run every 6 hours
    read -p "Enter cron schedule (default: 0 */6 * * * for every 6 hours): " CRON_SCHEDULE
    CRON_SCHEDULE=${CRON_SCHEDULE:-"0 */6 * * *"}
    
    # Ask for email notifications
    read -p "Enter email for notifications (optional): " EMAIL
    
    # Create cron job entry
    CRON_JOB="$CRON_SCHEDULE cd $INSTALL_DIR && ./app_monitor.sh"
    if [[ -n "$EMAIL" ]]; then
        CRON_JOB="$CRON_JOB && echo 'App monitoring completed' | mail -s 'App Monitor Report' $EMAIL"
    fi
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    
    log "Cron job added: $CRON_JOB"
}

# Create systemd service (optional)
setup_systemd_service() {
    read -p "Create systemd service for more advanced scheduling? (y/n): " CREATE_SERVICE
    
    if [[ "$CREATE_SERVICE" =~ ^[Yy]$ ]]; then
        log "Creating systemd service..."
        
        # Create service file
        sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=App Monitor Service
After=network.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/app_monitor.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

        # Create timer file
        sudo tee /etc/systemd/system/${SERVICE_NAME}.timer > /dev/null <<EOF
[Unit]
Description=Run App Monitor every 6 hours
Requires=${SERVICE_NAME}.service

[Timer]
OnCalendar=*-*-* 0,6,12,18:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

        # Enable and start timer
        sudo systemctl daemon-reload
        sudo systemctl enable ${SERVICE_NAME}.timer
        sudo systemctl start ${SERVICE_NAME}.timer
        
        log "Systemd service and timer created and started"
    fi
}

# Create configuration file
create_config() {
    log "Creating configuration file..."
    
    cat > "$INSTALL_DIR/monitor_config.conf" <<EOF
# App Monitor Configuration
NOTIFICATION_EMAIL="$EMAIL"
LOG_RETENTION_DAYS=30
MAX_PARALLEL_REQUESTS=3
REQUEST_DELAY=2
OUTPUT_FORMAT="json"
BACKUP_RESULTS=true
BACKUP_DIR="$INSTALL_DIR/backups"
EOF
    
    # Create backup directory
    mkdir -p "$INSTALL_DIR/backups"
    
    log "Configuration file created"
}

# Create log rotation
setup_log_rotation() {
    log "Setting up log rotation..."
    
    sudo tee /etc/logrotate.d/app-monitor > /dev/null <<EOF
$INSTALL_DIR/app_monitor.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF
    
    log "Log rotation configured"
}

# Test the installation
test_installation() {
    log "Testing installation..."
    
    # Test a single app
    log "Testing with WhatsApp (Play Store)..."
    if python3 "$INSTALL_DIR/app_scraper.py" playstore com.whatsapp WhatsApp > /dev/null 2>&1; then
        log "Test successful!"
    else
        warn "Test failed. Please check the configuration."
    fi
    
    log "You can run a full test with: $INSTALL_DIR/app_monitor.sh"
}

# Main installation function
main() {
    log "Starting App Monitor installation..."
    
    check_root
    detect_os
    install_dependencies
    create_install_dir
    setup_scripts
    setup_cron
    setup_systemd_service
    create_config
    setup_log_rotation
    test_installation
    
    log "Installation completed successfully!"
    log "App Monitor is now installed in: $INSTALL_DIR"
    log "Logs will be available in: $INSTALL_DIR/app_monitor.log"
    log "Results will be saved in: $INSTALL_DIR/"
    
    echo ""
    echo "=== Manual Commands ==="
    echo "Run manually: $INSTALL_DIR/app_monitor.sh"
    echo "Check cron jobs: crontab -l"
    echo "Check systemd timer: sudo systemctl status ${SERVICE_NAME}.timer"
    echo "View logs: tail -f $INSTALL_DIR/app_monitor.log"
    echo "======================="
}

# Run main function
main "$@"