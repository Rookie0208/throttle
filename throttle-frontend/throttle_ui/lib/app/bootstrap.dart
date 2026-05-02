import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:throttle_ui/core/resources/frontend_resource_config.dart';
import 'package:throttle_ui/app/theme/app_theme.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await FrontendResourceConfig.instance.load();
  await AuthService.initGoogleSignIn();
  await ThemeController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        FrontendResourceConfig.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildTheme(ThemeController.instance.theme),
          themeAnimationDuration: const Duration(milliseconds: 280),
          themeAnimationCurve: Curves.easeOutCubic,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
