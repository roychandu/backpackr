import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ios_permission/ios_permission.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _cameraStatus = 'Unknown';
  String _locationStatus = 'Unknown';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  Future<void> _refreshPermissionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get camera permission status
      final cameraStatus = await IosPermission.getCameraPermissionStatus();
      final locationStatus = await IosPermission.getLocationPermissionStatus();

      setState(() {
        _cameraStatus =
            '${cameraStatus.status.rawValue} - ${cameraStatus.description}';
        _locationStatus =
            '${locationStatus.status.rawValue} - ${locationStatus.description}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cameraStatus = 'Error: $e';
        _locationStatus = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await IosPermission.smartCameraPermissionRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? '✅ Camera permission granted!'
                : '❌ Camera permission denied',
          ),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
      await _refreshPermissionStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting camera permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCameraPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await IosPermission.testCameraPermission();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera permission test completed - check console logs',
          ),
          backgroundColor: Colors.blue,
        ),
      );
      await _refreshPermissionStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing camera permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await IosPermission.smartLocationPermissionRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? '✅ Location permission granted!'
                : '❌ Location permission denied',
          ),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
      await _refreshPermissionStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting location permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await IosPermission.testLocationPermission();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission test completed - check console logs',
          ),
          backgroundColor: Colors.blue,
        ),
      );
      await _refreshPermissionStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing location permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('iOS Permission Plugin Example'),
          backgroundColor: Colors.blue,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshPermissionStatus,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Camera Permission',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Status: $_cameraStatus',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _requestCameraPermission,
                                  child: const Text('Request Permission'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _testCameraPermission,
                                  child: const Text('Run Test'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Location Permission',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Status: $_locationStatus',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _requestLocationPermission,
                                  child: const Text('Request Permission'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _testLocationPermission,
                                  child: const Text('Run Test'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.grey[100],
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instructions:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Tap "Request Permission" to show the native permission dialog',
                            ),
                            Text(
                              '• Tap "Run Test" to run comprehensive permission tests',
                            ),
                            Text('• Pull down to refresh permission status'),
                            Text(
                              '• Check console logs for detailed debug information',
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Note: This plugin only works on iOS. On other platforms, it will show error status.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
