#!/usr/bin/env python3
"""
Test script for the updated app scraper
"""

import json
import time
from app_scraper import AppStoreScraper


def test_apps():
    """Test the scraper with popular apps"""
    
    test_cases = [
        # Google Play Store apps
        {
            "store": "playstore",
            "app_id": "com.flipkart.android",
            "app_name": "Flipkart"
        },
        {
            "store": "playstore", 
            "app_id": "com.amazon.mShop.android.shopping",
            "app_name": "Amazon Shopping"
        },
        {
            "store": "playstore",
            "app_id": "com.whatsapp",
            "app_name": "WhatsApp"
        },
        {
            "store": "playstore",
            "app_id": "com.instagram.android",
            "app_name": "Instagram"
        },
        # Apple App Store apps
        {
            "store": "appstore",
            "app_id": "1059655371",
            "app_name": "Instagram"
        },
        {
            "store": "appstore",
            "app_id": "310633997",
            "app_name": "WhatsApp"
        },
        {
            "store": "appstore",
            "app_id": "1440147259",
            "app_name": "AdGuard"
        }
    ]
    
    scraper = AppStoreScraper()
    results = []
    
    print("Testing App Store Scraper")
    print("=" * 50)
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{i}. Testing {test_case['app_name']} ({test_case['store']})")
        print("-" * 30)
        
        result = scraper.scrape_app(
            test_case['store'], 
            test_case['app_id'], 
            test_case['app_name']
        )
        
        results.append(result)
        
        # Print summary
        if result['status'] == 'success':
            print(f"✓ SUCCESS")
            print(f"  Version: {result['version']}")
            print(f"  Updated: {result['last_updated']}")
            print(f"  Size: {result['size']}")
            if 'developer' in result:
                print(f"  Developer: {result['developer']}")
        else:
            print(f"✗ FAILED: {result.get('error', 'Unknown error')}")
        
        # Small delay between requests
        time.sleep(2)
    
    print("\n" + "=" * 50)
    print("SUMMARY")
    print("=" * 50)
    
    successful = sum(1 for r in results if r['status'] == 'success')
    failed = len(results) - successful
    
    print(f"Total apps tested: {len(results)}")
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")
    print(f"Success rate: {successful/len(results)*100:.1f}%")
    
    # Save detailed results
    with open('test_results.json', 'w') as f:
        json.dump({
            'test_time': time.strftime('%Y-%m-%d %H:%M:%S'),
            'total_tests': len(results),
            'successful': successful,
            'failed': failed,
            'success_rate': successful/len(results)*100,
            'results': results
        }, f, indent=2)
    
    print(f"\nDetailed results saved to: test_results.json")
    
    # Show failed apps if any
    if failed > 0:
        print("\nFailed apps:")
        for result in results:
            if result['status'] == 'error':
                print(f"  - {result['app_name']} ({result['store']}): {result.get('error', 'Unknown error')}")


def test_bulk_scraping():
    """Test bulk scraping functionality"""
    print("\n" + "=" * 50)
    print("TESTING BULK SCRAPING")
    print("=" * 50)
    
    apps_list = [
        {"store": "playstore", "app_id": "com.flipkart.android", "app_name": "Flipkart"},
        {"store": "playstore", "app_id": "com.amazon.mShop.android.shopping", "app_name": "Amazon Shopping"},
        {"store": "appstore", "app_id": "1059655371", "app_name": "Instagram"},
    ]
    
    scraper = AppStoreScraper()
    
    print(f"Testing bulk scraping with {len(apps_list)} apps...")
    start_time = time.time()
    
    results = scraper.bulk_scrape(apps_list)
    
    end_time = time.time()
    elapsed = end_time - start_time
    
    successful = sum(1 for r in results if r['status'] == 'success')
    
    print(f"\nBulk scraping completed in {elapsed:.2f} seconds")
    print(f"Success rate: {successful}/{len(results)} ({successful/len(results)*100:.1f}%)")
    
    return results


if __name__ == "__main__":
    # Test individual scraping
    test_apps()
    
    # Test bulk scraping
    test_bulk_scraping()
    
    print("\n" + "=" * 50)
    print("All tests completed!")
    print("=" * 50)