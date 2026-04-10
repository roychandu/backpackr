# iOS Permission Plugin

A Flutter plugin that provides reliable, native iOS camera and location permission handling that bypasses unreliable permission_handler plugins. It uses direct platform APIs for maximum reliability and comprehensive permission status information.

## Features

- ✅ **Native iOS camera permission handling** via `AVCaptureDevice`
- ✅ **Native iOS location permission handling** via `CLLocationManager`
- ✅ **Comprehensive permission status information** including device metadata
- ✅ **Multiple permission request strategies** for maximum reliability
- ✅ **Smart permission handling** with automatic fallback strategies
- ✅ **Detailed debug logging** for troubleshooting
- ✅ **Testing functions** to verify permission system functionality

## Why This Plugin?

The popular `permission_handler` plugin can be unreliable on iOS, especially for camera and location permissions. This plugin solves that by:

1. **Direct Native API Calls**: Uses `AVCaptureDevice.requestAccess()` and `CLLocationManager.requestWhenInUseAuthorization()` directly
2. **Comprehensive Status Information**: Returns detailed permission status with device info, timestamps, and actionable flags
3. **Multiple Request Strategies**: Includes fallback methods for stubborn permission dialogs
4. **iOS-Focused**: Designed specifically for iOS reliability (Android support can be added later)

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  ios_permission: ^0.0.1
```

## Usage

### Camera Permissions

```dart
import 'package:ios_permission/ios_permission.dart';

// Get detailed camera permission status
final cameraStatus = await IosPermission.getCameraPermissionStatus();
print('Camera status: ${cameraStatus.status.rawValue}');
print('Can use camera: ${cameraStatus.canUseCamera}');
print('Can request: ${cameraStatus.canRequest}');
print('Needs settings: ${cameraStatus.needsSettings}');

// Smart camera permission request (recommended)
final granted = await IosPermission.smartCameraPermissionRequest();
if (granted) {
  // Camera permission granted, proceed with camera initialization
} else {
  // Handle permission denied
}

// Simple permission request
final result = await IosPermission.requestCameraPermission();

// Quick status check
final canUse = await IosPermission.canUseCameraNow();
```

### Location Permissions

```dart
// Get detailed location permission status
final locationStatus = await IosPermission.getLocationPermissionStatus();
print('Location status: ${locationStatus.status.rawValue}');
print('Can use location: ${locationStatus.canUseLocation}');

// Smart location permission request (recommended)
final granted = await IosPermission.smartLocationPermissionRequest();

// Standard permission request
final result = await IosPermission.requestLocationPermission();

// Quick status check
final canUse = await IosPermission.canUseLocationNow();
```

### Testing and Debugging

```dart
// Run comprehensive camera permission test
await IosPermission.testCameraPermission();

// Run comprehensive location permission test
await IosPermission.testLocationPermission();
```

## Permission Status Information

The plugin provides detailed status information:

### Camera Permission Status
- `notDetermined`: User hasn't been asked yet
- `authorized`: Permission granted
- `denied`: Permission denied by user
- `restricted`: Restricted by device policy
- `unknown`: Error or unknown state

### Location Permission Status
- `notDetermined`: User hasn't been asked yet
- `authorizedWhenInUse`: Permission granted when app is in use
- `authorizedAlways`: Permission granted always
- `denied`: Permission denied by user
- `restricted`: Restricted by device policy
- `unknown`: Error or unknown state

Each status includes:
- `canUse*`: Whether the permission is granted right now
- `canRequest`: Whether permission dialog can be shown
- `needsSettings`: Whether user must go to Settings to grant permission
- `description`: Human-readable description
- `rawValue`: Native platform raw value
- `timestamp`: When status was retrieved
- `deviceModel`: Device model information
- `systemVersion`: iOS version

## Platform Support

- ✅ **iOS**: Full native support
- ❌ **Android**: Not implemented (returns error status)
- ❌ **Web/Desktop**: Not supported

## iOS Setup

Add these permissions to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos and videos.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find travelers near you.</string>
```

## Example App

Run the example app to see the plugin in action:

```bash
cd example
flutter run
```

The example app demonstrates:
- Permission status checking
- Permission requesting
- Smart permission handling
- Comprehensive testing
- Real-time status updates

## Troubleshooting

1. **Permission dialog not showing**: Ensure Info.plist has the required permission descriptions
2. **Status not updating**: Use the refresh functionality in the example app
3. **Unexpected behavior**: Enable debug logging and check console output
4. **Testing**: Use the built-in test functions to verify functionality

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.