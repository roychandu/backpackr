import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_permission_platform_interface.dart';

/// An implementation of [IosPermissionPlatform] that uses method channels.
class MethodChannelIosPermission extends IosPermissionPlatform {
  /// The method channel used to interact with the native camera permissions.
  @visibleForTesting
  final cameraMethodChannel = const MethodChannel('com.aviatorapp.native_permissions');

  /// The method channel used to interact with the native location permissions.
  @visibleForTesting
  final locationMethodChannel = const MethodChannel('com.aviatorapp.native_location_permissions');

  @override
  Future<NativeCameraPermissionStatus> getCameraPermissionStatus() async {
    try {
      final dynamic result = await cameraMethodChannel.invokeMethod('getCameraPermissionStatus');
      
      if (result is Map<String, dynamic>) {
        return NativeCameraPermissionStatus.fromNative(result);
      } else if (result is Map) {
        final Map<String, dynamic> convertedResult = Map<String, dynamic>.from(result);
        return NativeCameraPermissionStatus.fromNative(convertedResult);
      } else {
        // Fallback for unexpected result types
        return NativeCameraPermissionStatus(
          status: IOSCameraPermissionStatus.unknown,
          canUseCamera: false,
          canRequest: false,
          needsSettings: false,
          description: 'Unexpected result type: ${result.runtimeType}',
          rawValue: -1,
          timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
        );
      }
    } catch (e) {
      debugPrint('Error getting camera permission status: $e');
      return NativeCameraPermissionStatus(
        status: IOSCameraPermissionStatus.unknown,
        canUseCamera: false,
        canRequest: false,
        needsSettings: false,
        description: 'Error: $e',
        rawValue: -1,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      );
    }
  }

  @override
  Future<bool?> requestCameraPermission() async {
    try {
      final bool? result = await cameraMethodChannel.invokeMethod('requestCameraPermission');
      return result;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return null;
    }
  }

  @override
  Future<NativeLocationPermissionStatus> getLocationPermissionStatus() async {
    try {
      final dynamic result = await locationMethodChannel.invokeMethod('getLocationPermissionStatus');
      
      if (result is Map<String, dynamic>) {
        return NativeLocationPermissionStatus.fromNative(result);
      } else if (result is Map) {
        final Map<String, dynamic> convertedResult = Map<String, dynamic>.from(result);
        return NativeLocationPermissionStatus.fromNative(convertedResult);
      } else {
        // Fallback for unexpected result types
        return NativeLocationPermissionStatus(
          status: IOSLocationPermissionStatus.unknown,
          canUseLocation: false,
          canRequest: false,
          needsSettings: false,
          description: 'Unexpected result type: ${result.runtimeType}',
          rawValue: -1,
          timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
        );
      }
    } catch (e) {
      debugPrint('Error getting location permission status: $e');
      return NativeLocationPermissionStatus(
        status: IOSLocationPermissionStatus.unknown,
        canUseLocation: false,
        canRequest: false,
        needsSettings: false,
        description: 'Error: $e',
        rawValue: -1,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      );
    }
  }

  @override
  Future<bool?> requestLocationPermission() async {
    try {
      final bool? result = await locationMethodChannel.invokeMethod('requestLocationPermission');
      return result;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return null;
    }
  }
}
