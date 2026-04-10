import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ios_permission_platform_interface.dart';

// Export the classes from platform interface for easy access
export 'ios_permission_platform_interface.dart'
    show
        IOSCameraPermissionStatus,
        NativeCameraPermissionStatus,
        IOSLocationPermissionStatus,
        NativeLocationPermissionStatus;

/// iOS Permission Plugin
///
/// A Flutter plugin that provides reliable, native iOS camera and location
/// permission handling that bypasses unreliable permission_handler plugins.
/// It uses direct platform APIs for maximum reliability.
///
/// Features:
/// - Native iOS camera permission handling via AVCaptureDevice
/// - Native iOS location permission handling via CLLocationManager
/// - Comprehensive permission status information
/// - Multiple permission request strategies for maximum reliability
/// - Detailed device and system information
class IosPermission {
  // MARK: - Camera Permission Methods

  /// Get comprehensive native camera permission status
  ///
  /// Returns detailed status information including whether camera can be used,
  /// whether permission can be requested, device information, and more.
  ///
  /// This method works on iOS only. On other platforms, it will return an
  /// error status.
  static Future<NativeCameraPermissionStatus> getCameraPermissionStatus() {
    return IosPermissionPlatform.instance.getCameraPermissionStatus();
  }

  /// Request native camera permission
  ///
  /// Shows the native iOS camera permission dialog and returns the result.
  /// This method bypasses the unreliable permission_handler plugin and
  /// calls AVCaptureDevice.requestAccess() directly.
  ///
  /// Returns:
  /// - true: User granted camera permission
  /// - false: User denied camera permission
  /// - null: Error occurred during request
  static Future<bool?> requestCameraPermission() {
    return IosPermissionPlatform.instance.requestCameraPermission();
  }

  /// Quick check if camera can be used right now
  ///
  /// This is a convenience method that checks the current permission status
  /// and returns a simple boolean indicating whether camera initialization
  /// would succeed right now.
  static Future<bool> canUseCameraNow() async {
    final status = await getCameraPermissionStatus();
    return status.canUseCamera;
  }

  /// Smart camera permission request with automatic handling
  ///
  /// This method implements intelligent permission handling:
  /// - If already authorized: Returns true immediately
  /// - If not determined: Requests permission
  /// - If denied: Tries to request again (iOS allows this)
  /// - If restricted: Returns false (cannot be changed)
  ///
  /// Returns true if camera can be used after this call.
  static Future<bool> smartCameraPermissionRequest() async {
    if (!Platform.isIOS) {
      debugPrint(
        '📱 Smart camera permission: Not supported on ${Platform.operatingSystem}',
      );
      return false;
    }

    debugPrint('📱 Smart camera permission request starting...');

    // First check current status
    final currentStatus = await getCameraPermissionStatus();
    debugPrint('📱 Current status: ${currentStatus.status.rawValue}');

    // Handle different scenarios
    switch (currentStatus.status) {
      case IOSCameraPermissionStatus.authorized:
        debugPrint('📱 ✅ Camera already authorized - ready to use!');
        return true;

      case IOSCameraPermissionStatus.notDetermined:
        debugPrint('📱 🤔 Permission not asked yet - requesting...');
        final granted = await requestCameraPermission();
        debugPrint(
          '📱 Request result: ${granted == true ? "GRANTED" : "DENIED"}',
        );
        return granted == true;

      case IOSCameraPermissionStatus.denied:
        debugPrint(
          '📱 ❌ Permission denied - can try requesting again or direct to settings',
        );
        if (currentStatus.canRequest) {
          debugPrint('📱 🔄 Trying to request again...');
          final granted = await requestCameraPermission();
          if (granted != true) {
            debugPrint('📱 ⚙️ Still denied - user should go to Settings');
          }
          return granted == true;
        }
        return false;

      case IOSCameraPermissionStatus.restricted:
        debugPrint(
          '📱 🔒 Camera access restricted by device policy - cannot request',
        );
        return false;

      case IOSCameraPermissionStatus.unknown:
        debugPrint('📱  Unknown permission status - something went wrong');
        return false;
    }
  }

  // MARK: - Testing and Debug Methods

  /// Comprehensive test function to verify native camera permission functionality
  ///
  /// This function runs a complete test of the native permission system:
  /// 1. Gets initial permission status
  /// 2. Requests permission if possible
  /// 3. Gets final permission status
  /// 4. Compares results and logs detailed information
  ///
  /// Use this function to verify that the native permission system is working
  /// correctly on your device.
  static Future<void> testCameraPermission() async {
    debugPrint('🧪 ========== Testing Native Camera Permission ==========');

    // Get initial status
    debugPrint('🧪 Step 1: Getting initial permission status...');
    final initialStatus = await getCameraPermissionStatus();
    debugPrint('🧪 Initial Status: $initialStatus');

    // Test permission request if possible
    if (initialStatus.canRequest) {
      debugPrint('🧪 Step 2: Requesting camera permission...');
      final result = await requestCameraPermission();
      debugPrint('🧪 Permission request result: $result');

      // Get status after request
      debugPrint('🧪 Step 3: Getting status after request...');
      final finalStatus = await getCameraPermissionStatus();
      debugPrint('🧪 Final Status: $finalStatus');

      // Compare results
      debugPrint('🧪 Step 4: Comparison:');
      debugPrint(
        '  - Status changed: ${initialStatus.status != finalStatus.status}',
      );
      debugPrint('  - Can use camera now: ${finalStatus.canUseCamera}');
      debugPrint('  - Permission granted: ${result == true}');
    } else {
      debugPrint(
        '🧪 Step 2: Cannot request permission (already determined or restricted)',
      );
      if (initialStatus.needsSettings) {
        debugPrint('🧪 User needs to go to Settings to grant permission');
      }
    }

    debugPrint('🧪 ================= Test Complete ===================');
  }

