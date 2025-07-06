#!/usr/bin/env python3
"""
App Store Scraper Helper
Provides better API handling for both Google Play Store and Apple App Store
"""

import json
import sys
import requests
from urllib.parse import quote
import time
import re
from datetime import datetime
import argparse


class AppStoreScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
    
    def get_playstore_info(self, package_id, app_name):
        """Fetch app info from Google Play Store"""
        try:
            url = f"https://play.google.com/store/apps/details?id={package_id}&hl=en"
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            
            html = response.text
            
            # Extract version info using regex
            version_pattern = r'Current Version.*?<span[^>]*>([^<]+)</span>'
            updated_pattern = r'Updated.*?<span[^>]*>([^<]+)</span>'
            size_pattern = r'Size.*?<span[^>]*>([^<]+)</span>'
            
            version_match = re.search(version_pattern, html, re.DOTALL)
            updated_match = re.search(updated_pattern, html, re.DOTALL)
            size_match = re.search(size_pattern, html, re.DOTALL)
            
            # Alternative patterns for different page layouts
            if not version_match:
                version_pattern = r'"(\d+(?:\.\d+)*)"[^>]*>Current Version'
                version_match = re.search(version_pattern, html)
            
            result = {
                "app_name": app_name,
                "package_id": package_id,
                "store": "Google Play Store",
                "version": version_match.group(1).strip() if version_match else "N/A",
                "last_updated": updated_match.group(1).strip() if updated_match else "N/A",
                "size": size_match.group(1).strip() if size_match else "N/A",
                "fetch_time": datetime.now().isoformat(),
                "status": "success",
                "url": url
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
            
            result = {
                "app_name": app_name,
                "app_id": app_id,
                "store": "Apple App Store",
                "version": app_data.get('version', 'N/A'),
                "last_updated": app_data.get('currentVersionReleaseDate', 'N/A'),
                "size": size_str,
                "fetch_time": datetime.now().isoformat(),
                "status": "success",
                "bundle_id": app_data.get('bundleId', 'N/A'),
                "price": app_data.get('formattedPrice', 'N/A'),
                "url": app_data.get('trackViewUrl', 'N/A')
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


def main():
    parser = argparse.ArgumentParser(description='Scrape app information from app stores')
    parser.add_argument('store', choices=['playstore', 'appstore'], help='App store to scrape')
    parser.add_argument('app_id', help='App ID or package name')
    parser.add_argument('app_name', help='App name')
    parser.add_argument('--output', '-o', help='Output file path')
    
    args = parser.parse_args()
    
    scraper = AppStoreScraper()
    result = scraper.scrape_app(args.store, args.app_id, args.app_name)
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()