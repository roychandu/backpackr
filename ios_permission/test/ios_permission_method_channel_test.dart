import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_permission/ios_permission_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIosPermission platform = MethodChannelIosPermission();
  const MethodChannel cameraChannel = MethodChannel('com.aviatorapp.native_permissions');
  const MethodChannel locationChannel = MethodChannel('com.aviatorapp.native_location_permissions');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      cameraChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getCameraPermissionStatus') {
          return {
            'status': 'authorized',
            'canUseCamera': true,
            'canRequest': false,
            'needsSettings': false,
            'description': 'Camera access granted by user',
            'rawValue': 3,
            'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
            'deviceModel': 'Test Device',
            'systemVersion': '17.0',
          };
        } else if (methodCall.method == 'requestCameraPermission') {
          return true;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      locationChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getLocationPermissionStatus') {
          return {
            'status': 'authorizedWhenInUse',
            'canUseLocation': true,
            'canRequest': false,
            'needsSettings': false,
            'description': 'Location access granted when app is in use',
            'rawValue': 4,
            'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
            'deviceModel': 'Test Device',
            'systemVersion': '17.0',
            'locationServicesEnabled': true,
            'authorizationType': 'whenInUse',
          };
        } else if (methodCall.method == 'requestLocationPermission') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(cameraChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(locationChannel, null);
  });

  test('getCameraPermissionStatus', () async {
    final status = await platform.getCameraPermissionStatus();
    expect(status.status.rawValue, 'authorized');
    expect(status.canUseCamera, true);
  });

  test('requestCameraPermission', () async {
    final result = await platform.requestCameraPermission();
    expect(result, true);
  });

  test('getLocationPermissionStatus', () async {
    final status = await platform.getLocationPermissionStatus();
    expect(status.status.rawValue, 'authorizedWhenInUse');
    expect(status.canUseLocation, true);
  });

  test('requestLocationPermission', () async {
    final result = await platform.requestLocationPermission();
    expect(result, true);
  });
}
