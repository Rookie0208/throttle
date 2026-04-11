import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/auth/presentation/screens/signup_screen.dart';
import 'package:throttle_ui/app/main_screen.dart';
import 'package:throttle_ui/core/services/logger_service.dart';
import 'package:throttle_ui/features/auth/presentation/screens/otp_screen.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/features/auth/presentation/widgets/web_signin_stub.dart';

class LoginColors {
  static const Color primary = Color(0xff0047DE);
  static const Color background = Color(0xffF4F7FC);
  static const Color textPrimary = Color(0xff191B22);
  static const Color textSecondary = Color(0xff4F596E);
  static const Color border = Color(0x52B8C6DA);
  static const Color shadow = Color(0x14191B22);
}

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
      await Logger.warn("This is the second data : $result");
      if (result["success"]) {
        // Smooth slide transition
        if (!mounted) return;
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.speed_rounded,
                      color: colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  "THROTTLE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 40),

                // EMAIL
                TextField(
                  controller: emailController,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // LOGIN BUTTON
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.white,
                          )
                        : Text(
                            "Login",
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // OR separator
                Center(
                  child: Text(
                    "OR",
                    style: GoogleFonts.lexend(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: colorScheme.onSurface),
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

  Widget _buildSignupLink() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      },
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.lexend(
            color: LoginColors.textSecondary,
            fontSize: 14,
          ),
          children: const [
            TextSpan(text: "New to the trail? "),
            TextSpan(
              text: "Join the Pack",
              style: TextStyle(
                color: LoginColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const _LoginInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  State<_LoginInputField> createState() => _LoginInputFieldState();
}

class _LoginInputFieldState extends State<_LoginInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isFocused ? LoginColors.primary : LoginColors.border,
            width: _isFocused ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: LoginColors.shadow,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.isPassword,
          style: GoogleFonts.lexend(color: LoginColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.lexend(
              color: LoginColors.textSecondary.withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused
                  ? LoginColors.primary
                  : LoginColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}

class _SocialSyncCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialSyncCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LoginColors.border),
          boxShadow: const [
            BoxShadow(
              color: LoginColors.shadow,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: LoginColors.textPrimary, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.lexend(
                color: LoginColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
