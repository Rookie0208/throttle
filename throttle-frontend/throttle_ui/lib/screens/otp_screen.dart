import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class OtpScreen extends StatefulWidget {
  final Map<String, dynamic> googleData;

  const OtpScreen({super.key, required this.googleData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> verify() async {
    final otpStr = otpController.text.trim();
    if (otpStr.length != 6) {
      showError("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() => isLoading = true);

    try {
      final String email = widget.googleData['email'] ?? '';
      final result = await AuthService.verifyOtp(email: email, otp: otpStr);

      if (result['success'] == true) {
        // Correct OTP, now go to Signup Screen to complete profile
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SignupScreen(
                isGoogleRegistration: true,
                googleData: widget.googleData,
              ),
            ),
          );
        }
      } else {
        showError(result['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      showError("Verification failed. Please check network.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.googleData['email'] ?? '';
    
    return Scaffold(
      backgroundColor: const Color(0xff0f1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Verify your Email",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a 6-digit code to $email. Enter it below to continue.",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xfffe6603), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfffe6603),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify OTP",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
