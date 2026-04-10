import 'dart:async';
import 'package:backpackr/screens/auth_screen/login_screen.dart';
import 'package:backpackr/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backsate.dart';

class BackFormPage extends ConsumerStatefulWidget {
  const BackFormPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BackFormPage> createState() => _BackFormPageState();
}

class _BackFormPageState extends ConsumerState<BackFormPage> {
  Widget? mainScreen;

  @override
  void initState() {
    super.initState();
    setupOrientationPreferences();
  }

  void setupOrientationPreferences() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: buildContent());
  }

  Widget buildContent() {
    return Consumer(
      builder: (context, ref, child) {
        final backValue = ref.watch(backProvidr);
        debugPrint('buildContent for backProvidr called');
        return FutureBuilder(
          future: backValue.canShow
              ? Future.value()
              : ref.read(backProvidr.notifier).checkForUpdates(),
          builder: (context, snapshot) {
            return getContent(backValue);
          },
        );
      },
    );
  }

  Widget getContent(BackState backValue) {
    if (backValue.displayView == null) {
      return Center(
        child: SizedBox(
          height: 100.0,
          width: 100.0,
          child: CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
          ),
        ),
      );
    }

    mainScreen = backValue.type == 1
        ? Container(
            color: Colors.black,
            child: SafeArea(bottom: false, child: backValue.displayView!),
          )
        : const SizedBox.shrink();

    return Stack(
      children: [
        backValue.type == 1 ? LoginScreen() : SplashScreen(),
        //splash screen when webview is closed
        mainScreen!, //webview
      ],
    );
  }
}

// Alternative: Using ConsumerWidget (stateless approach)
class BackFormPageStateless extends ConsumerWidget {
  const BackFormPageStateless({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backValue = ref.watch(backProvidr);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: backValue.canShow
            ? Future.value()
            : ref.read(backProvidr.notifier).checkForUpdates(),
        builder: (context, snapshot) {
          return _buildUpUI(backValue);
        },
      ),
    );
  }

  Widget _buildUpUI(BackState backValue) {
    if (backValue.displayView == null) {
      return Center(
        child: SizedBox(
          height: 100.0,
          width: 100.0,
          child: CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
          ),
        ),
      );
    }

    final mainScreen = backValue.type == 1
        ? Container(
            color: Colors.black,
            child: SafeArea(bottom: false, child: backValue.displayView!),
          )
        : const SizedBox.shrink();

    return Stack(
      children: [
        backValue.type == 1 ? LoginScreen() : SplashScreen(),
        mainScreen,
      ],
    );
  }
}
