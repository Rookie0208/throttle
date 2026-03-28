import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildGoogleSignInButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
        .renderButton(),
  );
}
