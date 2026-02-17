import 'package:flutter/material.dart';
import '../services/ride_service.dart';

class PlanRideScreen extends StatefulWidget {
  final String token; // user JWT token

  const PlanRideScreen({super.key, required this.token});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  // ================= STATE =================
  String rideType = "SOLO"; // SOLO or GROUP
  String difficulty = "EASY"; // EASY, MODERATE, HARD
  DateTime selectedStartTime = DateTime.now().add(const Duration(hours: 1));

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final startLocationController = TextEditingController();
  final endLocationController = TextEditingController();
  final maxRidersController = TextEditingController();
  final rulesController = TextEditingController();

  double startLat = 0.0, startLng = 0.0;
  double endLat = 0.0, endLng = 0.0;

  bool isLoading = false;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ================= DATE PICKER =================
  Future<void> pickStartTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedStartTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedStartTime),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedStartTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ================= CREATE RIDE =================
  Future<void> createRide() async {
    if (titleController.text.trim().isEmpty) {
      showError("Title is required");
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      showError("Description is required");
      return;
    }
    if (startLocationController.text.trim().isEmpty ||
        endLocationController.text.trim().isEmpty) {
      showError("Start and End locations are required");
      return;
    }
    if (rideType == "GROUP" &&
        (maxRidersController.text.isEmpty ||
            int.tryParse(maxRidersController.text) == null)) {
      showError("Max Riders is required for group rides");
      return;
    }

    setState(() => isLoading = true);

    final rideData = {
      "title": titleController.text.trim(),
      "description": descriptionController.text.trim(),
      "routeType": rideType,
      "difficulty": difficulty,
      "startTime": selectedStartTime.toIso8601String(),
      "maxRiders": rideType == "GROUP"
          ? int.parse(maxRidersController.text)
          : 1,
      "rules": rulesController.text.isNotEmpty
          ? [rulesController.text.trim()]
          : ["No rules"],
      "startLocation": {
        "name": startLocationController.text.trim(),
        "latitude": startLat,
        "longitude": startLng,
      },
      "endLocation": {
        "name": endLocationController.text.trim(),
        "latitude": endLat,
        "longitude": endLng,
      },
    };
    print("my_token : ${widget.token}");
    final result = await RideService.createRide(rideData,widget.token,
    );

    setState(() => isLoading = false);

    if (result["success"]) {
      showSuccess("Ride created successfully!");
      Navigator.pop(context);
    } else {
      showError(result["message"] ?? "Failed to create ride");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f1115),
      appBar: AppBar(
        title: const Text("Plan a Ride"),
        backgroundColor: const Color(0xff0f1115),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= RIDE TYPE =================
              const Text(
                "Ride Type",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: ["SOLO", "GROUP"].map((type) {
                  final selected = rideType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => rideType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.orange : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ================= MAP PLACEHOLDER =================
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Map goes here",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ================= START LOCATION =================
              TextField(
                controller: startLocationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Start Location",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ================= END LOCATION =================
              TextField(
                controller: endLocationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "End Location",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ================= TITLE =================
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ================= DESCRIPTION =================
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ================= RULES =================
              TextField(
                controller: rulesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Rules (comma separated)",
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ================= MAX RIDERS =================
              if (rideType == "GROUP")
                TextField(
                  controller: maxRidersController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Max Riders",
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                ),
              if (rideType == "GROUP") const SizedBox(height: 12),

              // ================= DATE & TIME =================
              GestureDetector(
                onTap: pickStartTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Start Time: ${selectedStartTime.toLocal()}".split(".")[0],
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.white70)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ================= DIFFICULTY =================
              const Text(
                "Difficulty",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: ["EASY", "MODERATE", "HARD"].map((level) {
                  final selected = difficulty == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => difficulty = level),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.orange : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            level,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ================= CREATE BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create Ride",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
