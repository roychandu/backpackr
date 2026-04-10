import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_permission_method_channel.dart';

// Camera Permission Status Classes
enum IOSCameraPermissionStatus {
  notDetermined('notDetermined'),
  authorized('authorized'),
  denied('denied'),
  restricted('restricted'),
  unknown('unknown');

  const IOSCameraPermissionStatus(this.rawValue);
  final String rawValue;

  static IOSCameraPermissionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'notdetermined':
        return IOSCameraPermissionStatus.notDetermined;
      case 'authorized':
        return IOSCameraPermissionStatus.authorized;
      case 'denied':
        return IOSCameraPermissionStatus.denied;
      case 'restricted':
        return IOSCameraPermissionStatus.restricted;
      default:
        return IOSCameraPermissionStatus.unknown;
    }
  }

  bool get isGranted => this == IOSCameraPermissionStatus.authorized;
  bool get canRequest => this == IOSCameraPermissionStatus.notDetermined || this == IOSCameraPermissionStatus.denied;
  bool get needsSettings => this == IOSCameraPermissionStatus.denied;
}

class NativeCameraPermissionStatus {
  final IOSCameraPermissionStatus status;
  final bool canUseCamera;
  final bool canRequest;
  final bool needsSettings;
  final String description;
  final int rawValue;
  final double timestamp;
  final String? deviceModel;
  final String? systemVersion;

  const NativeCameraPermissionStatus({
    required this.status,
    required this.canUseCamera,
    required this.canRequest,
    required this.needsSettings,
    required this.description,
    required this.rawValue,
    required this.timestamp,
    this.deviceModel,
    this.systemVersion,
  });

  factory NativeCameraPermissionStatus.fromNative(Map<String, dynamic> data) {
    return NativeCameraPermissionStatus(
      status: IOSCameraPermissionStatus.fromString(data['status']),
      canUseCamera: data['canUseCamera'] ?? false,
      canRequest: data['canRequest'] ?? false,
      needsSettings: data['needsSettings'] ?? false,
      description: data['description'] ?? 'Unknown status',
      rawValue: data['rawValue'] ?? -1,
      timestamp: data['timestamp'] ?? 0.0,
      deviceModel: data['deviceModel'],
      systemVersion: data['systemVersion'],
    );
  }
}

// Location Permission Status Classes
enum IOSLocationPermissionStatus {
  notDetermined('notDetermined'),
  restricted('restricted'),
  denied('denied'),
  authorizedWhenInUse('authorizedWhenInUse'),
  authorizedAlways('authorizedAlways'),
  unknown('unknown');

  const IOSLocationPermissionStatus(this.rawValue);
  final String rawValue;

  static IOSLocationPermissionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'notdetermined':
        return IOSLocationPermissionStatus.notDetermined;
      case 'restricted':
        return IOSLocationPermissionStatus.restricted;
      case 'denied':
        return IOSLocationPermissionStatus.denied;
      case 'authorizedwheninuse':
        return IOSLocationPermissionStatus.authorizedWhenInUse;
      case 'authorizedalways':
        return IOSLocationPermissionStatus.authorizedAlways;
      default:
        return IOSLocationPermissionStatus.unknown;
    }
  }

  bool get isGranted => this == IOSLocationPermissionStatus.authorizedWhenInUse || this == IOSLocationPermissionStatus.authorizedAlways;
  bool get canRequest => this == IOSLocationPermissionStatus.notDetermined || this == IOSLocationPermissionStatus.denied;
  bool get needsSettings => this == IOSLocationPermissionStatus.denied || this == IOSLocationPermissionStatus.restricted;
}

class NativeLocationPermissionStatus {
  final IOSLocationPermissionStatus status;
  final bool canUseLocation;
  final bool canRequest;
  final bool needsSettings;
  final String description;
  final int rawValue;
  final double timestamp;
  final String? deviceModel;
  final String? systemVersion;
  final bool? locationServicesEnabled;
  final String? authorizationType;

  const NativeLocationPermissionStatus({
    required this.status,
    required this.canUseLocation,
    required this.canRequest,
    required this.needsSettings,
    required this.description,
    required this.rawValue,
    required this.timestamp,
    this.deviceModel,
    this.systemVersion,
    this.locationServicesEnabled,
    this.authorizationType,
  });

  factory NativeLocationPermissionStatus.fromNative(Map<String, dynamic> data) {
    return NativeLocationPermissionStatus(
      status: IOSLocationPermissionStatus.fromString(data['status']),
      canUseLocation: data['canUseLocation'] ?? false,
      canRequest: data['canRequest'] ?? false,
      needsSettings: data['needsSettings'] ?? false,
      description: data['description'] ?? 'Unknown status',
      rawValue: data['rawValue'] ?? -1,
      timestamp: data['timestamp'] ?? 0.0,
      deviceModel: data['deviceModel'],
      systemVersion: data['systemVersion'],
      locationServicesEnabled: data['locationServicesEnabled'],
      authorizationType: data['authorizationType'],
    );
  }
}

abstract class IosPermissionPlatform extends PlatformInterface {
  /// Constructs a IosPermissionPlatform.
  IosPermissionPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosPermissionPlatform _instance = MethodChannelIosPermission();

  /// The default instance of [IosPermissionPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosPermission].
  static IosPermissionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosPermissionPlatform] when
  /// they register themselves.
  static set instance(IosPermissionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Camera permission methods
  Future<NativeCameraPermissionStatus> getCameraPermissionStatus() {
    throw UnimplementedError('getCameraPermissionStatus() has not been implemented.');
  }

  Future<bool?> requestCameraPermission() {
    throw UnimplementedError('requestCameraPermission() has not been implemented.');
  }

  // Location permission methods
  Future<NativeLocationPermissionStatus> getLocationPermissionStatus() {
    throw UnimplementedError('getLocationPermissionStatus() has not been implemented.');
  }

  Future<bool?> requestLocationPermission() {
    throw UnimplementedError('requestLocationPermission() has not been implemented.');
  }
}
