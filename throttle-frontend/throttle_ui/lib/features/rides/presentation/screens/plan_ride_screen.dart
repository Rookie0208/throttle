import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_refresh_notifier.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/rides/presentation/screens/live_ride_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_start_screen.dart';
import 'package:throttle_ui/core/services/location_service.dart';

class PlanRideScreen extends StatefulWidget {
  final String token;
  final bool instantRide;

  const PlanRideScreen({
    super.key,
    required this.token,
    this.instantRide = false,
  });

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen> {
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
  Map<String, String> selectedFriendLabels = {};
  List<Map<String, dynamic>> inviteOptions = [];
  bool isLoadingInviteOptions = false;
  bool isLoading = false;
  bool isResolvingRoute = false;

  DateTime selectedStartTime = DateTime.now().add(
    const Duration(days: 1, hours: 1),
  );
  LatLng? startPoint;
  LatLng? endPoint;
  String? resolvedStartQuery;
  String? resolvedEndQuery;

  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.instantRide) {
      _setInstantStartTime();
    } else {
      _syncSelectedStartTime();
    }
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

  String get _mapboxPublicToken =>
      dotenv.env["MAPBOX_PUBLIC_TOKEN"]?.trim() ?? "";

  bool get _hasMapboxToken => _mapboxPublicToken.isNotEmpty;

  bool get _isInstantRide => widget.instantRide;

  List<String> get _steps => _isInstantRide
      ? const ["Type", "Route", "Info", "Preview"]
      : const ["Type", "Route", "Info", "Setup", "Preview"];

  int get _lastStepIndex => _steps.length - 1;

  String get _sheetTitle =>
      _isInstantRide ? "Create Instant Ride" : "Create Ride";

  String get _routeStatusLabel {
    if (!_hasMapboxToken) {
      return "Mapbox is required to resolve exact ride coordinates.";
    }
    if (startPoint != null && endPoint != null) {
      return "Start and destination are resolved with exact coordinates.";
    }
    if (startPoint != null || endPoint != null) {
      return "One location is resolved. Add the other end to complete the route.";
    }
    return "Start and destination will be shown on the ride map later in pre-ride info.";
  }

