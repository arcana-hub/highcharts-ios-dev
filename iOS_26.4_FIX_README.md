# iOS 26.4 Compatibility Fix

## Issue
GitHub Issue: https://github.com/highcharts/highcharts-ios/issues/465

Charts were showing a white screen on iOS 26.4 Beta due to WKWebView security changes that prevent loading JavaScript files from framework bundles when using `loadHTMLString:baseURL:`.

## Solution
Changed the loading mechanism to use `loadFileURL:allowingReadAccessToURL:` with absolute file:// URLs.

## Files Changed
1. **HIChartView.m**
   - Added `loadHTMLWithFileURL:` method
   - Writes HTML to temp file and loads with read access to framework bundle

2. **HIGHTML.m**
   - Modified `prepareJavaScript:` to generate absolute file:// URLs
   - Updated `injectJavaScriptToHTML` to convert CSS and lib paths

3. **HIWKSyncedWebView.m**
   - Added `loadFileURL:allowingReadAccessToURL:` override

## Testing
The XCFramework has been rebuilt with the fix at:
- `Highcharts/Highcharts/XCFramework/Highcharts.xcframework`
- `Release/Highcharts.xcframework`

### How to Test
1. Use the rebuilt XCFramework in your app
2. Run on iOS 26.4 Beta simulator/device
3. Charts should render correctly (no white screen)

## Compatibility
- ✅ iOS 26.4 Beta
- ✅ iOS 26.3 and earlier (backward compatible)
- ✅ No breaking changes to public API

## Build Details
- Built for: iOS Device (arm64) + iOS Simulator (arm64/x86_64)
- Build Date: March 27, 2026
- Code Signing: Disabled for development builds
