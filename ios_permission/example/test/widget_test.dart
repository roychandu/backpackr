// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:ios_permission/ios_permission_platform_interface.dart';
import '../lib/main.dart';

class FakeIosPermissionPlatform
    with MockPlatformInterfaceMixin
    implements IosPermissionPlatform {
  @override
  Future<NativeCameraPermissionStatus> getCameraPermissionStatus() async {
    return const NativeCameraPermissionStatus(
      status: IOSCameraPermissionStatus.authorized,
      canUseCamera: true,
      canRequest: false,
      needsSettings: false,
      description: 'Fake authorized',
      rawValue: 3,
      timestamp: 0,
      deviceModel: 'iPhone',
      systemVersion: '17.0',
    );
  }

  @override
  Future<bool?> requestCameraPermission() async => true;

  @override
  Future<NativeLocationPermissionStatus> getLocationPermissionStatus() async {
    return const NativeLocationPermissionStatus(
      status: IOSLocationPermissionStatus.authorizedWhenInUse,
      canUseLocation: true,
      canRequest: false,
      needsSettings: false,
      description: 'Fake authorized',
      rawValue: 4,
      timestamp: 0,
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
  testWidgets('Verify Platform version', (WidgetTester tester) async {
    // Ensure the app uses a fake platform so tests run off-device.
    IosPermissionPlatform.instance = FakeIosPermissionPlatform();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the main app bar title is shown.
    expect(find.text('iOS Permission Plugin Example'), findsOneWidget);

    // Verify that a Scaffold from Material is present in the widget tree.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
