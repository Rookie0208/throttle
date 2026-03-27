import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/ride_service.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class PlanRideScreen extends StatefulWidget {
  final String token;

  const PlanRideScreen({super.key, required this.token});

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
  final bgColor = AppColors.background;
  final cardColor = AppColors.surface;
  final softCardColor = const Color(0xff14161a);
  final primaryColor = AppColors.primary;

  String rideType = "SOLO";
  String difficulty = "EASY";

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final startLocationController = TextEditingController();
  final endLocationController = TextEditingController();
  final maxRidersController = TextEditingController();
  final rulesController = TextEditingController();

  List<String> selectedFriends = [];
  bool isLoading = false;

  DateTime selectedStartTime = DateTime.now().add(
    const Duration(days: 1, hours: 1),
  );
  double startLat = 0.0;
  double startLng = 0.0;
  double endLat = 0.0;
  double endLng = 0.0;

  int currentStep = 0;

  final String mapboxToken =
      "sk.eyJ1IjoiYW1pdHJhd2F0MjYxMiIsImEiOiJjbW1jNmZhZjQwMnNnMnJxdzJzNjJ0amk2In0.7524zGVXx4-Qq41E_LKOTg";

  @override
  void initState() {
    super.initState();
    _syncSelectedStartTime();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startLocationController.dispose();
    endLocationController.dispose();
    maxRidersController.dispose();
    rulesController.dispose();
    super.dispose();
  }

  Widget sectionTitle(String text, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ]
      ],
    );
  }

  Widget cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white10),
      ),
      child: child,
    );
  }

  Widget modernField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool disabled = false,
    Function(String)? onSubmitted,
    IconData? icon,
  }) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: softCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          crossAxisAlignment:
              maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !disabled,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: const TextStyle(color: AppColors.white, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget stepIndicator() {
    final steps = ["Type", "Route", "Info", "Setup", "Preview"];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;

        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: isDone || isActive ? primaryColor : AppColors.white10,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: AppColors.white, size: 15)
                      : Text(
                          "${index + 1}",
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                steps[index],
                style: TextStyle(
                  color: isActive ? AppColors.white : AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _syncSelectedStartTime();
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      final candidate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        picked.hour,
        picked.minute,
      );
      if (!candidate.isAfter(DateTime.now())) {
        showError("Please choose a future date and time");
        return;
      }
      setState(() {
        selectedTime = picked;
        _syncSelectedStartTime();
      });
    }
  }

  void _syncSelectedStartTime() {
    selectedStartTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  bool _hasValidFutureStartTime() {
    _syncSelectedStartTime();
    return selectedStartTime.isAfter(DateTime.now());
  }

  void openInviteFriendsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (_) {
        List<String> clubMembers = [
          "Rahul",
          "Amit",
          "Sneha",
          "Karan",
          "Vikram",
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Invite Club Members",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: clubMembers.length,
                        itemBuilder: (_, index) {
                          final member = clubMembers[index];
                          final isSelected = selectedFriends.contains(member);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: softCardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.white10),
                            ),
                            child: ListTile(
                              title: Text(
                                member,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                activeColor: primaryColor,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedFriends.add(member);
                                    } else {
                                      selectedFriends.remove(member);
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchCoordinates(String placeName, bool isStart) async {
    if (placeName.trim().isEmpty) return;

    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(placeName)}.json?access_token=$mapboxToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coords = data['features'][0]['center'];
          final lng = coords[0];
          final lat = coords[1];

          setState(() {
            if (isStart) {
              startLat = lat;
              startLng = lng;
            } else {
              endLat = lat;
              endLng = lng;
            }
          });
        }
      }
    } catch (e) {
      showError("Failed to fetch coordinates");
    }
  }

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

  bool validateCurrentStep() {
    if (currentStep == 0 && rideType == "GROUP") {
      if (maxRidersController.text.trim().isEmpty ||
          int.tryParse(maxRidersController.text.trim()) == null) {
        showError("Please enter max riders for group ride");
        return false;
      }
    }

    if (currentStep == 1) {
      if (startLocationController.text.trim().isEmpty ||
          endLocationController.text.trim().isEmpty) {
        showError("Start and End locations are required");
        return false;
      }
    }

    if (currentStep == 2) {
      if (titleController.text.trim().isEmpty) {
        showError("Title is required");
        return false;
      }
      if (descriptionController.text.trim().isEmpty) {
        showError("Description is required");
        return false;
      }
    }

    if (currentStep == 3 && !_hasValidFutureStartTime()) {
      showError("Please choose a future date and time");
      return false;
    }

    return true;
  }

  void nextStep() {
    if (!validateCurrentStep()) return;
    if (currentStep < 4) {
      setState(() => currentStep++);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

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
    if (!_hasValidFutureStartTime()) {
      showError("Please choose a future date and time");
      return;
    }

    setState(() => isLoading = true);

    final rideData = {
      "title": titleController.text.trim(),
      "description": descriptionController.text.replaceAll("\n", " "),
      "rideType": rideType,
      "routeType": "HIGHWAY",
      "difficulty": difficulty,
      "startTime": selectedStartTime.toUtc().toIso8601String(),
      "visibility": "PUBLIC",
      "maxRiders": rideType == "GROUP"
          ? int.parse(maxRidersController.text)
          : 1,
      "rules": rulesController.text.isNotEmpty
          ? rulesController.text.split(",").map((e) => e.trim()).toList()
          : [],
      "invitedFriends": selectedFriends,
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

    final result = await RideService.createRide(rideData, widget.token);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result["success"]) {
      showSuccess("Ride created successfully!");
      Navigator.pop(context, rideType == "GROUP");
    } else {
      showError(result["message"] ?? "Failed to create ride");
    }
  }

  Widget _choiceTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? primaryColor : softCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primaryColor : AppColors.white10,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.22),
                      blurRadius: 14,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.white, size: 22),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String iconText, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            iconText,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStepContent() {
    switch (currentStep) {
      case 0:
        return cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Choose ride type",
                subtitle: "Pick solo or group before continuing.",
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _choiceTile(
                    label: "SOLO",
                    icon: Icons.person,
                    selected: rideType == "SOLO",
                    onTap: () => setState(() => rideType = "SOLO"),
                  ),
                  const SizedBox(width: 10),
                  _choiceTile(
                    label: "GROUP",
                    icon: Icons.groups_2,
                    selected: rideType == "GROUP",
                    onTap: () => setState(() => rideType = "GROUP"),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              modernField(
                controller: maxRidersController,
                hint: rideType == "SOLO"
                    ? "Max riders not needed for solo"
                    : "Enter max riders",
                keyboardType: TextInputType.number,
                disabled: rideType == "SOLO",
                icon: Icons.people_alt_outlined,
              ),
            ],
          ),
        );

      case 1:
        return cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Set your route",
                subtitle: "Add start and end locations for the ride.",
              ),
              const SizedBox(height: 12),
              modernField(
                controller: startLocationController,
                hint: "Enter start location",
                onSubmitted: (val) => fetchCoordinates(val, true),
                icon: Icons.trip_origin,
              ),
              const SizedBox(height: 10),
              modernField(
                controller: endLocationController,
                hint: "Enter end location",
                onSubmitted: (val) => fetchCoordinates(val, false),
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: softCardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.white10),
                ),
                child: const Center(
                  child: Text(
                    "Route preview goes here",
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );

      case 2:
        return cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Ride details",
                subtitle: "Add title, description and any ride rules.",
              ),
              const SizedBox(height: 12),
              modernField(
                controller: titleController,
                hint: "Sunday Morning Ride",
                icon: Icons.title,
              ),
              const SizedBox(height: 10),
              modernField(
                controller: descriptionController,
                hint: "Describe the ride...",
                maxLines: 3,
                icon: Icons.notes,
              ),
              const SizedBox(height: 10),
              modernField(
                controller: rulesController,
                hint: "Helmet required, No rash riding",
                maxLines: 2,
                icon: Icons.rule_folder_outlined,
              ),
            ],
          ),
        );

      case 3:
        return cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Schedule & setup",
                subtitle: "Choose time, difficulty and invite riders.",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: softCardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Date",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${selectedDate.toLocal()}".split(" ")[0],
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: softCardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Time",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedTime.format(context),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Difficulty",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
                          color: selected ? primaryColor : softCardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? primaryColor : AppColors.white10,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            level,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (rideType == "GROUP") ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: openInviteFriendsModal,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: softCardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFriends.isEmpty
                                ? "Invite club members"
                                : "${selectedFriends.length} riders selected",
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

      case 4:
        final rules = rulesController.text.trim().isEmpty
            ? "-"
            : rulesController.text.trim();
        final invited = selectedFriends.isEmpty
            ? "No riders"
            : selectedFriends.join(", ");

        return cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Preview your ride",
                subtitle: "Quick summary before you create it.",
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.28,
                children: [
                  _infoChip("🏍️", "Ride Type", rideType),
                  _infoChip("📍", "Start", startLocationController.text.trim().isEmpty
                      ? "-"
                      : startLocationController.text.trim()),
                  _infoChip("🏁", "End", endLocationController.text.trim().isEmpty
                      ? "-"
                      : endLocationController.text.trim()),
                  _infoChip("📝", "Title", titleController.text.trim().isEmpty
                      ? "-"
                      : titleController.text.trim()),
                  _infoChip("📅", "Date", "${selectedDate.toLocal()}".split(" ")[0]),
                  _infoChip("⏰", "Time", selectedTime.format(context)),
                  _infoChip("🔥", "Difficulty", difficulty),
                  _infoChip("📋", "Rules", rules),
                  if (rideType == "GROUP")
                    _infoChip(
                      "👥",
                      "Max Riders",
                      maxRidersController.text.trim().isEmpty
                          ? "-"
                          : maxRidersController.text.trim(),
                    ),
                  if (rideType == "GROUP")
                    _infoChip("🤝", "Invited", invited),
                ],
              ),
              if (descriptionController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: softCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Description",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descriptionController.text.trim(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget buildBottomActions() {
    final isLastStep = currentStep == 4;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: bgColor,
        border: const Border(
          top: BorderSide(color: AppColors.white10),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.white24),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : isLastStep
                      ? createRide
                      : nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      isLastStep ? "Create Ride" : "Next",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modalHeight = MediaQuery.of(context).size.height * 0.56;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.40),
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: modalHeight,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: AppColors.white10),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Create Ride",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: stepIndicator(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(currentStep),
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: buildStepContent(),
                    ),
                  ),
                ),
                buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
