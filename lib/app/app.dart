import 'package:backpackr/app/app_flow_wrapper.dart';
import 'package:backpackr/features/auth/views/login_screen.dart';
import 'package:backpackr/features/onboarding/views/intro_screen.dart';
import 'package:backpackr/features/premium/controllers/purchase_controller.dart';
import 'package:backpackr/features/travelers/views/travelers_screen.dart';
import 'package:backpackr/shared/services/theme_service.dart';
import 'package:backpackr/shared/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:get/get.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

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
          title: 'Backpackr',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF131313),
            useMaterial3: true,
          ),
          themeMode: ThemeService.to.theme,
          navigatorKey: appNavigatorKey,
          home: home ?? const AppFlowWrapper(),
          routes: {
            '/intro': (context) => const IntroScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const TravelersScreen(),
          },
        ),
      ),
    );
  }
}
