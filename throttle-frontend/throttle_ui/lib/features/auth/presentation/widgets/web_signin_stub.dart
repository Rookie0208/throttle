import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({required VoidCallback onPressed}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.login),
    label: const Text("Sign in with Google"),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
    ),
  );
}
