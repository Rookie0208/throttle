import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:throttle_ui/app/theme/app_theme.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/app/main_screen.dart';
import 'package:throttle_ui/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env", isOptional: true);
  await AuthService.initGoogleSignIn();
  await ThemeController.instance.load();
  final hasSession = await AuthService.restoreSession();
  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.hasSession});

  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildTheme(ThemeController.instance.theme),
          themeAnimationDuration: const Duration(milliseconds: 280),
          themeAnimationCurve: Curves.easeOutCubic,
          home: hasSession ? const MainScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}
