// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:ios_permission/ios_permission.dart';
import 'package:ios_permission/ios_permission_platform_interface.dart';

class FakeIosPermissionPlatform
    with MockPlatformInterfaceMixin
    implements IosPermissionPlatform {
  @override
  Future<NativeCameraPermissionStatus> getCameraPermissionStatus() async {
    return NativeCameraPermissionStatus(
      status: IOSCameraPermissionStatus.authorized,
      canUseCamera: true,
      canRequest: false,
      needsSettings: false,
      description: 'Fake authorized',
      rawValue: 3,
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      deviceModel: 'iPhone',
      systemVersion: '17.0',
    );
  }

  @override
  Future<bool?> requestCameraPermission() async => true;

  @override
  Future<NativeLocationPermissionStatus> getLocationPermissionStatus() async {
    return NativeLocationPermissionStatus(
      status: IOSLocationPermissionStatus.authorizedWhenInUse,
      canUseLocation: true,
      canRequest: false,
      needsSettings: false,
      description: 'Fake authorized',
      rawValue: 4,
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      deviceModel: 'iPhone',
      systemVersion: '17.0',
      locationServicesEnabled: true,
      authorizationType: 'whenInUse',
    );
  }

  @override
  Future<bool?> requestLocationPermission() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use a fake platform implementation so tests do not rely on real iOS APIs.
  IosPermissionPlatform.instance = FakeIosPermissionPlatform();

  testWidgets('camera permission status test', (WidgetTester tester) async {
    // Test getting camera permission status
    final cameraStatus = await IosPermission.getCameraPermissionStatus();
    expect(cameraStatus, isNotNull);
    expect(cameraStatus.status, isA<IOSCameraPermissionStatus>());
  });

  testWidgets('camera permission request test', (WidgetTester tester) async {
    // Test requesting camera permission
    final result = await IosPermission.requestCameraPermission();
    expect(result, isA<bool?>());
  });
}
