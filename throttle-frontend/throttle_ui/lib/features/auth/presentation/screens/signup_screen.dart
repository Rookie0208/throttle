import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/main_screen.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  final bool isGoogleRegistration;
  final Map<String, dynamic>? googleData;

  const SignupScreen({
    super.key,
    this.isGoogleRegistration = false,
    this.googleData,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController controller = PageController();

  int step = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleRegistration && widget.googleData != null) {
      emailController.text = widget.googleData!["email"] ?? "";
      firstNameController.text = widget.googleData!["firstName"] ?? "";
      surNameController.text = widget.googleData!["lastName"] ?? "";
    }
  }

  String pronoun = "";
  String bikeType = "";
  String preference = "";

  bool obscurePassword = true;

  final firstNameController = TextEditingController();
  final surNameController = TextEditingController();
  final riderIdController = TextEditingController();
  final bikeModelController = TextEditingController();
  final bikeYearController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final pronouns = ["He/Him", "She/Her", "They/Them", "Other"];

  final bikeTypes = [
    "Sport",
    "Naked",
    "Cruiser",
    "Adventure",
    "Touring",
    "Electric",
  ];

  final preferences = [
    "Weekend Rides",
    "Long Tours",
    "City Riding",
    "Track Days",
    "Group Rides",
    "Casual Riding",
  ];

  // ================= NEXT BUTTON =================
  Future<void> next() async {
    // STEP 1 VALIDATION
    if (step == 0) {
      if (firstNameController.text.trim().isEmpty) {
        showError("First name is required");
        return;
      }

      if (emailController.text.trim().isEmpty) {
        showError("Email is required");
        return;
      }

      if (pronoun.isEmpty) {
        showError("Please select your pronoun");
        return;
      }

      final riderId = riderIdController.text.trim();
      if (riderId.isEmpty) {
        showError("Rider ID is required");
        return;
      }

      final riderIdPattern = RegExp(r'^[A-Za-z0-9._]{3,30}$');
      if (!riderIdPattern.hasMatch(riderId)) {
        showError(
          "Rider ID must be 3-30 characters and use only letters, numbers, dots, or underscores",
        );
        return;
      }

      if (!emailController.text.contains("@")) {
        showError("Enter a valid email");
        return;
      }

      if (!widget.isGoogleRegistration && passwordController.text.length < 6) {
        showError("Password must be at least 6 characters");
        return;
      }
    }

    // STEP 3 → REGISTER
    if (step == 2) {
      Map<String, dynamic> result;

      if (widget.isGoogleRegistration) {
        result = await AuthService.completeGoogleRegistration(
          email: emailController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: surNameController.text.trim(),
          riderId: riderIdController.text.trim(),
          pronoun: pronoun,
          bikeType: bikeType,
        );
      } else {
        result = await AuthService.register(
          firstName: firstNameController.text.trim(),
          lastName: surNameController.text.trim(),
          riderId: riderIdController.text.trim(),
          pronoun: pronoun,
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          bikeType: bikeType,
          experienceYears: 0,
        );
      }

      if (result["success"]) {
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
        showError(result["message"]);
      }

      return; // 🔥 VERY IMPORTANT — stop execution here
    }

    // GO TO NEXT STEP
    controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    setState(() => step++);
  }

  void back() {
    if (step > 0) {
      controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => step--);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ================= OPTION GRID =================
  Widget optionGrid(
    List<String> options,
    String selected,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((e) {
        final isSelected = selected == e;

        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              e,
              style: GoogleFonts.lexend(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= INPUT FIELD =================
  Widget thinInput(
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      readOnly: hint == "Email" && widget.isGoogleRegistration,
      obscureText: isPassword ? obscurePassword : false,
      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        fillColor: AppColors.card,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (step + 1) / 3,
              backgroundColor: AppColors.surface,
              color: colorScheme.primary,
            ),
            Expanded(
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ================= STEP 1 =================
                  buildStep(
                    "Tell us about you",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thinInput("First Name", firstNameController),
                        const SizedBox(height: 20),
                        thinInput("Last Name", surNameController),
                        const SizedBox(height: 20),
                        thinInput("Rider ID", riderIdController),
                        const SizedBox(height: 20),
                        thinInput(
                          "Email",
                          emailController,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        if (!widget.isGoogleRegistration) ...[
                          thinInput(
                            "Password",
                            passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 30),
                        ],
                        const Text(
                          "Pronoun",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        optionGrid(
                          pronouns,
                          pronoun,
                          (v) => setState(() => pronoun = v),
                        ),
                      ],
                    ),
                  ),

                  // ================= STEP 2 =================
                  buildStep(
                    "Your Riding Style",
                    optionGrid(
                      preferences,
                      preference,
                      (v) => setState(() => preference = v),
                    ),
                  ),

                  // ================= STEP 3 =================
                  buildStep(
                    "Your Bike",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bike Type",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 15),
                        optionGrid(
                          bikeTypes,
                          bikeType,
                          (v) => setState(() => bikeType = v),
                        ),
                        const SizedBox(height: 30),
                        thinInput("Bike Model", bikeModelController),
                        const SizedBox(height: 20),
                        thinInput(
                          "Year of Purchase",
                          bikeYearController,
                          type: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= BUTTONS =================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: next,
                      child: Text(
                        "CONTINUE",
                        style: GoogleFonts.lexend(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (step > 0)
                    TextButton(
                      onPressed: back,
                      child: Text(
                        "Back",
                        style: GoogleFonts.lexend(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEP WRAPPER =================
  Widget buildStep(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            content,
          ],
        ),
      ),
    );
  }
}
