#!/bin/bash

# Setup script for App Store Scraper
# This script installs dependencies and sets up the environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "App Store Scraper Setup"
echo "======================"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "ERROR: pip3 is not installed. Please install pip3 first."
    exit 1
fi

# Check if we're in a virtual environment
if [[ -z "${VIRTUAL_ENV}" ]]; then
    echo "WARNING: Not in a virtual environment. It's recommended to use a virtual environment."
    echo "Do you want to create one? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Creating virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        echo "Virtual environment created and activated."
    fi
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Check if jq is installed (needed for shell script)
if ! command -v jq &> /dev/null; then
    echo "WARNING: jq is not installed. Installing jq..."
    
    # Try to install jq based on the system
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        echo "ERROR: Could not install jq automatically. Please install it manually."
        echo "Visit: https://stedolan.github.io/jq/download/"
        exit 1
    fi
fi

# Make scripts executable
chmod +x app_scraper.py
chmod +x app_monitor.sh
chmod +x test_scraper.py

# Create sample configuration if it doesn't exist
if [[ ! -f "$SCRIPT_DIR/app_config.json" ]]; then
    echo "Creating sample configuration file..."
    cat << 'EOF' > "$SCRIPT_DIR/app_config.json"
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
            "store": "playstore",
            "id": "com.whatsapp",
            "name": "WhatsApp"
        },
        {
            "store": "playstore",
            "id": "com.instagram.android",
            "name": "Instagram"
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
            "store": "appstore",
            "id": "1440147259",
            "name": "AdGuard"
        }
    ]
}
EOF
    echo "Sample configuration created: app_config.json"
fi

# Test the installation
echo ""
echo "Testing installation..."
python3 -c "
import requests
import google_play_scraper
import json
print('✓ All Python dependencies installed successfully')
"

# Run a quick test
echo ""
echo "Running quick test..."
python3 app_scraper.py playstore com.whatsapp "WhatsApp" > /tmp/test_output.json

if jq -e '.status == "success"' /tmp/test_output.json > /dev/null; then
    echo "✓ Test passed! The scraper is working correctly."
else
    echo "⚠ Test had issues, but installation appears complete."
    echo "Check the output:"
    cat /tmp/test_output.json
fi

rm -f /tmp/test_output.json

echo ""
echo "Setup completed successfully!"
echo ""
echo "Usage examples:"
echo "  # Test individual app:"
echo "  python3 app_scraper.py playstore com.flipkart.android Flipkart"
echo ""
echo "  # Run monitoring script:"
echo "  ./app_monitor.sh"
echo ""
echo "  # Run comprehensive tests:"
echo "  python3 test_scraper.py"
echo ""
echo "Configuration file: app_config.json"
echo "Add your apps to monitor in this file."