  // MARK: - Location Permission Methods

  /// Get comprehensive native location permission status
  ///
  /// Returns detailed status information including whether location can be used,
  /// whether permission can be requested, location services status, and more.
  ///
  /// This method works on iOS only. On other platforms, it will return an
  /// error status.
  static Future<NativeLocationPermissionStatus> getLocationPermissionStatus() {
    return IosPermissionPlatform.instance.getLocationPermissionStatus();
  }

  /// Request native location permission
  ///
  /// Shows the native iOS location permission dialog and returns the result.
  /// This method bypasses the unreliable permission_handler plugin and
  /// calls CLLocationManager.requestWhenInUseAuthorization() directly.
  ///
  /// Returns:
  /// - true: User granted location permission
  /// - false: User denied location permission
  /// - null: Error occurred during request
  static Future<bool?> requestLocationPermission() {
    return IosPermissionPlatform.instance.requestLocationPermission();
  }

  /// Quick check if location can be used right now
  ///
  /// This is a convenience method that checks the current permission status
  /// and returns a simple boolean indicating whether location services
  /// would succeed right now.
  static Future<bool> canUseLocationNow() async {
    final status = await getLocationPermissionStatus();
    return status.canUseLocation;
  }

  /// Smart location permission request with automatic handling
  ///
  /// This method implements intelligent permission handling:
  /// - If already authorized: Returns true immediately
  /// - If not determined: Requests permission
  /// - If denied: Tries to request again (iOS allows this)
  /// - If restricted: Returns false (cannot be changed)
  ///
  /// Returns true if location can be used after this call.
  static Future<bool> smartLocationPermissionRequest() async {
    if (!Platform.isIOS) {
      debugPrint(
        '📱 Smart location permission: Not supported on ${Platform.operatingSystem}',
      );
      return false;
    }

    debugPrint('📱 Smart location permission request starting...');

    // First check current status
    final currentStatus = await getLocationPermissionStatus();
    debugPrint('📱 Current status: ${currentStatus.status.rawValue}');

    // Handle different scenarios
    switch (currentStatus.status) {
      case IOSLocationPermissionStatus.authorizedWhenInUse:
      case IOSLocationPermissionStatus.authorizedAlways:
        debugPrint('📱 ✅ Location already authorized - ready to use!');
        return true;

      case IOSLocationPermissionStatus.notDetermined:
        debugPrint('📱 🤔 Permission not asked yet - requesting...');
        final granted = await requestLocationPermission();
        debugPrint(
          '📱 Request result: ${granted == true ? "GRANTED" : "DENIED"}',
        );
        return granted == true;

      case IOSLocationPermissionStatus.denied:
        debugPrint(
          '📱 ❌ Permission denied - can try requesting again or direct to settings',
        );
        if (currentStatus.canRequest) {
          debugPrint('📱 🔄 Trying to request again...');
          final granted = await requestLocationPermission();
          if (granted != true) {
            debugPrint('📱 ⚙️ Still denied - user should go to Settings');
          }
          return granted == true;
        }
        return false;

      case IOSLocationPermissionStatus.restricted:
        debugPrint(
          '📱 🔒 Location access restricted by device policy - cannot request',
        );
        return false;

      case IOSLocationPermissionStatus.unknown:
        debugPrint('📱 ❓ Unknown permission status - something went wrong');
        return false;
    }
  }

  /// Comprehensive test function to verify native location permission functionality
  static Future<void> testLocationPermission() async {
    debugPrint('🧪 ========== Testing Native Location Permission ==========');

    // Get initial status
    debugPrint('🧪 Step 1: Getting initial permission status...');
    final initialStatus = await getLocationPermissionStatus();
    debugPrint('🧪 Initial Status: $initialStatus');

    // Test permission request if possible
    if (initialStatus.canRequest) {
      debugPrint('🧪 Step 2: Requesting location permission...');
      final result = await requestLocationPermission();
      debugPrint('🧪 Permission request result: $result');

      // Get status after request
      debugPrint('🧪 Step 3: Getting status after request...');
      final finalStatus = await getLocationPermissionStatus();
      debugPrint('🧪 Final Status: $finalStatus');

      // Compare results
      debugPrint('🧪 Step 4: Comparison:');
      debugPrint(
        '  - Status changed: ${initialStatus.status != finalStatus.status}',
      );
      debugPrint('  - Can use location now: ${finalStatus.canUseLocation}');
      debugPrint('  - Permission granted: ${result == true}');
    } else {
      debugPrint(
        '🧪 Step 2: Cannot request permission (already determined or restricted)',
      );
      if (initialStatus.needsSettings) {
        debugPrint('🧪 User needs to go to Settings to grant permission');
      }
    }

    debugPrint('🧪 ================= Test Complete ===================');
  }
}
