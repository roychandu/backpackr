import 'package:backpackr/backpform/backdpage.dart';
import 'package:backpackr/common_widgets/app_colors.dart';
import 'package:backpackr/provider/purchase_provider.dart';
import 'package:backpackr/screens/auth_screen/login_screen.dart';
import 'package:backpackr/screens/home_screen/home_screen.dart';
import 'package:backpackr/screens/intro_screen/intro_screen.dart';
import 'package:backpackr/services/app_flow_service.dart';
import 'package:backpackr/services/auth_service.dart';
import 'package:backpackr/services/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

setPortait() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    if (kReleaseMode) {
      FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.appAttest,
      );
    }
  } catch (e) {}
  try {
    await NotificationService.initialize();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Error initializing notification service: $e');
  }
  setPortait();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return riverpod.ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            lazy: false,
            create: (_) => InAppPurchaseProvider(),
          ),
        ],
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yuvon Globe',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
          ),
          navigatorKey: appNavigatorKey,
          home: BackFormPage(),
          routes: {
            '/intro': (context) => const IntroScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}

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

        // If user authentication state changes, determine the appropriate screen
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in - always go to home screen
          // Business setup will be checked when user tries to create an invoice
          return const HomeScreen();
        } else {
          // User is not logged in - check if they've seen intro
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
