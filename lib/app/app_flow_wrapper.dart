import 'package:backpackr/features/auth/repositories/auth_service.dart';
import 'package:backpackr/features/auth/views/login_screen.dart';
import 'package:backpackr/features/onboarding/views/intro_screen.dart';
import 'package:backpackr/features/travelers/views/travelers_screen.dart';
import 'package:backpackr/shared/services/app_flow_service.dart';
import 'package:flutter/material.dart';

class AppFlowWrapper extends StatefulWidget {
  const AppFlowWrapper({super.key});

  @override
  State<AppFlowWrapper> createState() => _AppFlowWrapperState();
}

class _AppFlowWrapperState extends State<AppFlowWrapper> {
  final AppFlowService _appFlowService = AppFlowService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const TravelersScreen();
        } else {
          return FutureBuilder<bool>(
            future: _appFlowService.hasSeenIntro(),
            builder: (context, introSnapshot) {
              if (introSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (introSnapshot.data == true) {
                return const LoginScreen();
              } else {
                return const IntroScreen();
              }
            },
          );
        }
      },
    );
  }
}
