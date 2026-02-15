import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'create_ride_screen.dart';

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

  Widget input(String hint, TextEditingController c,
      {bool isPassword = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget dropdown(String hint, TextEditingController c, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: c.text.isEmpty ? null : c.text,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: options
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (val) => setState(() => c.text = val ?? ""),
      ),
    );
  }

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
      "experienceYears":
          experienceYears.text.isEmpty ? 0 : int.parse(experienceYears.text),
      "emergencyContact":
          emergencyContact.text.isEmpty ? null : emergencyContact.text,
    });

    try {
      final body = jsonDecode(res["body"]);
      setState(() => message = body["message"] ?? "User registered successfully");
    } catch (e) {
      setState(() => message = res["body"]);
    }
  }

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
      setState(() => message = body["message"] ?? "Admin registered successfully");
    } catch (e) {
      setState(() => message = res["body"]);
    }
  }

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
            context, MaterialPageRoute(builder: (_) => const CreateRideScreen()));
      } else {
        setState(() => message = body["message"] ?? "Login failed");
      }
    } catch (e) {
      setState(() => message = "Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xff020617),
              borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(current.name.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),

                const SizedBox(height: 12),

                // USER REGISTER
                if (current == ViewType.user) ...[
                  input("First Name", firstName),
                  input("Last Name", lastName),
                  dropdown("Pronoun", pronoun, pronounOptions),
                  dropdown("Role", role, roleOptions),
                  input("Email", email, type: TextInputType.emailAddress),
                  input("Password", password, isPassword: true),
                  input("Experience Years", experienceYears,
                      type: TextInputType.number),
                  input("Emergency Contact", emergencyContact),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: registerUser, child: const Text("Register")),
                ],

                // ADMIN REGISTER
                if (current == ViewType.admin) ...[
                  input("Admin Name", adminName),
                  input("Admin Email", adminEmail, type: TextInputType.emailAddress),
                  input("Password", adminPassword, isPassword: true),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: registerAdmin, child: const Text("Register Admin")),
                ],

                // LOGIN
                if (current == ViewType.login) ...[
                  input("Email", loginEmail, type: TextInputType.emailAddress),
                  input("Password", loginPassword, isPassword: true),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: login, child: const Text("Login")),
                ],

                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                      color: message.toLowerCase().contains("fail")
                          ? Colors.red
                          : Colors.green),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                        onPressed: () => setState(() => current = ViewType.user),
                        child: const Text("User Register")),
                    TextButton(
                        onPressed: () => setState(() => current = ViewType.admin),
                        child: const Text("Admin Register")),
                    TextButton(
                        onPressed: () => setState(() => current = ViewType.login),
                        child: const Text("Login")),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
