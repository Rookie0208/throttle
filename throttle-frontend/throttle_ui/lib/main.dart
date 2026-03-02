import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AuthService.initGoogleSignIn();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const primaryColor = Color(0xfffe6603);
  static const backgroundColor = Color(0xff0f1114);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(primary: primaryColor),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xff1a1c20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
