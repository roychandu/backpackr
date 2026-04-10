import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

// Constants
const String baseUrl = "https://rest.yuvonglobe-app.info/";
const String tripId = "6755545951";
const String cUrl = 'https://yuvonglobe-app.info/terms_of_use/';
const String inviceApp = 'globeSection';
const String client = 'globeValue';
// checkForUpdates

// State class
class BackState {
  final int type;
  final WebViewWidget? displayView;
  final bool canShow;
  final bool isInitialScreen;

  const BackState({
    required this.type,
    this.displayView,
    required this.canShow,
    required this.isInitialScreen,
  });

  factory BackState.initial() =>
      const BackState(type: 1, canShow: false, isInitialScreen: true);

  BackState copyWith({
    int? type,
    WebViewWidget? displayView,
    bool? canShow,
    bool? isInitialScreen,
    SharedPreferences? prefs,
  }) {
    return BackState(
      type: type ?? this.type,
      displayView: displayView ?? this.displayView,
      canShow: canShow ?? this.canShow,
      isInitialScreen: isInitialScreen ?? this.isInitialScreen,
    );
  }
}

// Notifier class
class BackStateNotifier extends StateNotifier<BackState> {
  BackStateNotifier() : super(BackState.initial());

  void updateType(int newType) {
    state = state.copyWith(type: newType);
  }

  Future<bool> checkForUpdates() async {
    debugPrint('checkForUpdates for riverpod called');
    try {
      final user = await specify();
      await handle(user);
    } catch (ex) {
      state = state.copyWith(type: 2, canShow: true);
    }
    return true;
  }

  Future<String> specify() async {
    if (state.canShow) return "";

    try {

      ///New code
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Accept': '*/*',
          'x-app-id': '$tripId',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Error', 408),
      );
      ///Old code
      // final response = await http
      //     .post(
      //       Uri.parse(baseUrl),
      //       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      //       body: 'tripId=$tripId', // Can use any parameter name
      //     )
      //     .timeout(
      //       const Duration(seconds: 10),
      //       onTimeout: () => http.Response('Error', 408),
      //     );

      debugPrint('response rokwn: ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'];
      }
    } catch (error) {
      debugPrint('Error occurred: $error');
    }

    return "";
  }

  Future<void> handle(String parameter) async {
    if (state.canShow) return;

    try {
      final firebaseResult = await _initialiseFirebase(parameter);
      debugPrint('firebaseResult: $firebaseResult');
      if (!firebaseResult) {
        state = state.copyWith(
          type: 2,
          canShow: true,
          displayView: WebViewWidget(controller: WebViewController()),
        );
        return;
      }

      if (firebaseResult) {
        state = state.copyWith(
          type: 1,
          displayView: _createWebView(),
          canShow: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        type: 2,
        canShow: true,
        displayView: WebViewWidget(controller: WebViewController()),
      );
    }
  }

  WebViewWidget _createWebView() {
    return WebViewWidget(
      controller: WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'flutterChannel',
          onMessageReceived: (p0) async {
            state = state.copyWith(type: 2, canShow: true);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (error) async {
              if (error.errorType == WebResourceErrorType.connect) {
                state = state.copyWith(type: 2, canShow: true);
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(cUrl)),
    );
  }
}

// Provider
final backProvidr = StateNotifierProvider<BackStateNotifier, BackState>((ref) {
  return BackStateNotifier();
});

Future<bool> _initialiseFirebase(String key) async {
  final _database = FirebaseDatabase.instance.ref();
  if (key.isEmpty) return false;

  try {
    final snapshot = await _database.child(inviceApp).child(key).get();

    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data[client] ?? false;
    }
  } catch (error) {
    debugPrint("Data Error: $error");
  }

  return false;
}
