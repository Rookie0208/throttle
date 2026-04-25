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
import 'package:throttle_ui/app/theme/theme_controller.dart';

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
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final textSecondary = theme.textPrimary.withValues(alpha: 0.65);
        final borderSideColor = const Color(0x52B8C6DA);

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.background,
                    theme.background.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Header
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderSideColor),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'THROTTLE',
                                  style: GoogleFonts.lexend(
                                    color: theme.primary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Master your journey.',
                                  style: GoogleFonts.lexend(
                                    color: textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // EMAIL
                      _LoginInputField(
                        controller: emailController,
                        hint: "Rider Email",
                        icon: Icons.alternate_email_rounded,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD
                      _LoginInputField(
                        controller: passwordController,
                        hint: "Secret Code",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 24),

                      // IGNITION Button
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [theme.primary, theme.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                ),
                          label: Text(
                            'IGNITION',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Quick sync divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: borderSideColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Quick sync',
                              style: GoogleFonts.lexend(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: borderSideColor)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _SocialSyncCard(
                        label: "Continue with Google",
                        icon: Icons.g_mobiledata_rounded,
                        onTap: isLoading ? () {} : googleLogin,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _SocialSyncCard(
                        label: "Continue with Apple",
                        icon: Icons.apple_rounded,
                        onTap: () {},
                        theme: theme,
                      ),

                      const SizedBox(height: 40),

                      // Signup Link
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.lexend(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: "New to the trail? "),
                              TextSpan(
                                text: "Join the Pack",
                                style: TextStyle(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final dynamic theme;

  const _LoginInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    required this.theme,
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
          color: widget.theme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isFocused ? widget.theme.primary : const Color(0x52B8C6DA),
            width: _isFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.isPassword,
          style: GoogleFonts.lexend(color: widget.theme.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.lexend(
              color: widget.theme.textPrimary.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused
                  ? widget.theme.primary
                  : widget.theme.textPrimary.withValues(alpha: 0.6),
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
  final dynamic theme;

  const _SocialSyncCard({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x52B8C6DA)),
          boxShadow: [
            BoxShadow(
              color: theme.textPrimary.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.textPrimary, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
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
