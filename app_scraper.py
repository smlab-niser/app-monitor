#!/usr/bin/env python3
"""
App Store Scraper Helper
Provides better API handling for both Google Play Store and Apple App Store
Now uses google-play-scraper for reliable Google Play Store data
"""

import json
import sys
import requests
from urllib.parse import quote
import time
import re
from datetime import datetime
import argparse

# Import google-play-scraper
try:
    from google_play_scraper import app as gp_app
    from google_play_scraper.exceptions import NotFoundError, ExtraHTTPError
    GOOGLE_PLAY_SCRAPER_AVAILABLE = True
except ImportError:
    GOOGLE_PLAY_SCRAPER_AVAILABLE = False
    print("Warning: google-play-scraper not installed. Install with: pip install google-play-scraper")


class AppStoreScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
    
    def get_playstore_info(self, package_id, app_name):
        """Fetch app info from Google Play Store using google-play-scraper"""
        if not GOOGLE_PLAY_SCRAPER_AVAILABLE:
            return self._fallback_playstore_scraper(package_id, app_name)
        
        try:
            # Use google-play-scraper for reliable data
            app_data = gp_app(package_id, lang='en', country='us')
            
            # Format the size if available
            size_str = "N/A"
            if app_data.get('size'):
                size_str = app_data['size']
            elif app_data.get('androidVersion'):
                size_str = f"Varies with device"
            
            # Format the last updated date
            last_updated = "N/A"
            if app_data.get('updated'):
                try:
                    # The updated field is usually a timestamp or date
                    if isinstance(app_data['updated'], int):
                        last_updated = datetime.fromtimestamp(app_data['updated']).strftime('%Y-%m-%d')
                    else:
                        last_updated = str(app_data['updated'])
                except:
                    last_updated = str(app_data['updated'])
            
            result = {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": app_data.get('version', 'N/A'),
                "last_updated": last_updated,
                "size": size_str,
                "fetch_time": datetime.now().isoformat(),
                "status": "success",
                "url": app_data.get('url', f"https://play.google.com/store/apps/details?id={package_id}"),
                "developer": app_data.get('developer', 'N/A'),
                "rating": app_data.get('score', 'N/A'),
                "reviews": app_data.get('reviews', 'N/A'),
                "installs": app_data.get('installs', 'N/A'),
                "free": app_data.get('free', True),
                "price": app_data.get('price', 'Free' if app_data.get('free', True) else 'N/A')
            }
            
            return result
            
        except NotFoundError:
            return {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": "N/A",
                "last_updated": "N/A",
                "size": "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "error",
                "error": f"App not found: {package_id}"
            }
        except ExtraHTTPError as e:
            return {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": "N/A",
                "last_updated": "N/A",
                "size": "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "error",
                "error": f"HTTP Error: {str(e)}"
            }
        except Exception as e:
            return {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": "N/A",
                "last_updated": "N/A",
                "size": "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "error",
                "error": f"Unexpected error: {str(e)}"
            }
    
    def _fallback_playstore_scraper(self, package_id, app_name):
        """Fallback scraper when google-play-scraper is not available"""
        try:
            url = f"https://play.google.com/store/apps/details?id={package_id}&hl=en"
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            html = response.text
            
            # Improved regex patterns for different page layouts
            patterns = {
                'version': [
                    r'Current Version.*?<span[^>]*>([^<]+)</span>',
                    r'"(\d+(?:\.\d+)*)"[^>]*>Current Version',
                    r'Version.*?<span[^>]*>([^<]+)</span>',
                    r'<span[^>]*>Version</span>.*?<span[^>]*>([^<]+)</span>'
                ],
                'updated': [
                    r'Updated.*?<span[^>]*>([^<]+)</span>',
                    r'Last updated.*?<span[^>]*>([^<]+)</span>',
                    r'<span[^>]*>Updated</span>.*?<span[^>]*>([^<]+)</span>'
                ],
                'size': [
                    r'Size.*?<span[^>]*>([^<]+)</span>',
                    r'<span[^>]*>Size</span>.*?<span[^>]*>([^<]+)</span>'
                ]
            }
            
            def extract_with_patterns(field_patterns, html_content):
                for pattern in field_patterns:
                    match = re.search(pattern, html_content, re.DOTALL | re.IGNORECASE)
                    if match:
                        return match.group(1).strip()
                return "N/A"
            
            version = extract_with_patterns(patterns['version'], html)
            updated = extract_with_patterns(patterns['updated'], html)
            size = extract_with_patterns(patterns['size'], html)
            
            result = {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": version,
                "last_updated": updated,
                "size": size,
                "fetch_time": datetime.now().isoformat(),
                "status": "success",
                "url": url,
                "note": "Using fallback scraper - install google-play-scraper for better reliability"
            }
            
            return result
            
        except requests.exceptions.RequestException as e:
            return {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": "N/A",
                "last_updated": "N/A",
                "size": "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "error",
                "error": str(e)
            }
    
    def get_appstore_info(self, app_id, app_name):
        """Fetch app info from Apple App Store"""
        try:
            url = f"https://itunes.apple.com/lookup?id={app_id}"
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            if not data.get('results'):
                raise ValueError("No results found")
            
            app_data = data['results'][0]
            
            # Convert file size to readable format
            file_size = app_data.get('fileSizeBytes', 0)
            if file_size and isinstance(file_size, (int, float)):
                if file_size >= 1073741824:  # GB
                    size_str = f"{file_size / 1073741824:.1f} GB"
                elif file_size >= 1048576:  # MB
                    size_str = f"{file_size / 1048576:.1f} MB"
                elif file_size >= 1024:  # KB
                    size_str = f"{file_size / 1024:.1f} KB"
                else:
                    size_str = f"{file_size} bytes"
            else:
                size_str = "N/A"
            
            # Format the release date
            release_date = app_data.get('currentVersionReleaseDate', 'N/A')
            if release_date != 'N/A':
                try:
                    # Parse and format the date
                    parsed_date = datetime.fromisoformat(release_date.replace('Z', '+00:00'))
                    release_date = parsed_date.strftime('%Y-%m-%d')
                except:
                    pass  # Keep original format if parsing fails
            
            result = {
                "app_name": app_name,
                "app_id": app_id,
                "store": "Apple App Store",
                "version": app_data.get('version', 'N/A'),
                "last_updated": release_date,
                "size": size_str,
                "fetch_time": datetime.now().isoformat(),
                "status": "success",
                "bundle_id": app_data.get('bundleId', 'N/A'),
                "price": app_data.get('formattedPrice', 'N/A'),
                "url": app_data.get('trackViewUrl', 'N/A'),
                "developer": app_data.get('artistName', 'N/A'),
                "rating": app_data.get('averageUserRating', 'N/A'),
                "reviews": app_data.get('userRatingCount', 'N/A'),
                "genre": app_data.get('primaryGenreName', 'N/A')
            }
            
            return result
            
        except (requests.exceptions.RequestException, ValueError, KeyError) as e:
            return {
                "app_name": app_name,
                "app_id": app_id,
                "store": "Apple App Store",
                "version": "N/A",
                "last_updated": "N/A",
                "size": "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "error",
                "error": str(e)
            }
    
    def scrape_app(self, store, app_id, app_name):
        """Scrape app info from specified store"""
        if store.lower() == 'playstore':
            return self.get_playstore_info(app_id, app_name)
        elif store.lower() == 'appstore':
            return self.get_appstore_info(app_id, app_name)
        else:
            return {
                "app_name": app_name,
                "app_id": app_id,
                "store": store,
                "version": "N/A",
                "last_updated": "N/A",
                "size": "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "error",
                "error": f"Unknown store: {store}"
            }
    
    def get_app_details(self, store, app_id, app_name):
        """Get detailed app information (alias for scrape_app)"""
        return self.scrape_app(store, app_id, app_name)
    
    def bulk_scrape(self, apps_list):
        """Scrape multiple apps at once
        
        Args:
            apps_list: List of dictionaries with keys: store, app_id, app_name
        
        Returns:
            List of app information dictionaries
        """
        results = []
        for app in apps_list:
            result = self.scrape_app(
                app.get('store', ''),
                app.get('app_id', ''),
                app.get('app_name', '')
            )
            results.append(result)
            # Add a small delay to avoid rate limiting
            time.sleep(1)
        return results


def main():
    parser = argparse.ArgumentParser(description='Scrape app information from app stores')
    parser.add_argument('store', choices=['playstore', 'appstore'], help='App store to scrape')
    parser.add_argument('app_id', help='App ID or package name')
    parser.add_argument('app_name', help='App name')
    parser.add_argument('--output', '-o', help='Output file path')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    scraper = AppStoreScraper()
    
    if args.verbose:
        print(f"Scraping {args.store} for {args.app_name} ({args.app_id})")
    
    result = scraper.scrape_app(args.store, args.app_id, args.app_name)
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
        if args.verbose:
            print(f"Results saved to {args.output}")
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()