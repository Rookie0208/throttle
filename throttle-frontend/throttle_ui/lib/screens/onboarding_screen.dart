import 'package:flutter/material.dart';
import 'login_screen.dart';

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
      "icon": Icons.map_outlined
    },
    {
      "title": "TRACK PERFORMANCE",
      "desc": "Monitor stats and improve your journey.",
      "icon": Icons.speed
    },
    {
      "title": "LET'S RIDE TOGETHER",
      "desc": "Join riders who share your passion.",
      "icon": Icons.groups
    },
  ];

  void next() {
    if (currentIndex < pages.length - 1) {
      setState(() => currentIndex++);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void skip() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentIndex];

    return Scaffold(
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
                  child: const Text("Skip",
                      style: TextStyle(color: Color(0xfffe6603))),
                ),
              ),

              const Spacer(),

              Icon(
                page["icon"] as IconData,
                size: 100,
                color: const Color(0xfffe6603),
              ),

              const SizedBox(height: 40),

              Text(
                page["title"] as String,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              Text(
                page["desc"] as String,
                style: const TextStyle(color: Colors.white70),
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
                          ? const Color(0xfffe6603)
                          : Colors.grey,
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xfffe6603)),
                  child: Text(
                      currentIndex == pages.length - 1
                          ? "GET STARTED"
                          : "NEXT",
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
