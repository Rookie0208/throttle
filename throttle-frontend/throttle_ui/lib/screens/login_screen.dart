import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/web_signin.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import '../services/logger_service.dart';
import 'otp_screen.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  StreamSubscription? _googleAuthSubscription;
  bool _isProcessingGoogle = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleAuthSubscription = AuthService.googleSignIn.authenticationEvents
          .listen((event) async {
            if (event is GoogleSignInAuthenticationEventSignIn &&
                !_isProcessingGoogle) {
              final account = event.user;
              final auth = account.authentication;
              if (auth.idToken != null) {
                _handleWebGoogleAuth(auth.idToken!);
              }
            }
          });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _googleAuthSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleWebGoogleAuth(String idToken) async {
    if (_isProcessingGoogle) return;
    setState(() {
      _isProcessingGoogle = true;
      isLoading = true;
    });

    try {
      final result = await AuthService.initiateGoogleAuth(webIdToken: idToken);

      if (result["success"]) {
        if (result["data"] != null && result["data"]["token"] != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, _, _) => const MainScreen(),
                transitionsBuilder: (_, animation, _, child) {
                  final offsetAnimation =
                      Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                      );
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
            );
          }
        } else if (result["data"] != null &&
            result["data"]["requiresRegistration"] == true) {
          if (mounted) {
            if (result["data"]["otpSent"] == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpScreen(googleData: result["data"]),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SignupScreen(
                    isGoogleRegistration: true,
                    googleData: result["data"],
                  ),
                ),
              );
            }
          }
        }
      } else {
        showError(result["message"] ?? "Google Sign-In failed");
      }
    } catch (e) {
      showError("Google Sign-In failed. Please check network.");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingGoogle = false;
          isLoading = false;
        });
      }
      await AuthService.googleSignIn.disconnect();
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty) {
      showError("Email is required");
      return;
    }

    if (passwordController.text.isEmpty) {
      showError("Password is required");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await Logger.warn("This is the second data : " + result.toString());
      if (result["success"]) {
        // Smooth slide transition
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, _, _) => const MainScreen(),
            transitionsBuilder: (_, animation, _, child) {
              final offsetAnimation =
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  );
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      } else {
        showError(result["message"] ?? "Login failed");
      }
    } catch (e) {
      // Any network or unexpected error
      showError("Login failed. Please check your credentials or network.");
    } finally {
      // ✅ Make sure spinner always stops
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> googleLogin() async {
    setState(() => isLoading = true);

    try {
      final result = await AuthService.initiateGoogleAuth();

      if (mounted) setState(() => isLoading = false);

      if (result["success"]) {
        // If 'token' exists, it's a returning user login
        if (result["data"] != null && result["data"]["token"] != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, _, _) => const MainScreen(),
                transitionsBuilder: (_, animation, _, child) {
                  final offsetAnimation =
                      Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                      );
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
            );
          }
        }
        // If no token but requires registration = true, new user OTP flow
        else if (result["data"] != null &&
            result["data"]["requiresRegistration"] == true) {
          if (mounted) {
            if (result["data"]["otpSent"] == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpScreen(googleData: result["data"]),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SignupScreen(
                    isGoogleRegistration: true,
                    googleData: result["data"],
                  ),
                ),
              );
            }
          }
        }
      } else {
        showError(result["message"] ?? "Google Sign-In failed");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      showError("Google Sign-In failed. Please check network.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                // LOGO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 6,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.speed, color: AppColors.primary, size: 30),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 6,
                      color: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "THROTTLE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // EMAIL
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 15),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 25),

                // LOGIN BUTTON
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: AppColors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // OR separator
                const Center(
                  child: Text("OR", style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 15),

                // GOOGLE SIGN-IN
                buildGoogleSignInButton(
                  onPressed: isLoading ? () {} : googleLogin,
                ),
                const SizedBox(height: 12),

                // APPLE SIGN-IN
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.apple),
                  label: const Text("Sign in with Apple"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 25),

                // SIGN UP TEXT
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.white),
                        ),
                        Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
