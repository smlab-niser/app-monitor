# App Store Scraper

A robust Python-based tool for monitoring app updates across Google Play Store and Apple App Store. This tool uses the reliable `google-play-scraper` library for Google Play Store data and the iTunes API for Apple App Store data.

## Features

- **Reliable Google Play Store scraping** using `google-play-scraper` library
- **Apple App Store support** via iTunes API
- **Bulk monitoring** of multiple apps
- **Detailed app information** including version, size, ratings, and more
- **Automated monitoring** with shell script
- **Error handling** and fallback mechanisms
- **JSON output** for easy integration
- **Rate limiting** to avoid being blocked

## Installation

### Quick Setup

```bash
# Clone or download the files
# Run the setup script
chmod +x setup.sh
./setup.sh
```

### Manual Setup

1. **Install Python dependencies:**
   ```bash
   pip3 install -r requirements.txt
   ```

2. **Install system dependencies:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # macOS
   brew install jq
   
   # CentOS/RHEL
   sudo yum install jq
   ```

3. **Make scripts executable:**
   ```bash
   chmod +x app_scraper.py app_monitor.sh test_scraper.py
   ```

## Usage

### Individual App Scraping

```bash
# Google Play Store
python3 app_scraper.py playstore com.flipkart.android "Flipkart"

# Apple App Store
python3 app_scraper.py appstore 1059655371 "Instagram"

# Save to file
python3 app_scraper.py playstore com.whatsapp "WhatsApp" --output whatsapp_info.json
```

### Bulk Monitoring

1. **Configure apps to monitor:**
   Edit `app_config.json`:
   ```json
   {
     "apps": [
       {
         "store": "playstore",
         "id": "com.flipkart.android",
         "name": "Flipkart"
       },
       {
         "store": "appstore",
         "id": "1059655371",
         "name": "Instagram"
       }
     ]
   }
   ```

2. **Run monitoring:**
   ```bash
   ./app_monitor.sh
   ```

3. **Advanced options:**
   ```bash
   # Custom config file
   ./app_monitor.sh --config my_apps.json
   
   # Email notifications
   ./app_monitor.sh --email user@example.com
   
   # Verbose output
   ./app_monitor.sh --verbose
   ```

### Testing

```bash
# Run comprehensive tests
python3 test_scraper.py

# Test specific app
python3 app_scraper.py playstore com.whatsapp "WhatsApp" --verbose
```

## Output Format

The scraper returns detailed JSON information:

### Google Play Store Output
```json
{
  "app_name": "Flipkart",
  "package_id": "com.flipkart.android",
  "store": "Google Play Store",
  "version": "8.9.0",
  "last_updated": "2024-01-15",
  "size": "Varies with device",
  "developer": "Flipkart",
  "rating": 4.3,
  "reviews": 5000000,
  "installs": "500,000,000+",
  "price": "Free",
  "url": "https://play.google.com/store/apps/details?id=com.flipkart.android",
  "fetch_time": "2024-01-20T10:30:00.000Z",
  "status": "success"
}
```

### Apple App Store Output
```json
{
  "app_name": "Instagram",
  "app_id": "1059655371",
  "store": "Apple App Store",
  "version": "309.0",
  "last_updated": "2024-01-18",
  "size": "123.4 MB",
  "developer": "Instagram, Inc.",
  "rating": 4.8,
  "reviews": 2500000,
  "price": "Free",
  "bundle_id": "com.burbn.instagram",
  "url": "https://apps.apple.com/us/app/instagram/id1059655371",
  "fetch_time": "2024-01-20T10:30:00.000Z",
  "status": "success"
}
```

## Finding App IDs

### Google Play Store
The package ID is in the URL:
```
https://play.google.com/store/apps/details?id=com.flipkart.android
                                            ^^^^^^^^^^^^^^^^^^^^
```

### Apple App Store
The app ID is in the URL:
```
https://apps.apple.com/us/app/instagram/id1059655371
                                         ^^^^^^^^^^
```

## Common Issues & Solutions

### 1. Google Play Store Scraping Fails

**Problem:** Getting "N/A" values or errors for Google Play Store apps.

**Solution:**
- Ensure `google-play-scraper` is installed: `pip3 install google-play-scraper`
- Check if the package ID is correct
- Some apps might be region-restricted

### 2. Rate Limiting

**Problem:** Getting blocked by app stores.

**Solution:**
- The scraper includes built-in rate limiting (2-second delays)
- For bulk operations, consider increasing delays
- Use VPN if necessary

### 3. Apple App Store Issues

**Problem:** App not found or incorrect data.

**Solution:**
- Verify the app ID is correct
- Some apps might not be available in all regions
- Check if the app is still published

## Advanced Usage

### Custom Python Integration

```python
from app_scraper import AppStoreScraper

scraper = AppStoreScraper()

# Single app
result = scraper.scrape_app('playstore', 'com.whatsapp', 'WhatsApp')

# Bulk scraping
apps = [
    {'store': 'playstore', 'app_id': 'com.flipkart.android', 'app_name': 'Flipkart'},
    {'store': 'appstore', 'app_id': '1059655371', 'app_name': 'Instagram'}
]
results = scraper.bulk_scrape(apps)
```

### Automated Monitoring with Cron

```bash
# Add to crontab for daily monitoring
# crontab -e
0 9 * * * /path/to/app_monitor.sh --email user@example.com
```

## Dependencies

- **Python 3.6+**
- **requests** - HTTP library
- **google-play-scraper** - Google Play Store scraping
- **jq** - JSON processing (for shell script)
- **curl** - HTTP requests (for shell script)

## Troubleshooting

### Import Error
```bash
# If you get import errors
pip3 install --upgrade requests google-play-scraper
```

### Permission Denied
```bash
# Make scripts executable
chmod +x app_scraper.py app_monitor.sh
```

### JSON Parse Error
```bash
# Check if jq is installed
which jq
# Install if missing
sudo apt-get install jq
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is provided as-is for educational and monitoring purposes. Please respect the terms of service of Google Play Store and Apple App Store when using this tool.

## Changelog

### Version 2.0
- Added `google-play-scraper` library support
- Improved error handling
- Enhanced data extraction
- Added bulk scraping functionality
- Better rate limiting
- Comprehensive testing suite

### Version 1.0
- Initial release with basic scraping functionality