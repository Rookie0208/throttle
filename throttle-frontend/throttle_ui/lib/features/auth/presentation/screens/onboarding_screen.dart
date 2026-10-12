import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;

  final pages = [
    {
      "title": "PLAN YOUR RIDE",
      "desc": "Schedule, organize and ride smarter.",
      "icon": Icons.map_outlined,
    },
    {
      "title": "TRACK PERFORMANCE",
      "desc": "Monitor stats and improve your journey.",
      "icon": Icons.speed,
    },
    {
      "title": "LET'S RIDE TOGETHER",
      "desc": "Join riders who share your passion.",
      "icon": Icons.groups,
    },
  ];

  void next() {
    if (currentIndex < pages.length - 1) {
      setState(() => currentIndex++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  void skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // SKIP BUTTON
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: skip,
                  child: Text(
                    "Skip",
                    style: GoogleFonts.lexend(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/branding/throttle_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                page["title"] as String,
                style: GoogleFonts.lexend(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              Text(
                page["desc"] as String,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // PROGRESS DOTS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentIndex == index
                          ? AppColors.primary
                          : AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // FULL WIDTH BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: next,
                  child: Text(
                    currentIndex == pages.length - 1
                        ? "Get Started"
                        : "Next  >",
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
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
