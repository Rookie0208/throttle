import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/main_screen.dart';
import 'package:throttle_ui/services/auth_service.dart';

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
          pronoun: pronoun,
          bikeType: bikeType,
        );
      } else {
        result = await AuthService.register(
          firstName: firstNameController.text.trim(),
          lastName: surNameController.text.trim(),
          pronoun: pronoun,
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          bikeType: bikeType,
          experienceYears: 0,
        );
      }

      if (result["success"]) {
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
              color: isSelected
                  ? const Color(0xfffe6603)
                  : const Color(0xff1a1c20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              e,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w500,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 0.6),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xfffe6603), width: 1),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
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
    return Scaffold(
      backgroundColor: const Color(0xff0f1115),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (step + 1) / 3,
              backgroundColor: Colors.grey.shade900,
              color: const Color(0xfffe6603),
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
                            color: Colors.white70,
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
                            color: Colors.white70,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfffe6603),
                      ),
                      child: const Text(
                        "CONTINUE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (step > 0)
                    TextButton(
                      onPressed: back,
                      child: const Text(
                        "Back",
                        style: TextStyle(color: Colors.white54),
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
