import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:throttle_ui/screens/main_screen.dart';
import '../services/api_service.dart';

enum ViewType { user, admin, login }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  ViewType current = ViewType.user;
  String message = "";

  // USER CONTROLLERS
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final pronoun = TextEditingController();
  final role = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final experienceYears = TextEditingController();
  final emergencyContact = TextEditingController();

  // ADMIN CONTROLLERS
  final adminName = TextEditingController();
  final adminEmail = TextEditingController();
  final adminPassword = TextEditingController();

  // LOGIN CONTROLLERS
  final loginEmail = TextEditingController();
  final loginPassword = TextEditingController();

  final List<String> pronounOptions = ["HE/HIM", "SHE/HER", "OTHER"];
  final List<String> roleOptions = ["CAPTAIN", "RIDER"];

  final Duration animDuration = const Duration(milliseconds: 400);

  // INPUT WIDGET
  Widget input(
    String label,
    TextEditingController c, {
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          fillColor: Colors.white10,
          filled: true,
        ),
      ),
    );
  }

  // DROPDOWN WIDGET
  Widget dropdown(String label, TextEditingController c, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: c.text.isEmpty ? null : c.text,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          fillColor: Colors.white10,
          filled: true,
        ),
        items: options
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (val) => setState(() => c.text = val ?? ""),
      ),
    );
  }

  // REGISTER USER
  Future<void> registerUser() async {
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        pronoun.text.isEmpty ||
        role.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty) {
      setState(() => message = "Please fill all required fields");
      return;
    }

    final res = await ApiService.post("/auth/register", {
      "firstName": firstName.text,
      "lastName": lastName.text,
      "pronoun": pronoun.text,
      "role": role.text,
      "email": email.text,
      "password": password.text,
      "experienceYears": experienceYears.text.isEmpty
          ? 0
          : int.parse(experienceYears.text),
      "emergencyContact": emergencyContact.text.isEmpty
          ? null
          : emergencyContact.text,
    });

    try {
      final body = jsonDecode(res["body"]);
      setState(
        () => message = body["message"] ?? "User registered successfully",
      );
    } catch (e) {
      setState(() => message = res["body"]);
    }
  }

  // REGISTER ADMIN
  Future<void> registerAdmin() async {
    if (adminName.text.isEmpty ||
        adminEmail.text.isEmpty ||
        adminPassword.text.isEmpty) {
      setState(() => message = "Please fill all required fields");
      return;
    }

    final res = await ApiService.post("/auth/admin/register", {
      "name": adminName.text,
      "email": adminEmail.text,
      "password": adminPassword.text,
    });

    try {
      final body = jsonDecode(res["body"]);
      setState(
        () => message = body["message"] ?? "Admin registered successfully",
      );
    } catch (e) {
      setState(() => message = res["body"]);
    }
  }

  // LOGIN
  Future<void> login() async {
    if (loginEmail.text.isEmpty || loginPassword.text.isEmpty) {
      setState(() => message = "Please enter email and password");
      return;
    }

    final res = await ApiService.post("/auth/login", {
      "email": loginEmail.text,
      "password": loginPassword.text,
    });

    try {
      final body = jsonDecode(res["body"]);
      if (res["status"] == 200 && body["data"]?["token"] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", body["data"]["token"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => message = body["message"] ?? "Login failed");
      }
    } catch (e) {
      setState(() => message = "Login failed");
    }
  }

  // RETURN CURRENT FORM WIDGET
  Widget currentViewWidget() {
    switch (current) {
      case ViewType.user:
        return Column(
          key: const ValueKey(1),
          children: [
            input("First Name", firstName),
            input("Last Name", lastName),
            dropdown("Pronoun", pronoun, pronounOptions),
            dropdown("Role", role, roleOptions),
            input("Email", email, type: TextInputType.emailAddress),
            input("Password", password, isPassword: true),
            input(
              "Experience Years",
              experienceYears,
              type: TextInputType.number,
            ),
            input("Emergency Contact", emergencyContact),
            const SizedBox(height: 10),
            AnimatedButton(text: "Register", onPressed: registerUser),
          ],
        );
      case ViewType.admin:
        return Column(
          key: const ValueKey(2),
          children: [
            input("Admin Name", adminName),
            input("Admin Email", adminEmail, type: TextInputType.emailAddress),
            input("Password", adminPassword, isPassword: true),
            const SizedBox(height: 10),
            AnimatedButton(text: "Register Admin", onPressed: registerAdmin),
          ],
        );
      case ViewType.login:
        return Column(
          key: const ValueKey(3),
          children: [
            input("Email", loginEmail, type: TextInputType.emailAddress),
            input("Password", loginPassword, isPassword: true),
            const SizedBox(height: 10),
            AnimatedButton(text: "Login", onPressed: login),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: animDuration,
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: current == ViewType.user
                ? [Colors.blue.shade800, Colors.blue.shade600]
                : current == ViewType.admin
                ? [Colors.purple.shade800, Colors.purple.shade600]
                : [Colors.teal.shade800, Colors.teal.shade600],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff020617),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  current.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // ANIMATED SWITCHER FOR FORMS
                AnimatedSwitcher(
                  duration: animDuration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: currentViewWidget(),
                ),
                const SizedBox(height: 12),
                // MESSAGE
                AnimatedOpacity(
                  duration: animDuration,
                  opacity: message.isEmpty ? 0 : 1,
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.toLowerCase().contains("fail")
                          ? Colors.red
                          : Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => current = ViewType.user),
                      child: const Text("User Register"),
                    ),
                    TextButton(
                      onPressed: () => setState(() => current = ViewType.admin),
                      child: const Text("Admin Register"),
                    ),
                    TextButton(
                      onPressed: () => setState(() => current = ViewType.login),
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CUSTOM ANIMATED BUTTON
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPressed ? Colors.blue.shade700 : Colors.blue.shade500,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
