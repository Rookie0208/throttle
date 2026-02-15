import 'package:flutter/material.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // THROTTLE LOGO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 6,
                    color: const Color(0xfffe6603),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.speed,
                      color: Color(0xfffe6603), size: 30),
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 6,
                    color: const Color(0xfffe6603),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text("THROTTLE",
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),

              const SizedBox(height: 40),

              TextField(
                decoration:
                    const InputDecoration(labelText: "Username or Email"),
              ),
              const SizedBox(height: 15),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xfffe6603)),
                  child: const Text("SIGN IN"),
                ),
              ),

              const SizedBox(height: 25),

              const Text("OR", style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 15),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.apple),
                label: const Text("Sign in with Apple"),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()));
                },
                child: const Text("Don't have an account? Sign Up",
                    style: TextStyle(color: Color(0xfffe6603))),
              )
            ],
          ),
        ),
      ),
    );
  }
}
