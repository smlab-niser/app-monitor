# App Monitor System

A comprehensive Linux-based monitoring system that tracks app updates, version numbers, and sizes across Google Play Store and Apple App Store for popular applications.

## Features

- **Multi-Store Support**: Monitors both Google Play Store and Apple App Store
- **Comprehensive App Coverage**: Tracks 60+ popular apps across categories:
  - Finance & Banking (Google Pay, PhonePe, Paytm, HDFC, SBI, ICICI)
  - Entertainment (Netflix, Disney+ Hotstar, Prime Video, YouTube)
  - Messaging (WhatsApp, Signal, Telegram)
  - Shopping (Amazon, Flipkart, Blinkit, Swiggy, Zomato)
  - Productivity (Google Maps, Docs, Office suite, Slack, Zoom)
  - Social Media (Instagram, Facebook, Twitter, TikTok, LinkedIn)
- **Automated Scheduling**: Configurable cron jobs for regular monitoring
- **Multiple Output Formats**: JSON results with timestamps and metadata
- **Error Handling**: Robust error handling and logging
- **Email Notifications**: Optional email alerts for monitoring completion
- **Rate Limiting**: Built-in delays to avoid being blocked by stores

## Installation

### Quick Installation

1. **Download all files** to your preferred directory:
   ```bash
   mkdir ~/app-monitor
   cd ~/app-monitor
   # Copy all the script files here
   ```

2. **Run the setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

### Manual Installation

1. **Install dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install curl jq python3 python3-pip cron mailutils
   
   # CentOS/RHEL
   sudo yum install curl jq python3 python3-pip crontabs mailx
   
   # Install Python dependencies
   pip3 install --user requests
   ```

2. **Set up files**:
   ```bash
   chmod +x app_monitor.sh
   chmod +x app_scraper.py
   chmod +x cron_config.sh
   ```

## Configuration

### App Configuration

Edit `app_config.json` to add/remove apps or modify categories. The configuration includes:

- **App Name**: Display name for the app
- **Store**: Either "playstore" or "appstore"
- **ID**: Package ID for Play Store or App ID for App Store
- **Category**: App category for organization

### Monitoring Configuration

Create `monitor_config.conf` for additional settings:

```bash
NOTIFICATION_EMAIL="your-email@example.com"
LOG_RETENTION_DAYS=30
MAX_PARALLEL_REQUESTS=3
REQUEST_DELAY=2
OUTPUT_FORMAT="json"
BACKUP_RESULTS=true
BACKUP_DIR="./backups"
```

## Usage

### Manual Execution

Run the monitor once:
```bash
./app_monitor.sh
```

### Automated Scheduling

#### Using Cron (Recommended)

1. **Every 6 hours** (recommended):
   ```bash
   crontab -e
   # Add this line:
   0 */6 * * * cd /home/user/app-monitor && ./app_monitor.sh >> ./cron.log 2>&1
   ```

2. **Daily at 2 AM**:
   ```bash
   0 2 * * * cd /home/user/app-monitor && ./app_monitor.sh >> ./cron.log 2>&1
   ```

3. **Using the cron helper script**:
   ```bash
   ./cron_config.sh install /path/to/app_monitor.sh "0 */6 * * *" "your-email@example.com"
   ```

#### Using Systemd (Alternative)

The setup script can create systemd services for more advanced scheduling.

## Output

### JSON Output Format

Results are saved in timestamped JSON files:

```json
{
  "monitoring_time": "2025-07-06T10:30:00Z",
  "apps": [
    {
      "app_name": "WhatsApp",
      "package_id": "com.whatsapp",
      "store": "Google Play Store",
      "version": "2.24.15.75",
      "last_updated": "July 1, 2025",
      "size": "65.2 MB",
      "fetch_time": "2025-07-06T10:30:15Z",
      "status": "success"
    }
  ]
}
```

### Log Files

- `app_monitor.log`: Main application logs
- `cron.log`: Cron job execution logs

## Troubleshooting

### Common Issues

1. **Script not executing**:
   ```bash
   chmod +x app_monitor.sh
   ```

2. **Cron job not running**:
   ```bash
   # Check cron service
   sudo systemctl status cron  # Ubuntu/Debian
   sudo systemctl status crond # CentOS/RHEL
   
   # Check cron logs
   ./cron_config.sh logs
   ```

3. **Rate limiting issues**:
   - Increase `REQUEST_DELAY` in configuration
   - Reduce `MAX_PARALLEL_REQUESTS`

4. **Missing dependencies**:
   ```bash
   # Check if all tools are installed
   which curl jq python3
   ```

### Troubleshooting Script

Run the built-in troubleshooting:
```bash
./cron_config.sh troubleshoot
```

## API Rate Limits

### Google Play Store
- No official API; uses web scraping
- Implement delays between requests
- May require IP rotation for high-volume usage

### Apple App Store
- Uses official iTunes Search API
- Rate limit: ~20 requests per minute
- More reliable than Play Store scraping

## Security Considerations

- **No Authentication Required**: Uses public APIs and web scraping
- **Rate Limiting**: Implements delays to be respectful to services
- **Data Privacy**: Only collects publicly available app information
- **No Personal Data**: Does not access or store personal information

## Customization

### Adding New Apps

1. Find the app's package ID (Play Store) or App ID (App Store)
2. Add to `app_config.json`:
   ```json
   {
     "name": "App Name",
     "store": "playstore",
     "id": "com.example.app",
     "category": "Category"
   }
   ```

### Modifying Categories

Edit the `category` field in `app_config.json` to organize apps differently.

### Custom Notification Scripts

Modify the notification section in `app_monitor.sh` to integrate with:
- Slack webhooks
- Discord notifications
- Custom APIs
- SMS services

## Performance

### Resource Usage
- **Memory**: ~50MB during execution
- **CPU**: Minimal impact
- **Network**: ~1-2MB per monitoring cycle
- **Storage**: ~1MB per day for logs and results

### Optimization Tips
1. Monitor only essential apps
2. Adjust monitoring frequency based on needs
3. Use log rotation to manage disk space
4. Consider running during off-peak hours

## Contributing

To add support for more apps or improve functionality:

1. Fork the repository
2. Add new app configurations
3. Test thoroughly
4. Submit pull requests

## License

This project is open-source and available under the MIT License.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review log files for error messages
3. Ensure all dependencies are installed
4. Verify app IDs and package names are correct

## Version History

- **v1.0**: Initial release with basic monitoring
- **v1.1**: Added Python helper script
- **v1.2**: Enhanced error handling and logging
- **v1.3**: Added systemd service support
- **v1.4**: Improved rate limiting and reliability

## Disclaimer

This tool is for educational and monitoring purposes only. Please respect the terms of service of Google Play Store and Apple App Store. The authors are not responsible for any misuse or violations of service terms.