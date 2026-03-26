import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/public_profile_screen.dart';
import 'package:throttle_ui/services/group_service.dart';
import 'package:throttle_ui/services/notification_service.dart';
import 'package:throttle_ui/services/ride_service.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class RideInfoScreen extends StatefulWidget {
  final Map<String, dynamic> rideGroup;
  final String token;

  const RideInfoScreen({
    super.key,
    required this.rideGroup,
    required this.token,
  });

  @override
  State<RideInfoScreen> createState() => _RideInfoScreenState();
}

class _RideInfoScreenState extends State<RideInfoScreen> {
  String searchQuery = "";
  int _refreshCounter = 0; // Add this for refreshing the members list

  String? _currentUserUuidFromToken() {
    try {
      final parts = widget.token.split('.');
      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      ) as Map<String, dynamic>;

      return payload["sub"]?.toString();
    } catch (_) {
      return null;
    }
  }

  String _currentUserRoleFromMembers(List<dynamic> members) {
    final currentUserUuid = _currentUserUuidFromToken();
    if (currentUserUuid != null) {
      for (final member in members) {
        if (member is Map && member["userUuid"]?.toString() == currentUserUuid) {
          return member["role"]?.toString() ?? "";
        }
      }
    }

    final createdByUser = widget.rideGroup["createdByUser"];
    final createdByUuid =
        createdByUser is Map ? createdByUser["uuid"]?.toString() : null;

    if (createdByUuid != null && createdByUuid == currentUserUuid) {
      return "ADMIN";
    }

    return widget.rideGroup["myRole"]?.toString() ?? "";
  }

  bool _canManageMembers(String currentUserRole) {
    return currentUserRole == "CAPTAIN" || currentUserRole == "ADMIN";
  }

  String _formatRoleLabel(String role) {
    return role
        .split("_")
        .map((part) => part.isEmpty
            ? part
            : "${part[0]}${part.substring(1).toLowerCase()}")
        .join(" ");
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _refreshMembers() async {
    if (!mounted) return;
    setState(() {
      _refreshCounter++;
    });
  }

  Future<void> _showRolePicker(Map<String, dynamic> member) async {
    final String currentRole = member["role"] ?? "RIDER";
    String selectedRole = currentRole;
    List<String> availableRoles = RideService.availableRoles;

    try {
      availableRoles = await RideService.fetchRoles(widget.token);
    } catch (_) {}

    if (!mounted) return;

    final String? nextRole = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Change role",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pick a role for ${member["firstName"] ?? "this rider"}.",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.overlay,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary),
                          items: availableRoles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                _formatRoleLabel(role),
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              selectedRole = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: selectedRole == currentRole
                            ? null
                            : () => Navigator.pop(sheetContext, selectedRole),
                        child: const Text("Save role"),
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

    if (nextRole == null || nextRole == currentRole) return;

    try {
      await RideService.updateUserRole(
        widget.token,
        widget.rideGroup["uuid"],
        member["userUuid"],
        nextRole,
      );
      _showMessage("Role updated to ${_formatRoleLabel(nextRole)}");
      await _refreshMembers();
    } catch (e) {
      _showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                "Remove rider?",
                style: TextStyle(color: AppColors.white),
              ),
              content: Text(
                "This will remove ${member["firstName"] ?? "this rider"} from the ride.",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    "Remove",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    try {
      await RideService.removeMember(
        widget.token,
        widget.rideGroup["uuid"],
        member["userUuid"],
      );
      _showMessage("Member removed from ride");
      await _refreshMembers();
    } catch (e) {
      _showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  Future<List<dynamic>> fetchMembers() async {
    final result = await GroupService.fetchRideMembers(
      widget.token,
      widget.rideGroup["uuid"],
    );

    return result["data"] ?? [];
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  bool _canEditPreRide(String currentUserRole) {
    return currentUserRole == "CAPTAIN" || currentUserRole == "ADMIN";
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.white10),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preRideFeature({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preRideHeroCard(Map<String, dynamic> preRideInfo) {
    final meetingPoint =
        (preRideInfo["meetingPoint"] ?? "No meeting point added").toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Meeting Point",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meetingPoint,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _openMemberSheet(
    BuildContext context,
    Map member,
    String currentUserRole,
  ) {
    final bool canManageRoles = _canManageMembers(currentUserRole);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final String name =
            "${member["firstName"] ?? ""} ${member["lastName"] ?? ""}".trim();
        final String role = member["role"] ?? "RIDER";

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// MEMBER BASIC INFO
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "U",
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(role, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.white),
                title: const Text(
                  "View Profile",
                  style: TextStyle(color: AppColors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        user: Map<String, dynamic>.from(member),
                      ),
                    ),
                  );
                },
              ),

              if (canManageRoles) ...[
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: AppColors.white),
                  title: const Text(
                    "Change Role",
                    style: TextStyle(color: AppColors.white),
                  ),
                  subtitle: Text(
                    "Current: ${_formatRoleLabel(role)}",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRolePicker(Map<String, dynamic>.from(member));
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.remove_circle, color: Colors.red),
                  title: const Text(
                    "Remove from Ride",
                    style: TextStyle(color: AppColors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeMember(Map<String, dynamic>.from(member));
                  },
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.overlay,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.white10),
                  ),
                  child: const Text(
                    "Only riders with the CAPTAIN or ADMIN role can assign roles or remove members.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _editDescription() {
    TextEditingController controller = TextEditingController(
      text: widget.rideGroup["description"],
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Description",
                style: TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Enter group description",
                  hintStyle: TextStyle(color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await GroupService.updateRide(
                    widget.token,
                    widget.rideGroup["uuid"],
                    {"description": controller.text},
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    widget.rideGroup["description"] = controller.text;
                  });
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statTile(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(String currentUserRole) {
    final name = widget.rideGroup["title"] ?? "Ride";
    final creatorUser = widget.rideGroup["createdByUser"];
    final creatorName = creatorUser != null
        ? "${creatorUser["firstName"] ?? ""} ${creatorUser["lastName"] ?? ""}"
              .trim()
        : widget.rideGroup["createdByName"] ?? "Unknown";

    final createdAt = widget.rideGroup["createdAt"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.surfaceMuted,
                child: Icon(
                  Icons.directions_bike,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (creatorName.isNotEmpty || createdAt != null)
                Text(
                  "${creatorName.isNotEmpty ? creatorName : "Unknown"}"
                  "${createdAt != null ? " • ${formatTime(createdAt)}" : ""}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _quickAction(
                    icon: Icons.campaign_outlined,
                    label: "Announcement",
                    onTap: () {
                      _showMessage(
                        "Announcement flow can be connected here when the backend is ready.",
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.person_add_alt_1,
                    label: "Add Members",
                    onTap: () {
                      _showMessage(
                        "Add members flow can be connected here when the invite flow is ready.",
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.route_outlined,
                    label: "Pre-Ride Info",
                    onTap: () {
                      _showPreRideDetails(currentUserRole);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.rideGroup["preRideInfo"] != null &&
            (widget.rideGroup["preRideInfo"] as Map).isNotEmpty &&
            ((widget.rideGroup["preRideInfo"]["meetingPoint"] ?? "")
                .toString()
                .trim()
                .isNotEmpty)) ...[
          const SizedBox(height: 16),
          _preRideHeroCard(
            Map<String, dynamic>.from(widget.rideGroup["preRideInfo"]),
          ),
        ],
      ],
    );
  }

  String formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showPreRideDetails(String currentUserRole) {
    final preRideInfo =
        Map<String, dynamic>.from(widget.rideGroup["preRideInfo"] ?? {});
    final canEditPreRide = _canEditPreRide(currentUserRole);
    final checkpoints = (preRideInfo["checkpointList"] as List?)
            ?.whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        [];
    final rules = (preRideInfo["ruleList"] as List?)
            ?.whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Pre-Ride Information",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canEditPreRide)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openPreRideInfo(canEdit: true);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text("Edit"),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preRideInfo.isEmpty
                        ? "No pre-ride briefing has been added yet."
                        : "Ride setup and briefing shared by the captain/admin.",
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  if (preRideInfo.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.overlay,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.white10),
                      ),
                      child: const Text(
                        "Add meeting point, checkpoints, rules, notes, and ride setup details here.",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((preRideInfo["meetingPoint"] ?? "")
                            .toString()
                            .isNotEmpty)
                          _preRideHeroCard(preRideInfo),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          children: [
                            _preRideFeature(
                              icon: Icons.directions_bike_outlined,
                              label: "Ride Type",
                              value: (preRideInfo["rideType"] ??
                                      widget.rideGroup["rideType"] ??
                                      "Ride")
                                  .toString(),
                            ),
                            _preRideFeature(
                              icon: Icons.map_outlined,
                              label: "Route Type",
                              value: (preRideInfo["routeType"] ??
                                      widget.rideGroup["routeType"] ??
                                      "Route")
                                  .toString(),
                            ),
                            _preRideFeature(
                              icon: Icons.people_outline,
                              label: "Max Riders",
                              value: (preRideInfo["maxRiders"] ??
                                      widget.rideGroup["maxRiders"] ??
                                      "-")
                                  .toString(),
                            ),
                            _preRideFeature(
                              icon: Icons.visibility_outlined,
                              label: "Visibility",
                              value: (preRideInfo["visibility"] ??
                                      widget.rideGroup["visibility"] ??
                                      "PUBLIC")
                                  .toString(),
                            ),
                            _preRideFeature(
                              icon: Icons.local_gas_station_outlined,
                              label: "Fuel Stops",
                              value: (preRideInfo["fuelStops"] ?? "-")
                                  .toString(),
                            ),
                            _preRideFeature(
                              icon: Icons.sticky_note_2_outlined,
                              label: "Notes",
                              value: ((preRideInfo["notes"] ?? "")
                                      .toString()
                                      .isEmpty)
                                  ? "No notes added"
                                  : preRideInfo["notes"].toString(),
                            ),
                          ],
                        ),
                        if (checkpoints.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Checkpoints",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: checkpoints
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.white10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.place_outlined,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (rules.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Ride Rules",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: rules
                                .map(
                                  (rule) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: AppColors.white10),
                                    ),
                                    child: Text(
                                      rule,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPreRideInfo({bool canEdit = true}) {
    if (!canEdit) {
      _showPreRideDetails(_currentUserRoleFromMembers(const []));
      return;
    }

    int step = 0;
    final existingPreRide =
        Map<String, dynamic>.from(widget.rideGroup["preRideInfo"] ?? {});

    final meetingController = TextEditingController(
      text: existingPreRide["meetingPoint"]?.toString() ?? "",
    );
    final fuelController = TextEditingController(
      text: existingPreRide["fuelStops"]?.toString() ?? "",
    );
    final checkpointController = TextEditingController();
    final notesController = TextEditingController(
      text: existingPreRide["notes"]?.toString() ?? "",
    );

    List<String> checkpoints = List<String>.from(
      existingPreRide["checkpointList"] ??
          (existingPreRide["checkpoints"]?.toString().split(",") ?? [])
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty),
    );
    List<String> selectedRules = List<String>.from(
      existingPreRide["ruleList"] ??
          (existingPreRide["rules"]?.toString().split(",") ?? [])
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty),
    );

    final rules = [
      "No overspeeding",
      "Stay in formation",
      "No reckless riding",
      "Follow captain",
      "Helmet mandatory",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget section;

            /// ---------- STEP 1 ----------
            if (step == 0) {
              section = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Meeting Point",
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: meetingController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration("Enter meetup location"),
                  ),
                ],
              );
            }
            /// ---------- STEP 2 ----------
            else if (step == 1) {
              section = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fuel & Checkpoints",
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fuelController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration("Estimated fuel stops"),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: checkpointController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                            "Add checkpoint location",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (checkpointController.text.isNotEmpty) {
                            setModalState(() {
                              checkpoints.add(checkpointController.text);
                              checkpointController.clear();
                            });
                          }
                        },
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.add, color: AppColors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: checkpoints.asMap().entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }
            /// ---------- STEP 3 ----------
            else if (step == 2) {
              section = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ride Rules",
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rules.map((rule) {
                      final selected = selectedRules.contains(rule);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selected
                                ? selectedRules.remove(rule)
                                : selectedRules.add(rule);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rule,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration("Add custom rule (optional)"),
                  ),
                ],
              );
            }
            /// ---------- STEP 4 (PREVIEW) ----------
            else {
              section = SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Preview",
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _preview("Meeting Point", meetingController.text),
                    _preview("Ride Type", widget.rideGroup["rideType"] ?? ""),
                    _preview("Route Type", widget.rideGroup["routeType"] ?? ""),
                    _preview(
                      "Max Riders",
                      (widget.rideGroup["maxRiders"] ?? "").toString(),
                    ),
                    _preview("Fuel Stops", fuelController.text),
                    _preview("Rules", selectedRules.join(", ")),
                    const SizedBox(height: 10),
                    const Text(
                      "Checkpoints",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: checkpoints
                          .map(
                            (c) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.place,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              title: Text(
                                c,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration("Notes (optional)"),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Circle Step Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      bool done = index <= step;
                      return Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: done
                                  ? AppColors.primary
                                  : AppColors.white12,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (index < 3)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: index < step
                                      ? AppColors.primary
                                      : AppColors.white12,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 14),

                  section,

                  const SizedBox(height: 16),

                  /// Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (step > 0)
                        TextButton(
                          onPressed: () => setModalState(() => step--),
                          child: const Text("Back"),
                        )
                      else
                        const SizedBox(), // placeholder for alignment

                      ElevatedButton(
                        onPressed: () {
                          if (step < 3) {
                            setModalState(() => step++);
                          } else {
                            final previousPreRide =
                                Map<String, dynamic>.from(
                                  widget.rideGroup["preRideInfo"] ?? {},
                                );
                            final preRidePayload =
                                RideService.buildPreRideInfoPayload(
                                  rideGroup: widget.rideGroup,
                                  meetingPoint: meetingController.text,
                                  fuelStops: fuelController.text,
                                  checkpoints: checkpoints,
                                  rules: selectedRules,
                                  notes: notesController.text,
                                );

                            RideService.savePreRideInfoLocally(
                              rideGroup: widget.rideGroup,
                              preRideInfo: preRidePayload,
                            );

                            final rideTitle =
                                widget.rideGroup["title"]?.toString() ?? "ride";
                            final meetingPoint =
                                preRidePayload["meetingPoint"]?.toString() ?? "";
                            final hadMeetingPoint =
                                (previousPreRide["meetingPoint"] ?? "")
                                    .toString()
                                    .trim()
                                    .isNotEmpty;

                            Navigator.pop(context);
                            setState(() {});
                            _showMessage("Pre-ride information saved locally");

                            NotificationService().notifyPreRideInfoUpdated(
                              token: widget.token,
                              rideTitle: rideTitle,
                            );

                            if (!hadMeetingPoint &&
                                meetingPoint.trim().isNotEmpty) {
                              NotificationService().notifyMeetingPointSelected(
                                token: widget.token,
                                rideTitle: rideTitle,
                                meetingPoint: meetingPoint,
                              );
                            }
                          }
                        },
                        child: Text(step == 3 ? "Save" : "Next"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Common input decoration for all text fields
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Preview row for the last section
  Widget _preview(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              content.isEmpty ? "-" : content,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContainer({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _checkpointCard({
    required int index,
    required String text,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$index. $text",
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _previewCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _previewTile(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _locationField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true, // 🔥 ready for map picker
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onTap: () {
        // 👉 future: open map picker
      },
    );
  }

  // Helper function to create input fields with disable logic
  Widget _input(
    String label,
    TextEditingController controller,
    bool isEditable,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary),
        enabled: isEditable, // Enable or disable based on user role
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.rideGroup["description"];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Group Info"),
      ),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(
          _refreshCounter,
        ), // Add key to refresh when counter changes
        future: fetchMembers(),
        builder: (context, snapshot) {
          List members = snapshot.data ?? [];
          final String currentUserRole = _currentUserRoleFromMembers(members);

          if (searchQuery.isNotEmpty) {
            members = members.where((m) {
              final name = "${m["firstName"] ?? ""} ${m["lastName"] ?? ""}"
                  .toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _groupHeader(currentUserRole),
              const SizedBox(height: 20),

              /// DESCRIPTION
              const Text(
                "Description",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _editDescription,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    description ?? "Add group description",
                    style: TextStyle(
                      color: description == null
                          ? AppColors.textHint
                          : AppColors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SETTINGS
              const Text(
                "Settings",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text(
                  "Notifications",
                  style: TextStyle(color: AppColors.white),
                ),
              ),

              ListTile(
                title: const Text(
                  "Group Visibility",
                  style: TextStyle(color: AppColors.white),
                ),
                subtitle: Text(
                  widget.rideGroup["visibility"] ?? "PUBLIC",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              /// PARTICIPANTS HEADER
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${members.length} riders",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search riders...",
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// MEMBERS LIST
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (members.isEmpty)
                const Text(
                  "No riders found",
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                Column(
                  children: members.map((m) {
                    final member = Map<String, dynamic>.from(m);

                    final name =
                        "${member["firstName"] ?? ""} ${member["lastName"] ?? ""}"
                            .trim();

                    return ListTile(
                      onTap: () =>
                          _openMemberSheet(context, member, currentUserRole),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "R",
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      trailing: Text(
                        member["role"] ?? "",
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 30),

              /// EXIT GROUP
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  final myRole = widget.rideGroup["myRole"];

                  if (myRole == "CAPTAIN") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Assign a new captain before leaving"),
                      ),
                    );
                    return;
                  }

                  // call exit API
                },
                child: const Text(
                  "Exit Group",
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
