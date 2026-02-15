import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController controller = PageController();
  int step = 0;

  String name = "";
  String pronoun = "";
  String bikeType = "";
  String preference = "";

  final nameController = TextEditingController();
  final bikeModelController = TextEditingController();
  final bikeYearController = TextEditingController();

  final pronouns = ["He/Him", "She/Her", "They/Them", "Other"];

  final bikeTypes = [
    "Sport",
    "Naked",
    "Cruiser",
    "Adventure",
    "Touring",
    "Electric"
  ];

  final preferences = [
    "Weekend Rides",
    "Long Tours",
    "City Riding",
    "Track Days",
    "Group Rides",
    "Casual Riding"
  ];

  void next() {
    if (step < 2) {
      controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
      setState(() => step++);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  void back() {
    if (step > 0) {
      controller.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
      setState(() => step--);
    }
  }

  Widget optionGrid(List<String> options, String selected,
      Function(String) onSelect) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((e) {
        final isSelected = selected == e;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget thinInput(String hint, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  // STEP 1 — NAME + PRONOUN
                  buildStep(
                    "Tell us about you",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thinInput("Full Name", nameController),
                        const SizedBox(height: 25),
                        const Text("Pronoun",
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 15),
                        optionGrid(
                            pronouns,
                            pronoun,
                            (v) => setState(() => pronoun = v)),
                      ],
                    ),
                  ),

                  // STEP 2 — RIDING PREFERENCE
                  buildStep(
                    "Your Riding Style",
                    optionGrid(preferences, preference,
                        (v) => setState(() => preference = v)),
                  ),

                  // STEP 3 — BIKE DETAILS
                  buildStep(
                    "Your Bike",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Bike Type",
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 15),
                        optionGrid(bikeTypes, bikeType,
                            (v) => setState(() => bikeType = v)),
                        const SizedBox(height: 30),
                        thinInput("Bike Model", bikeModelController),
                        const SizedBox(height: 20),
                        thinInput("Year of Purchase", bikeYearController,
                            type: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (step > 0)
                    TextButton(
                      onPressed: back,
                      child: const Text(
                        "Back",
                        style: TextStyle(
                            color: Colors.white54),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildStep(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 40),
            content,
          ],
        ),
      ),
    );
  }
}
