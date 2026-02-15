import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {

  final title = TextEditingController();
  final description = TextEditingController();

  final startName = TextEditingController();
  final startLat = TextEditingController();
  final startLng = TextEditingController();

  final endName = TextEditingController();
  final endLat = TextEditingController();
  final endLng = TextEditingController();

  final maxRiders = TextEditingController();
  final rules = TextEditingController();

  DateTime? selectedDateTime;
  String routeType = "";
  String visibility = "";
  String message = "";

  String toIso(DateTime dt) => dt.toUtc().toIso8601String();

  Widget input(String hint, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        initialDate: DateTime.now());

    if (date == null) return;

    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now());

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
          date.year, date.month, date.day,
          time.hour, time.minute);
    });
  }

  Future<void> createRide() async {

    final rulesList = rules.text
        .split("\n")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final res = await ApiService.post(
      "/rides/create",
      {
        "title": title.text,
        "description": description.text,
        "startLocation": {
          "name": startName.text,
          "latitude": double.tryParse(startLat.text),
          "longitude": double.tryParse(startLng.text)
        },
        "endLocation": {
          "name": endName.text,
          "latitude": double.tryParse(endLat.text),
          "longitude": double.tryParse(endLng.text)
        },
        "routeType": routeType,
        "startTime": selectedDateTime != null
            ? toIso(selectedDateTime!)
            : null,
        "maxRiders":
            int.tryParse(maxRiders.text),
        "visibility": visibility,
        "rules": rulesList
      },
      authorized: true,
    );

    setState(() =>
        message = "Status: ${res["status"]}\n${res["body"]}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      appBar: AppBar(title: const Text("Create Ride")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            input("Ride Title", title),
            input("Description", description),

            const SizedBox(height: 10),
            const Text("Start Location"),
            input("Name", startName),
            input("Latitude", startLat),
            input("Longitude", startLng),

            const SizedBox(height: 10),
            const Text("End Location"),
            input("Name", endName),
            input("Latitude", endLat),
            input("Longitude", endLng),

            DropdownButton<String>(
              value: routeType.isEmpty ? null : routeType,
              hint: const Text("Route Type"),
              items: ["HIGHWAY", "CITY", "OFFROAD"]
                  .map((e) => DropdownMenuItem(
                      value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => routeType = v ?? ""),
            ),

            DropdownButton<String>(
              value: visibility.isEmpty ? null : visibility,
              hint: const Text("Visibility"),
              items: ["PUBLIC", "PRIVATE"]
                  .map((e) => DropdownMenuItem(
                      value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => visibility = v ?? ""),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
                onPressed: pickDateTime,
                child: Text(selectedDateTime == null
                    ? "Pick Start Time"
                    : DateFormat("yyyy-MM-dd HH:mm")
                        .format(selectedDateTime!))),

            input("Max Riders", maxRiders),
            input("Rules (one per line)", rules),

            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: createRide,
                child: const Text("Create Ride")),

            const SizedBox(height: 10),
            Text(message,
                style:
                    const TextStyle(color: Colors.green))
          ],
        ),
      ),
    );
  }
}
