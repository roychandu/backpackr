import 'package:flutter_test/flutter_test.dart';
import 'package:ios_permission/ios_permission.dart';
import 'package:ios_permission/ios_permission_platform_interface.dart';
import 'package:ios_permission/ios_permission_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIosPermissionPlatform
    with MockPlatformInterfaceMixin
    implements IosPermissionPlatform {
  @override
  Future<NativeCameraPermissionStatus> getCameraPermissionStatus() {
    return Future.value(
      NativeCameraPermissionStatus(
        status: IOSCameraPermissionStatus.authorized,
        canUseCamera: true,
        canRequest: false,
        needsSettings: false,
        description: 'Test camera permission',
        rawValue: 3,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      ),
    );
  }

  @override
  Future<bool?> requestCameraPermission() => Future.value(true);

  @override
  Future<NativeLocationPermissionStatus> getLocationPermissionStatus() {
    return Future.value(
      NativeLocationPermissionStatus(
        status: IOSLocationPermissionStatus.authorizedWhenInUse,
        canUseLocation: true,
        canRequest: false,
        needsSettings: false,
        description: 'Test location permission',
        rawValue: 4,
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      ),
    );
  }

  @override
  Future<bool?> requestLocationPermission() => Future.value(true);
}

void main() {
  final IosPermissionPlatform initialPlatform = IosPermissionPlatform.instance;

  test('$MethodChannelIosPermission is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIosPermission>());
  });

  test('camera permission status', () async {
    MockIosPermissionPlatform fakePlatform = MockIosPermissionPlatform();
    IosPermissionPlatform.instance = fakePlatform;

    final status = await IosPermission.getCameraPermissionStatus();
    expect(status.status, IOSCameraPermissionStatus.authorized);
    expect(status.canUseCamera, true);
  });

  test('location permission status', () async {
    MockIosPermissionPlatform fakePlatform = MockIosPermissionPlatform();
    IosPermissionPlatform.instance = fakePlatform;

    final status = await IosPermission.getLocationPermissionStatus();
    expect(status.status, IOSLocationPermissionStatus.authorizedWhenInUse);
    expect(status.canUseLocation, true);
  });

  test('camera permission request', () async {
    MockIosPermissionPlatform fakePlatform = MockIosPermissionPlatform();
    IosPermissionPlatform.instance = fakePlatform;

    final result = await IosPermission.requestCameraPermission();
    expect(result, true);
  });

  test('location permission request', () async {
    MockIosPermissionPlatform fakePlatform = MockIosPermissionPlatform();
    IosPermissionPlatform.instance = fakePlatform;

    final result = await IosPermission.requestLocationPermission();
    expect(result, true);
  });
}