  Widget sectionTitle(String text, AppThemeConfig theme, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  String _friendUuid(Map<String, dynamic> friend) {
    return (friend["userUuid"] ?? friend["uuid"] ?? "").toString().trim();
  }

  String _friendLabel(Map<String, dynamic> friend) {
    final displayName = (friend["username"] ?? "").toString().trim();
    final riderId = (friend["riderId"] ?? "").toString().trim();
    if (displayName.isNotEmpty) return displayName;
    if (riderId.isNotEmpty) return "@$riderId";
    return "Unknown Rider";
  }

  Widget cardWrapper({required Widget child, required AppThemeConfig theme}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
              ),
      child: child,
    );
  }

  Widget stepIndicator(AppThemeConfig theme) {
    return Row(
      children: List.generate(_steps.length, (index) {
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
                  color: isDone || isActive
                      ? theme.primary
                      : const Color(0x19000000),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : theme.textPrimary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _steps[index],
                style: TextStyle(
                  color: isActive
                      ? theme.textPrimary
                      : theme.textPrimary.withValues(alpha: 0.6),
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
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

  void _setInstantStartTime() {
    final now = DateTime.now().add(const Duration(minutes: 1));
    selectedDate = DateTime(now.year, now.month, now.day);
    selectedTime = TimeOfDay.fromDateTime(now);
    selectedStartTime = now;
  }

  bool _hasValidFutureStartTime() {
    _syncSelectedStartTime();
    return selectedStartTime.isAfter(DateTime.now());
  }

  void openInviteFriendsModal(AppThemeConfig theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (inviteOptions.isEmpty && !isLoadingInviteOptions) {
              _loadInviteOptions(setModalState);
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invite Club Members",
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isLoadingInviteOptions
                          ? Center(
                              child: CircularProgressIndicator(
                                color: theme.primary,
                              ),
                            )
                          : inviteOptions.isEmpty
                          ? const Center(
                              child: Text(
                                "No friends available to invite.",
                                style: TextStyle(color: Color(0xff4F596E)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: inviteOptions.length,
                              itemBuilder: (_, index) {
                                final member = inviteOptions[index];
                                final displayName = _friendLabel(member);
                                final riderId = (member["riderId"] ?? "")
                                    .toString();
                                final friendUuid = _friendUuid(member);
                                final isSelected = selectedFriends.contains(
                                  friendUuid,
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0x52B8C6DA),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      displayName.isEmpty
                                          ? "Unknown Rider"
                                          : displayName,
                                      style: const TextStyle(
                                        color: Color(0xff191B22),
                                      ),
                                    ),
                                    subtitle: riderId.isEmpty
                                        ? null
                                        : Text(
                                            "@$riderId",
                                            style: const TextStyle(
                                              color: Color(0xff697389),
                                            ),
                                          ),
                                    trailing: TextButton(
                                      onPressed: friendUuid.isEmpty
                                          ? null
                                          : () {
                                              setModalState(() {
                                                if (!isSelected) {
                                                  selectedFriends.add(
                                                    friendUuid,
                                                  );
                                                  selectedFriendLabels[friendUuid] =
                                                      displayName;
                                                } else {
                                                  selectedFriends.remove(
                                                    friendUuid,
                                                  );
                                                  selectedFriendLabels.remove(
                                                    friendUuid,
                                                  );
                                                }
                                              });
                                              setState(() {});
                                            },
                                      style: TextButton.styleFrom(
                                        foregroundColor: isSelected
                                            ? Colors.white
                                            : theme.primary,
                                        backgroundColor: isSelected
                                            ? theme.primary
                                            : Colors.transparent,
                                        side: BorderSide(color: theme.primary),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isSelected ? "Invited" : "Invite",
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    if (inviteOptions.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Showing your friends list. Club-specific members will be prioritized when available.",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [theme.primary, theme.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
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

  Future<void> _loadInviteOptions(
    void Function(void Function()) setModalState,
  ) async {
    setModalState(() => isLoadingInviteOptions = true);
    try {
      final me = await UserService.getMe();
      final userUuid = me?['id']?.toString();
      if (userUuid == null || userUuid.isEmpty) {
        throw Exception("Unable to load your profile");
      }
      final friends = await FriendService.getFriends(userUuid);
      if (!mounted) return;
      setModalState(() {
        inviteOptions = friends
            .whereType<Map>()
            .map((friend) => Map<String, dynamic>.from(friend))
            .toList();
        isLoadingInviteOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setModalState(() {
        inviteOptions = [];
        isLoadingInviteOptions = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      if (pos == null) {
        showError("Location permission denied or service disabled.");
        return;
      }
      final city = await LocationService.getCityName(pos.latitude, pos.longitude);
      final locationName = city ?? "Current Location";
      
      if (!mounted) return;
      setState(() {
        startPoint = LatLng(pos.latitude, pos.longitude);
        resolvedStartQuery = locationName;
        startLocationController.text = locationName;
      });
    } catch (e) {
      if (!mounted) return;
      showError("Failed to get current location");
    }
  }

  Future<bool> fetchCoordinates(String placeName, bool isStart) async {
    final query = placeName.trim();
    if (query.isEmpty) return false;
    if (!_hasMapboxToken) {
      showError("Add a Mapbox public token to continue");
      return false;
    }

    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$_mapboxPublicToken&limit=1&autocomplete=true";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        showError("Failed to look up ${isStart ? "start" : "end"} location");
        return false;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data["features"];
      if (features is! List || features.isEmpty) {
        showError("No map result found for \"$query\"");
        return false;
      }

      final center = (features.first as Map<String, dynamic>)["center"];
      if (center is! List || center.length < 2) {
        showError("Invalid map response for \"$query\"");
        return false;
      }

      final point = LatLng(
        (center[1] as num).toDouble(),
        (center[0] as num).toDouble(),
      );

      if (!mounted) return false;
      setState(() {
        if (isStart) {
          startPoint = point;
          resolvedStartQuery = query;
        } else {
          endPoint = point;
          resolvedEndQuery = query;
        }
      });
      return true;
    } catch (_) {
      showError("Failed to fetch coordinates");
      return false;
    }
  }

  Future<bool> _ensureRouteCoordinates() async {
    final startName = startLocationController.text.trim();
    final endName = endLocationController.text.trim();

    if (startName.isEmpty || endName.isEmpty) {
      showError("Start and End locations are required");
      return false;
    }

    if (!_hasMapboxToken) {
      showError("Mapbox is not configured yet");
      return false;
    }

    setState(() => isResolvingRoute = true);
    try {
      final startOk = resolvedStartQuery == startName && startPoint != null
          ? true
          : await fetchCoordinates(startName, true);
      if (!startOk) return false;

      final endOk = resolvedEndQuery == endName && endPoint != null
          ? true
          : await fetchCoordinates(endName, false);
      return endOk;
    } finally {
      if (mounted) {
        setState(() => isResolvingRoute = false);
      }
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
    if (currentStep == 0 && rideType == "GROUP" && !_isInstantRide) {
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

    if (!_isInstantRide && currentStep == 3 && !_hasValidFutureStartTime()) {
      showError("Please choose a future date and time");
      return false;
    }

    return true;
  }

  Future<void> nextStep() async {
    if (!validateCurrentStep()) return;
    if (currentStep == 1) {
      final routeReady = await _ensureRouteCoordinates();
      if (!routeReady) return;
    }
    if (currentStep < _lastStepIndex) {
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
        !_isInstantRide &&
        (maxRidersController.text.isEmpty ||
            int.tryParse(maxRidersController.text) == null)) {
      showError("Max Riders is required for group rides");
      return;
    }
    if (!_isInstantRide && !_hasValidFutureStartTime()) {
      showError("Please choose a future date and time");
      return;
    }
    final routeReady = await _ensureRouteCoordinates();
    if (!routeReady) {
      return;
    }

    setState(() => isLoading = true);

    final rideStartTime = _isInstantRide
        ? DateTime.now().add(const Duration(minutes: 1))
        : selectedStartTime;

    final rules = rulesController.text.trim().isEmpty
        ? <String>[]
        : rulesController.text
              .split(",")
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

    final rideData = {
      "title": titleController.text.trim(),
      "description": descriptionController.text.replaceAll("\n", " "),
      "rideType": rideType,
      "routeType": "HIGHWAY",
      "difficulty": difficulty,
      "startTime": rideStartTime.toIso8601String(),
      "visibility": "PUBLIC",
      "maxRiders": rideType == "GROUP"
          ? (_isInstantRide
                ? (selectedFriends.length + 1)
                : int.parse(maxRidersController.text))
          : 1,
      "startLocation": {
        "name": startLocationController.text.trim(),
        "latitude": startPoint?.latitude,
        "longitude": startPoint?.longitude,
      },
      "endLocation": {
        "name": endLocationController.text.trim(),
        "latitude": endPoint?.latitude,
        "longitude": endPoint?.longitude,
      },
    };

    if (!_isInstantRide && rules.isNotEmpty) {
      rideData["rules"] = rules;
    }
    if (selectedFriends.isNotEmpty) {
      rideData["invitedFriends"] = selectedFriends;
    }

    final result = await RideService.createRide(rideData, widget.token);

    if (!mounted) return;

    if (result["success"]) {
      final rideUuid = _extractRideUuid(result);
      if (_isInstantRide) {
        if (rideUuid == null || rideUuid.isEmpty) {
          setState(() => isLoading = false);
          showError("Ride was created, but we couldn't open it automatically.");
          return;
        }

        try {
          await RideService.startRideSession(widget.token, rideUuid);
          if (!mounted) return;
          setState(() => isLoading = false);
          RideRefreshNotifier.notify();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LiveRideScreen(
                groupName: titleController.text.trim(),
                onEndRide: () {},
                token: widget.token,
                rideUuid: rideUuid,
              ),
            ),
          );
          return;
        } catch (_) {
          if (!mounted) return;
          setState(() => isLoading = false);
          RideRefreshNotifier.notify();
          showSuccess("Instant ride created. Opening ride controls...");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RideStartScreen(
                groupName: titleController.text.trim(),
                rideDate: "${selectedDate.toLocal()}".split(" ")[0],
                rideTime: "Now",
                location: startLocationController.text.trim(),
                memberCount: rideType == "GROUP"
                    ? selectedFriends.length + 1
                    : 1,
                token: widget.token,
                rideUuid: rideUuid,
              ),
            ),
          );
          return;
        }
      }

      setState(() => isLoading = false);
      RideRefreshNotifier.notify();
      showSuccess("Ride created successfully!");
      Navigator.pop(context, rideType == "GROUP");
    } else {
      setState(() => isLoading = false);
      showError(result["message"] ?? "Failed to create ride");
    }
  }

  String? _extractRideUuid(Map<String, dynamic> result) {
    final root = result["data"];
    if (root is Map) {
      final rootMap = Map<String, dynamic>.from(root);
      final nested = rootMap["data"];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final nestedRideUid = nestedMap["rideUid"] ?? nestedMap["rideUuid"];
        if (nestedRideUid != null) {
          return nestedRideUid.toString();
        }
      }
      final directRideUid = rootMap["rideUid"] ?? rootMap["rideUuid"];
      if (directRideUid != null) {
        return directRideUid.toString();
      }
    }
    return null;
  }

  Widget _choiceTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required AppThemeConfig theme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? theme.primary : const Color(0x52B8C6DA),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? theme.primary
                    : theme.textPrimary.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? theme.primary : theme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(
    String iconText,
    String label,
    String value,
    AppThemeConfig theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(iconText, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStepContent(AppThemeConfig theme) {
    if (_isInstantRide && currentStep == 3) {
      return _buildPreviewStep(theme);
    }

    switch (currentStep) {
      case 0:
        return cardWrapper(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Choose ride type",
                theme,
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
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _choiceTile(
                    label: "GROUP",
                    icon: Icons.groups_2,
                    selected: rideType == "GROUP",
                    onTap: () => setState(() => rideType = "GROUP"),
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!_isInstantRide)
                _ModernInputField(
                  controller: maxRidersController,
                  hint: rideType == "SOLO"
                      ? "Max riders not needed for solo"
                      : "Enter max riders",
                  keyboardType: TextInputType.number,
                  disabled: rideType == "SOLO",
                  icon: Icons.people_alt_outlined,
                  primaryColor: theme.primary,
                  theme: theme,
                ),
            ],
          ),
        );

      case 1:
        return cardWrapper(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Set your route",
                theme,
                subtitle: "Add start and end locations for the ride.",
              ),
              const SizedBox(height: 12),
              _MapboxAutocomplete(
                controller: startLocationController,
                hint: "Enter start location",
                icon: Icons.trip_origin,
                suffixIcon: IconButton(
                  icon: Icon(Icons.my_location, color: theme.primary, size: 20),
                  onPressed: _useCurrentLocation,
                  tooltip: "Use Current Location",
                ),
                theme: theme,
                mapboxToken: _mapboxPublicToken,
                onSelected: (point, placeName) {
                  setState(() {
                    startPoint = point;
                    resolvedStartQuery = placeName;
                  });
                },
                onSubmitted: (val) => fetchCoordinates(val, true),
                onChanged: (_) {
                  setState(() {
                    resolvedStartQuery = null;
                    startPoint = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              _MapboxAutocomplete(
                controller: endLocationController,
                hint: "Enter end location",
                icon: Icons.flag_outlined,
                theme: theme,
                mapboxToken: _mapboxPublicToken,
                onSelected: (point, placeName) {
                  setState(() {
                    endPoint = point;
                    resolvedEndQuery = placeName;
                  });
                },
                onSubmitted: (val) => fetchCoordinates(val, false),
                onChanged: (_) {
                  setState(() {
                    resolvedEndQuery = null;
                    endPoint = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                                  ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.map_outlined, color: theme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _routeStatusLabel,
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.65),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (isResolvingRoute)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 2:
        return cardWrapper(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Ride details",
                theme,
                subtitle:
                    "Add title and description. Ride rules are optional here and can be added later in pre-ride info.",
              ),
              const SizedBox(height: 12),
              _ModernInputField(
                controller: titleController,
                hint: "Sunday Morning Ride",
                icon: Icons.title,
                primaryColor: theme.primary,
                theme: theme,
              ),
              const SizedBox(height: 10),
              _ModernInputField(
                controller: descriptionController,
                hint: "Describe the ride...",
                maxLines: 3,
                icon: Icons.notes,
                primaryColor: theme.primary,
                theme: theme,
              ),
              const SizedBox(height: 10),
              if (!_isInstantRide)
                _ModernInputField(
                  controller: rulesController,
                  hint: "Optional: Helmet required, No rash riding",
                  maxLines: 2,
                  icon: Icons.rule_folder_outlined,
                  primaryColor: theme.primary,
                  theme: theme,
                ),
              if (_isInstantRide && rideType == "GROUP") ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => openInviteFriendsModal(theme),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                                          ),
                    child: Row(
                      children: [
                        Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: theme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFriends.isEmpty
                                ? "Invite members"
                                : "${selectedFriends.length} riders selected",
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.textPrimary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

      case 3:
        return cardWrapper(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle(
                "Schedule & setup",
                theme,
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
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                                                  ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date",
                              style: TextStyle(
                                color: theme.textPrimary.withValues(alpha: 0.6),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${selectedDate.toLocal()}".split(" ")[0],
                              style: TextStyle(
                                color: theme.textPrimary,
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
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                                                  ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Time",
                              style: TextStyle(
                                color: theme.textPrimary.withValues(alpha: 0.6),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedTime.format(context),
                              style: TextStyle(
                                color: theme.textPrimary,
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
              Text(
                "Difficulty",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildDifficultySelector(theme),
              const SizedBox(height: 12),
              if (rideType == "GROUP") ...[
                GestureDetector(
                  onTap: () => openInviteFriendsModal(theme),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                                          ),
                    child: Row(
                      children: [
                        Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: theme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedFriends.isEmpty
                                ? "Invite club members"
                                : "${selectedFriends.length} riders selected",
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.textPrimary.withValues(alpha: 0.6),
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
        return _buildPreviewStep(theme);

      default:
        return const SizedBox();
    }
  }

  Widget _buildDifficultySelector(AppThemeConfig theme) {
    return Row(
      children: ["EASY", "MODERATE", "HARD"].map((level) {
        final selected = difficulty == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => difficulty = level),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? theme.primary : const Color(0x52B8C6DA),
                ),
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(
                    color: selected ? theme.primary : theme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewStep(AppThemeConfig theme) {
    final rules = rulesController.text.trim().isEmpty
        ? "-"
        : rulesController.text.trim();
    final invited = selectedFriends.isEmpty
        ? "No riders"
        : selectedFriends
              .map((uuid) => selectedFriendLabels[uuid] ?? uuid)
              .join(", ");

    return cardWrapper(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          sectionTitle(
            "Preview your ride",
            theme,
            subtitle: _isInstantRide
                ? "Quick summary before you start it right away."
                : "Quick summary before you create it.",
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
              _infoChip("🏍️", "Ride Type", rideType, theme),
              _infoChip(
                "📍",
                "Start",
                startLocationController.text.trim().isEmpty
                    ? "-"
                    : startLocationController.text.trim(),
                theme,
              ),
              _infoChip(
                "🏁",
                "End",
                endLocationController.text.trim().isEmpty
                    ? "-"
                    : endLocationController.text.trim(),
                theme,
              ),
              _infoChip(
                "📝",
                "Title",
                titleController.text.trim().isEmpty
                    ? "-"
                    : titleController.text.trim(),
                theme,
              ),
              _infoChip(
                _isInstantRide ? "⚡" : "📅",
                _isInstantRide ? "Start" : "Date",
                _isInstantRide
                    ? "Starts now"
                    : "${selectedDate.toLocal()}".split(" ")[0],
                theme,
              ),
              if (!_isInstantRide)
                _infoChip(
                  "🔥",
                  "Difficulty",
                  difficulty,
                  theme,
                ),
              if (!_isInstantRide) _infoChip("📋", "Rules", rules, theme),
              if (!_isInstantRide)
                _infoChip("⏰", "Time", selectedTime.format(context), theme),
              if (rideType == "GROUP" && !_isInstantRide)
                _infoChip(
                  "👥",
                  "Max Riders",
                  maxRidersController.text.trim().isEmpty
                      ? "-"
                      : maxRidersController.text.trim(),
                  theme,
                ),
              if (rideType == "GROUP" && !_isInstantRide)
                _infoChip("🤝", "Invited", invited, theme),
            ],
          ),
          if (descriptionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descriptionController.text.trim(),
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildBottomActions(AppThemeConfig theme) {
    final isLastStep = currentStep == _lastStepIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: theme.background,
        border: const Border(top: BorderSide(color: Color(0x52B8C6DA))),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x52B8C6DA)),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Back",
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.65),
                  ),
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
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
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
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastStep
                          ? (_isInstantRide ? "Start Ride" : "Create Ride")
                          : "Next",
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
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final modalHeight = MediaQuery.of(context).size.height * 0.56;

        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.40),
          body: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: modalHeight,
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                                  ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x19000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _sheetTitle,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: theme.textPrimary.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: stepIndicator(theme),
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
                          child: buildStepContent(theme),
                        ),
                      ),
                    ),
                    buildBottomActions(theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool disabled;
  final Function(String)? onSubmitted;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final Color primaryColor;
  final AppThemeConfig theme;
  final FocusNode? focusNode;
  final Widget? suffixIcon;

  const _ModernInputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.disabled = false,
    this.onSubmitted,
    this.onChanged,
    this.icon,
    required this.primaryColor,
    required this.theme,
    this.focusNode,
    this.suffixIcon,
  });

  @override
  State<_ModernInputField> createState() => _ModernInputFieldState();
}

class _ModernInputFieldState extends State<_ModernInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.disabled ? 0.45 : 1,
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused ? widget.primaryColor : const Color(0x52B8C6DA),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12),
                  child: Icon(
                    widget.icon,
                    color: _isFocused
                        ? widget.theme.primary
                        : widget.theme.textPrimary.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 4),
              ] else
                const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: !widget.disabled,
                  maxLines: widget.maxLines,
                  keyboardType: widget.keyboardType,
                  style: TextStyle(
                    color: widget.theme.textPrimary,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: widget.theme.textPrimary.withValues(alpha: 0.4),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                ),
              ),
              if (widget.suffixIcon != null) ...[
                widget.suffixIcon!,
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MapboxAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final AppThemeConfig theme;
  final String mapboxToken;
  final Function(LatLng point, String placeName) onSelected;
  final Function(String) onSubmitted;
  final Function(String) onChanged;
  final Widget? suffixIcon;

  const _MapboxAutocomplete({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.theme,
    required this.mapboxToken,
    required this.onSelected,
    required this.onSubmitted,
    required this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty || mapboxToken.isEmpty) return const [];
        try {
          final url =
              "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$mapboxToken&autocomplete=true&limit=5";
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            return (data['features'] as List).map((f) => f as Map<String, dynamic>);
          }
        } catch (_) {}
        return const [];
      },
      displayStringForOption: (option) => option['place_name'] as String,
      onSelected: (option) {
        final center = option['center'] as List;
        final point = LatLng(
          (center[1] as num).toDouble(),
          (center[0] as num).toDouble(),
        );
        onSelected(point, option['place_name'] as String);
      },
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return _ModernInputField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          hint: hint,
          icon: icon,
          primaryColor: theme.primary,
          theme: theme,
          onSubmitted: (val) {
            onFieldSubmitted();
            onSubmitted(val);
          },
          onChanged: onChanged,
          suffixIcon: suffixIcon,
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: theme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 220,
                maxWidth: MediaQuery.of(context).size.width - 40,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(color: theme.textPrimary.withValues(alpha: 0.1), height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(Icons.location_on, color: theme.primary, size: 20),
                    title: Text(
                      option['place_name'] as String,
                      style: TextStyle(color: theme.textPrimary, fontSize: 13.5),
                    ),
                    onTap: () => onSelectedOption(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
