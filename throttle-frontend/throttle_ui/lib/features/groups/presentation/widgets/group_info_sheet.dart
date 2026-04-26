import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:throttle_ui/features/groups/data/services/place_service.dart';
import 'package:throttle_ui/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:throttle_ui/features/groups/data/services/group_service.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

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

  String get _groupUuid => widget.rideGroup["uuid"].toString();
  String get _rideUuid =>
      (widget.rideGroup["rideUuid"] ?? widget.rideGroup["uuid"]).toString();

  bool get _isSubGroup =>
      widget.rideGroup["isSubGroup"] == true ||
      widget.rideGroup["parentGroupUuid"] != null;

  bool get _isGroupLocked {
    final groupStatus = (widget.rideGroup["status"] ?? "")
        .toString()
        .toLowerCase();
    final rideStatus = (widget.rideGroup["rideStatus"] ?? "")
        .toString()
        .toUpperCase();
    return groupStatus == "archive" ||
        {"CANCELLED", "COMPLETED", "ENDED"}.contains(rideStatus);
  }

  bool get _isRideStarted {
    final rideStatus = (widget.rideGroup["rideStatus"] ??
            widget.rideGroup["status"] ??
            "")
        .toString()
        .toUpperCase();
    return {
      "PARTIAL_STARTED",
      "READY_TO_START",
      "ACTIVE",
      "IN_PROGRESS",
      "COMPLETED",
      "CANCELLED",
      "ENDED",
    }.contains(rideStatus);
  }

  bool _isGroupMember(Map<dynamic, dynamic>? group) =>
      group?["isMember"] == true || group?["member"] == true;

  String? _currentUserUuidFromToken() {
    try {
      final parts = widget.token.split('.');
      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized)))
              as Map<String, dynamic>;

      return payload["sub"]?.toString();
    } catch (_) {
      return null;
    }
  }

  String _currentUserRoleFromMembers(List<dynamic> members) {
    final currentUserUuid = _currentUserUuidFromToken();
    if (currentUserUuid != null) {
      for (final member in members) {
        if (member is Map &&
            member["userUuid"]?.toString() == currentUserUuid) {
          return member["role"]?.toString() ?? "";
        }
      }
    }

    final createdByUser = widget.rideGroup["createdByUser"];
    final createdByUuid = createdByUser is Map
        ? createdByUser["uuid"]?.toString()
        : null;

    if (createdByUuid != null && createdByUuid == currentUserUuid) {
      return "ADMIN";
    }

    return widget.rideGroup["myRole"]?.toString() ?? "";
  }

  bool _canManageMembers(String currentUserRole) {
    if (_isGroupLocked || _isRideStarted) return false;
    return currentUserRole == "CAPTAIN" ||
        currentUserRole == "ADMIN" ||
        currentUserRole == "CO_CAPTAIN";
  }

  bool _isRideManagerRole(String currentUserRole) {
    return currentUserRole == "CAPTAIN" ||
        currentUserRole == "ADMIN" ||
        currentUserRole == "CO_CAPTAIN";
  }

  bool _canOpenAddMembers(String currentUserRole) {
    if (_isGroupLocked || _isRideStarted) return false;
    if (!_isSubGroup) {
      final rideType = (widget.rideGroup["rideType"] ?? "")
          .toString()
          .toUpperCase();
      if (rideType == "SOLO") return false;
      return _canManageMembers(currentUserRole);
    }
    if (!_isGroupMember(widget.rideGroup)) return false;
    if (_canManageMembers(currentUserRole)) return true;
    return widget.rideGroup["membersCanAddMembers"] == true &&
        widget.rideGroup["adminsApproveMembers"] != true;
  }

  bool _canJoinCurrentSubGroup() =>
      _isSubGroup &&
      !_isRideStarted &&
      !_isGroupMember(widget.rideGroup) &&
      !_canManageMembers((widget.rideGroup["myRole"] ?? "").toString()) &&
      (widget.rideGroup["canJoinDirectly"] == true ||
          widget.rideGroup["canRequestToJoin"] == true);

  bool _canRenameGroup(String currentUserRole) =>
      !_isRideStarted && _canManageMembers(currentUserRole);

  String get _memberNoun => _isSubGroup ? "members" : "riders";

  String _formatRoleLabel(String role) {
    return role
        .split("_")
        .map(
          (part) => part.isEmpty
              ? part
              : "${part[0]}${part.substring(1).toLowerCase()}",
        )
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

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    try {
      final details = _groupUuid == _rideUuid
          ? await SubGroupService.fetchMainGroupDetails(widget.token, _rideUuid)
          : await SubGroupService.fetchSubGroupDetails(
              widget.token,
              _groupUuid,
            );
      if (!mounted) return;
      setState(() {
        final preservedMyRole = widget.rideGroup["myRole"];
        widget.rideGroup.addAll(details);
        if ((widget.rideGroup["myRole"] == null ||
                widget.rideGroup["myRole"].toString().isEmpty) &&
            preservedMyRole != null) {
          widget.rideGroup["myRole"] = preservedMyRole;
        }
      });
    } catch (_) {}

    try {
      final preRideInfo = await GroupService.fetchPreRideInfo(
        widget.token,
        _groupUuid,
      );
      if (!mounted) return;
      setState(() {
        widget.rideGroup["preRideInfo"] = preRideInfo;
      });
    } catch (_) {}
  }

  Future<void> _openAnnouncementComposer(
    String currentUserRole,
    AppThemeConfig theme,
  ) async {
    if (_isGroupLocked) {
      _showMessage("This group is locked", isError: true);
      return;
    }

    if (!_isRideManagerRole(currentUserRole)) {
      _showMessage(
        "Only captain/admin can publish announcements",
        isError: true,
      );
      return;
    }

    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "New announcement",
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Share an update with everyone in this ride.",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Type announcement message",
                  hintStyle: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0x52B8C6DA)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final message = controller.text.trim();
                      if (message.isEmpty) {
                        _showMessage(
                          "Announcement message is required",
                          isError: true,
                        );
                        return;
                      }

                      try {
                        await NotificationService().sendRideAnnouncement(
                          token: widget.token,
                          rideUuid: _rideUuid,
                          message: message,
                        );
                        if (!sheetContext.mounted || !mounted) return;
                        Navigator.pop(sheetContext);
                        _showMessage("Announcement sent");
                      } catch (e) {
                        _showMessage(
                          e.toString().replaceFirst("Exception: ", ""),
                          isError: true,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                    ),
                    child: Text(
                      "Send",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshMembers() async {
    if (!mounted) return;
    setState(() {
      _refreshCounter++;
    });
  }

  Future<void> _showRolePicker(
    Map<String, dynamic> member,
    AppThemeConfig theme,
  ) async {
    final String currentRole = member["role"] ?? "RIDER";
    String selectedRole = currentRole;
    List<String> availableRoles = RideService.availableRoles;

    try {
      availableRoles = await RideService.fetchRoles(widget.token);
    } catch (_) {}

    if (!mounted) return;

    final String? nextRole = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.background,
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
                    Text(
                      "Change role",
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pick a role for ${member["username"] ?? "this rider"}.",
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x52B8C6DA)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          isExpanded: true,
                          dropdownColor: theme.surface,
                          style: TextStyle(color: theme.textPrimary),
                          items: availableRoles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                _formatRoleLabel(role),
                                style: TextStyle(color: theme.textPrimary),
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
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
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
      if (_isSubGroup) {
        await SubGroupService.updateSubGroupMemberRole(
          widget.token,
          _groupUuid,
          member["userUuid"],
          nextRole,
        );
      } else {
        await RideService.updateUserRole(
          widget.token,
          _rideUuid,
          member["userUuid"],
          nextRole,
        );
      }
      _showMessage("Role updated to ${_formatRoleLabel(nextRole)}");
      await _refreshMembers();
    } catch (e) {
      _showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  Future<void> _removeMember(
    Map<String, dynamic> member,
    AppThemeConfig theme,
  ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: theme.surface,
              title: Text(
                "Remove $_memberNoun?",
                style: TextStyle(color: theme.textPrimary),
              ),
              content: Text(
                _isSubGroup
                    ? "This will remove ${member["username"] ?? "this rider"} from the subgroup."
                    : "This will remove ${member["username"] ?? "this rider"} from the ride.",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                ),
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
      if (_isSubGroup) {
        await SubGroupService.removeSubGroupMember(
          widget.token,
          _groupUuid,
          member["userUuid"],
        );
      } else {
        await RideService.removeMember(
          widget.token,
          _rideUuid,
          member["userUuid"],
        );
      }
      _showMessage(
        _isSubGroup
            ? "Member removed from subgroup"
            : "Member removed from ride",
      );
      await _refreshMembers();
    } catch (e) {
      _showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  Future<List<dynamic>> fetchMembers() async {
    if (_isSubGroup) {
      return SubGroupService.fetchSubGroupMembers(widget.token, _groupUuid);
    }

    final result = await GroupService.fetchRideMembers(widget.token, _rideUuid);

    return result["data"] ?? [];
  }

  Widget _infoRow(String label, dynamic value, AppThemeConfig theme) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text("$label: $value", style: TextStyle(color: theme.textPrimary)),
    );
  }

  bool _canEditPreRide(String currentUserRole) {
    if (_isGroupLocked || _isRideStarted) return false;
    return _canManageMembers(currentUserRole);
  }

  Future<void> _shareGroupLink() async {
    final link = "throttle://groups/$_groupUuid";
    await Clipboard.setData(ClipboardData(text: link));
    _showMessage("Group link copied");
  }

  Future<void> _renameCurrentGroup(
    String currentUserRole,
    AppThemeConfig theme,
  ) async {
    if (!_canRenameGroup(currentUserRole)) {
      _showMessage(
        _isRideStarted
            ? "Ride setup is frozen after the ride starts"
            : "Only captain/admin can rename this group",
        isError: true,
      );
      return;
    }

    final controller = TextEditingController(
      text: (widget.rideGroup["title"] ?? widget.rideGroup["name"] ?? "")
          .toString(),
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Change Group Name",
                style: TextStyle(color: theme.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Enter group name",
                  hintStyle: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updated = await SubGroupService.renameGroup(
                      widget.token,
                      _groupUuid,
                      controller.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    setState(() {
                      widget.rideGroup.addAll(updated);
                      widget.rideGroup["title"] =
                          updated["title"] ?? updated["name"];
                      widget.rideGroup["name"] =
                          updated["name"] ??
                          updated["title"] ??
                          widget.rideGroup["name"];
                    });
                    _showMessage("Group name updated");
                  } catch (e) {
                    _showMessage(
                      e.toString().replaceFirst("Exception: ", ""),
                      isError: true,
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinCurrentSubGroup() async {
    try {
      final updated = await SubGroupService.joinSubGroup(
        widget.token,
        _groupUuid,
      );
      if (!mounted) return;
      setState(() {
        widget.rideGroup.addAll(updated);
      });
      _showMessage(
        widget.rideGroup["joinRequestPending"] == true
            ? "Join request sent"
            : "Joined subgroup",
      );
      await _refreshMembers();
      await _loadGroupDetails();
    } catch (e) {
      _showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  Future<void> _leaveCurrentGroup() async {
    try {
      if (_isSubGroup) {
        await SubGroupService.leaveSubGroup(widget.token, _groupUuid);
        if (!mounted) return;
        _showMessage("Exited subgroup");
      } else {
        await RideService.leaveRide(widget.token, _rideUuid);
        if (!mounted) return;
        _showMessage("Exited ride");
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }
  }

  Widget _joinRequestsSection(String currentUserRole, AppThemeConfig theme) {
    if (!_isSubGroup || !_canManageMembers(currentUserRole)) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SubGroupService.fetchJoinRequests(widget.token, _groupUuid),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Join Requests",
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...requests.map((request) {
              final requestId = request["requestId"] as int?;
              final name =
                  (request["username"] ?? "").toString()
                      .trim();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x52B8C6DA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Rider" : name,
                      style: TextStyle(color: theme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: requestId == null
                                ? null
                                : () async {
                                    await SubGroupService.rejectJoinRequest(
                                      widget.token,
                                      _groupUuid,
                                      requestId,
                                    );
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                            child: const Text("Reject"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: requestId == null
                                ? null
                                : () async {
                                    try {
                                      await SubGroupService.approveJoinRequest(
                                        widget.token,
                                        _groupUuid,
                                        requestId,
                                      );
                                      if (!mounted) return;
                                      _showMessage("Join request approved");
                                      await _refreshMembers();
                                      await _loadGroupDetails();
                                      setState(() {});
                                    } catch (e) {
                                      _showMessage(
                                        e.toString().replaceFirst(
                                          "Exception: ",
                                          "",
                                        ),
                                        isError: true,
                                      );
                                    }
                                  },
                            child: const Text("Approve"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppThemeConfig theme,
    bool enabled = true,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: enabled
                      ? theme.surface
                      : theme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x52B8C6DA)),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? theme.primary
                      : theme.textPrimary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled
                      ? theme.textPrimary.withValues(alpha: 0.7)
                      : theme.textPrimary.withValues(alpha: 0.4),
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
    required AppThemeConfig theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: theme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preRideHeroCard(
    Map<String, dynamic> preRideInfo,
    AppThemeConfig theme,
  ) {
    final meetingPoint =
        (preRideInfo["meetingPoint"] ?? "No meeting point added").toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x337D39EB), Color(0x22C6FF33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.place_rounded, color: theme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Meeting Point",
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meetingPoint,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
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
    AppThemeConfig theme,
  ) {
    final bool canManageRoles = _canManageMembers(currentUserRole);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final String name =
            (member["username"] ?? "").toString().trim();
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
                    backgroundColor: theme.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: Icon(Icons.info_outline, color: theme.textPrimary),
                title: Text(
                  "View Profile",
                  style: TextStyle(color: theme.textPrimary),
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
                  leading: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xff191B22),
                  ),
                  title: Text(
                    "Change Role",
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  subtitle: Text(
                    "Current: ${_formatRoleLabel(role)}",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.65),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.textPrimary.withValues(alpha: 0.4),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRolePicker(Map<String, dynamic>.from(member), theme);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.remove_circle, color: Colors.red),
                  title: Text(
                    _isSubGroup ? "Remove from Subgroup" : "Remove from Ride",
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeMember(Map<String, dynamic>.from(member), theme);
                  },
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x52B8C6DA)),
                  ),
                  child: Text(
                    "Only riders with the CAPTAIN or ADMIN role can assign roles or remove members.",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.65),
                    ),
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

  void _editDescription(AppThemeConfig theme) {
    final currentUserRole = (widget.rideGroup["myRole"] ?? "").toString();
    if (_isSubGroup) {
      _showMessage("Subgroup description editing is not available yet");
      return;
    }
    if (!_canManageMembers(currentUserRole)) {
      _showMessage(
        "Only captain/admin can edit the description",
        isError: true,
      );
      return;
    }
    if (_isGroupLocked) {
      _showMessage("This group is locked", isError: true);
      return;
    }
    TextEditingController controller = TextEditingController(
      text: widget.rideGroup["description"],
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Description",
                style: TextStyle(color: theme.textPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                style: TextStyle(color: theme.textPrimary),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Enter group description",
                  hintStyle: TextStyle(color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await GroupService.updateRide(widget.token, _rideUuid, {
                    "description": controller.text,
                  });
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

  void _openSubGroupInfo(Map<String, dynamic> subgroup) {
    final subgroupData = <String, dynamic>{
      ...widget.rideGroup,
      ...subgroup,
      "title": subgroup["name"] ?? widget.rideGroup["title"] ?? "Subgroup",
      "isSubGroup": true,
      "myRole": subgroup["myRole"] ?? widget.rideGroup["myRole"],
      "createdByName":
          subgroup["createdByName"] ?? widget.rideGroup["createdByName"],
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RideInfoScreen(rideGroup: subgroupData, token: widget.token),
      ),
    );
  }

  Widget _subGroupsSection(AppThemeConfig theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SubGroupService.fetchSubGroups(widget.token, _rideUuid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final subGroups = snapshot.data ?? [];
        if (subGroups.isEmpty) {
          return const Text(
            "No subgroups created yet.",
            style: TextStyle(color: Color(0xff4F596E)),
          );
        }

        return Column(
          children: subGroups.map((subgroup) {
            final memberCount = subgroup["memberCount"];
            final subgroupRole =
                (subgroup["myRole"] ?? widget.rideGroup["myRole"] ?? "")
                    .toString();
            final canManageSubgroup = _canManageMembers(subgroupRole);
            final canShowJoinAction =
                !_isGroupMember(subgroup) &&
                !canManageSubgroup &&
                (subgroup["joinRequestPending"] == true ||
                    subgroup["canRequestToJoin"] == true ||
                    subgroup["canJoinDirectly"] == true);
            final subtitleParts = [
              subgroup["visibility"]?.toString() ?? "",
              if (_isGroupMember(subgroup))
                "Joined"
              else if (subgroup["joinRequestPending"] == true)
                "Request pending"
              else if (subgroup["canRequestToJoin"] == true)
                "Approval required"
              else if (subgroup["canJoinDirectly"] == true)
                "Open to join",
              if (memberCount != null) "$memberCount members",
            ].where((part) => part.isNotEmpty).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x52B8C6DA)),
              ),
              child: ListTile(
                onTap: () =>
                    _openSubGroupInfo(Map<String, dynamic>.from(subgroup)),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.group_work_outlined, color: theme.primary),
                ),
                title: Text(
                  subgroup["name"]?.toString() ?? "Subgroup",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: subtitleParts.isEmpty
                    ? null
                    : Text(
                        subtitleParts.join(" • "),
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.65),
                        ),
                      ),
                trailing: _isGroupMember(subgroup) || canManageSubgroup
                    ? const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      )
                    : canShowJoinAction
                    ? ElevatedButton(
                        onPressed: subgroup["joinRequestPending"] == true
                            ? null
                            : () async {
                                try {
                                  final updated =
                                      await SubGroupService.joinSubGroup(
                                        widget.token,
                                        subgroup["uuid"].toString(),
                                      );
                                  if (!mounted) return;
                                  subgroup.addAll(updated);
                                  _showMessage(
                                    updated["joinRequestPending"] == true
                                        ? "Join request sent"
                                        : "Joined subgroup",
                                  );
                                  setState(() {});
                                  await _refreshMembers();
                                  await _loadGroupDetails();
                                } catch (e) {
                                  _showMessage(
                                    e.toString().replaceFirst(
                                      "Exception: ",
                                      "",
                                    ),
                                    isError: true,
                                  );
                                }
                              },
                        child: Text(
                          subgroup["joinRequestPending"] == true
                              ? "Pending"
                              : subgroup["canRequestToJoin"] == true
                              ? "Request"
                              : "Join",
                        ),
                      )
                    : const Icon(Icons.chevron_right, color: Color(0xff697389)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statTile(IconData icon, String label, AppThemeConfig theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x52B8C6DA)),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(String currentUserRole, AppThemeConfig theme) {
    final name =
        widget.rideGroup["title"] ?? widget.rideGroup["name"] ?? "Ride";
    final creatorUser = widget.rideGroup["createdByUser"];
    final creatorName = creatorUser != null
        ? (creatorUser["username"] ?? "").toString()
              .trim()
        : (widget.rideGroup["createdByName"]?.toString().trim().isNotEmpty ??
              false)
        ? widget.rideGroup["createdByName"].toString().trim()
        : "Unknown";

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
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.directions_bike,
                  size: 32,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textPrimary,
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
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.6),
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
                    enabled:
                        !_isSubGroup &&
                        !_isGroupLocked &&
                        _isRideManagerRole(currentUserRole),
                    onTap: () {
                      _openAnnouncementComposer(currentUserRole, theme);
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.person_add_alt_1,
                    label: "Add Members",
                    enabled: _canOpenAddMembers(currentUserRole),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InviteMemberScreen(
                            rideUuid: _rideUuid,
                            subgroupUuid: _isSubGroup ? _groupUuid : null,
                            token: widget.token,
                            preRideFrozen: _isRideStarted,
                          ),
                        ),
                      ).then((result) async {
                        if (result == true) {
                          await _refreshMembers();
                        }
                      });
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _quickAction(
                    icon: Icons.route_outlined,
                    label: "Pre-Ride Info",
                    onTap: () {
                      _showPreRideDetails(currentUserRole, theme);
                    },
                    theme: theme,
                  ),
                ],
              ),
              if (_canJoinCurrentSubGroup()) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.rideGroup["joinRequestPending"] == true
                        ? null
                        : _joinCurrentSubGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      widget.rideGroup["joinRequestPending"] == true
                          ? "Request Pending"
                          : widget.rideGroup["canRequestToJoin"] == true
                          ? "Request to Join"
                          : "Join Subgroup",
                    ),
                  ),
                ),
              ],
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
            theme,
          ),
        ],
      ],
    );
  }

  String formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showPreRideDetails(String currentUserRole, AppThemeConfig theme) {
    final preRideInfo = Map<String, dynamic>.from(
      widget.rideGroup["preRideInfo"] ?? {},
    );
    final canEditPreRide = _canEditPreRide(currentUserRole);
    final checkpoints =
        (preRideInfo["checkpointList"] as List?)
            ?.whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        [];
    final rules =
        (preRideInfo["ruleList"] as List?)
            ?.whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
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
                      Expanded(
                        child: Text(
                          "Pre-Ride Information",
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canEditPreRide)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _openPreRideInfo(theme, canEdit: true);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text("Edit"),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_isGroupLocked)
                    Text(
                      "This group is archived. Editing is disabled.",
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                  if (_isGroupLocked) const SizedBox(height: 8),
                  Text(
                    preRideInfo.isEmpty
                        ? "No pre-ride briefing has been added yet."
                        : "Ride setup and briefing shared by the captain/admin.",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (preRideInfo.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x52B8C6DA)),
                      ),
                      child: Text(
                        "Add meeting point, checkpoints, rules, notes, and ride setup details here.",
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.65),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((preRideInfo["meetingPoint"] ?? "")
                            .toString()
                            .isNotEmpty)
                          _preRideHeroCard(preRideInfo, theme),
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
                              value:
                                  (preRideInfo["rideType"] ??
                                          widget.rideGroup["rideType"] ??
                                          "Ride")
                                      .toString(),
                              theme: theme,
                            ),
                            _preRideFeature(
                              icon: Icons.map_outlined,
                              label: "Route Type",
                              value:
                                  (preRideInfo["routeType"] ??
                                          widget.rideGroup["routeType"] ??
                                          "Route")
                                      .toString(),
                              theme: theme,
                            ),
                            _preRideFeature(
                              icon: Icons.people_outline,
                              label: "Max Riders",
                              value:
                                  (preRideInfo["maxRiders"] ??
                                          widget.rideGroup["maxRiders"] ??
                                          "-")
                                      .toString(),
                              theme: theme,
                            ),
                            _preRideFeature(
                              icon: Icons.visibility_outlined,
                              label: "Visibility",
                              value:
                                  (preRideInfo["visibility"] ??
                                          widget.rideGroup["visibility"] ??
                                          "PUBLIC")
                                      .toString(),
                              theme: theme,
                            ),
                            _preRideFeature(
                              icon: Icons.local_gas_station_outlined,
                              label: "Fuel Stops",
                              value: (preRideInfo["fuelStops"] ?? "-")
                                  .toString(),
                              theme: theme,
                            ),
                            _preRideFeature(
                              icon: Icons.sticky_note_2_outlined,
                              label: "Notes",
                              value:
                                  ((preRideInfo["notes"] ?? "")
                                      .toString()
                                      .isEmpty)
                                  ? "No notes added"
                                  : preRideInfo["notes"].toString(),
                              theme: theme,
                            ),
                          ],
                        ),
                        if (checkpoints.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            "Checkpoints",
                            style: TextStyle(
                              color: theme.textPrimary,
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
                                      color: theme.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0x52B8C6DA),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.place_outlined,
                                          size: 16,
                                          color: theme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item,
                                          style: TextStyle(
                                            color: theme.textPrimary.withValues(
                                              alpha: 0.65,
                                            ),
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
                          Text(
                            "Ride Rules",
                            style: TextStyle(
                              color: theme.textPrimary,
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
                                      color: theme.surface,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0x52B8C6DA),
                                      ),
                                    ),
                                    child: Text(
                                      rule,
                                      style: TextStyle(
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.65,
                                        ),
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

  void _openPreRideInfo(AppThemeConfig theme, {bool canEdit = true}) {
    if (!canEdit) {
      _showPreRideDetails(_currentUserRoleFromMembers(const []), theme);
      return;
    }

    int step = 0;
    final existingPreRide = Map<String, dynamic>.from(
      widget.rideGroup["preRideInfo"] ?? {},
    );

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
    final meetingFocusNode = FocusNode();
    Timer? meetingSearchDebounce;
    int meetingSearchRequestId = 0;
    bool isMeetingSearchLoading = false;
    String? meetingSearchError;
    List<Map<String, String>> meetingSuggestions = [];

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

    void disposePreRideControllers() {
      meetingSearchDebounce?.cancel();
      meetingController.dispose();
      fuelController.dispose();
      checkpointController.dispose();
      notesController.dispose();
      meetingFocusNode.dispose();
    }

    void clearMeetingSuggestions(StateSetter setModalState) {
      setModalState(() {
        isMeetingSearchLoading = false;
        meetingSearchError = null;
        meetingSuggestions = [];
      });
    }

    void selectMeetingSuggestion(
      StateSetter setModalState,
      Map<String, String> suggestion,
    ) {
      meetingController.text =
          suggestion["fullText"] ?? suggestion["title"] ?? "";
      meetingController.selection = TextSelection.collapsed(
        offset: meetingController.text.length,
      );
      meetingFocusNode.unfocus();
      clearMeetingSuggestions(setModalState);
    }

    void scheduleMeetingSearch(StateSetter setModalState, String rawQuery) {
      meetingSearchDebounce?.cancel();
      final query = rawQuery.trim();

      if (query.length < 3) {
        clearMeetingSuggestions(setModalState);
        return;
      }

      meetingSearchDebounce = Timer(
        const Duration(milliseconds: 900),
        () async {
          final requestId = ++meetingSearchRequestId;
          setModalState(() {
            isMeetingSearchLoading = true;
            meetingSearchError = null;
          });

          try {
            final suggestions = await PlaceService.searchPlaces(query);

            if (!mounted || requestId != meetingSearchRequestId) return;

            setModalState(() {
              isMeetingSearchLoading = false;
              meetingSuggestions = suggestions;
              meetingSearchError = suggestions.isEmpty
                  ? "No places found"
                  : null;
            });
          } catch (error) {
            if (!mounted || requestId != meetingSearchRequestId) return;

            setModalState(() {
              isMeetingSearchLoading = false;
              meetingSuggestions = [];
              meetingSearchError = error.toString().replaceFirst(
                "Exception: ",
                "",
              );
            });
          }
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
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
                  Text(
                    "Meeting Point",
                    style: TextStyle(color: theme.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: meetingController,
                    focusNode: meetingFocusNode,
                    style: TextStyle(color: theme.textPrimary),
                    decoration:
                        _inputDecoration(
                          "Search meetup location",
                          theme,
                        ).copyWith(
                          prefixIcon: Icon(Icons.search, color: theme.primary),
                          suffixIcon: isMeetingSearchLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primary,
                                    ),
                                  ),
                                )
                              : (meetingController.text.trim().isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          meetingController.clear();
                                          clearMeetingSuggestions(
                                            setModalState,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: theme.textPrimary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      )
                                    : null),
                        ),
                    onChanged: (value) =>
                        scheduleMeetingSearch(setModalState, value),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Suggestions are powered by OpenStreetMap search and may take a moment to appear.",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (meetingSearchError != null &&
                      meetingController.text.trim().length >= 3) ...[
                    const SizedBox(height: 10),
                    Text(
                      meetingSearchError!,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (meetingSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.white12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: meetingSuggestions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.white12),
                        itemBuilder: (context, index) {
                          final suggestion = meetingSuggestions[index];
                          final title = suggestion["title"] ?? "";
                          final subtitle = suggestion["subtitle"] ?? "";

                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: subtitle.isEmpty
                                ? null
                                : Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: theme.textPrimary.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                            onTap: () => selectMeetingSuggestion(
                              setModalState,
                              suggestion,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    "Type at least 3 characters and pick a place from the search results.",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
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
                  Text(
                    "Fuel & Checkpoints",
                    style: TextStyle(color: theme.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fuelController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: _inputDecoration("Estimated fuel stops", theme),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: checkpointController,
                          style: TextStyle(color: theme.textPrimary),
                          decoration: _inputDecoration(
                            "Add checkpoint location",
                            theme,
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
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.primary,
                          child: Icon(Icons.add, color: Colors.white, size: 18),
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
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x52B8C6DA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.value,
                              style: TextStyle(
                                color: theme.textPrimary,
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
                  Text(
                    "Ride Rules",
                    style: TextStyle(color: theme.textPrimary, fontSize: 16),
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
                            color: selected ? theme.primary : theme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: selected
                                ? null
                                : Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Text(
                            rule,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : theme.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    style: TextStyle(color: theme.textPrimary),
                    decoration: _inputDecoration(
                      "Add custom rule (optional)",
                      theme,
                    ),
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
                    Text(
                      "Preview",
                      style: TextStyle(color: theme.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _preview("Meeting Point", meetingController.text, theme),
                    _preview(
                      "Ride Type",
                      widget.rideGroup["rideType"] ?? "",
                      theme,
                    ),
                    _preview(
                      "Route Type",
                      widget.rideGroup["routeType"] ?? "",
                      theme,
                    ),
                    _preview(
                      "Max Riders",
                      (widget.rideGroup["maxRiders"] ?? "").toString(),
                      theme,
                    ),
                    _preview("Fuel Stops", fuelController.text, theme),
                    _preview("Rules", selectedRules.join(", "), theme),
                    const SizedBox(height: 10),
                    Text(
                      "Checkpoints",
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: checkpoints
                          .map(
                            (c) => ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.place,
                                color: theme.primary,
                                size: 18,
                              ),
                              title: Text(
                                c,
                                style: TextStyle(color: theme.textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: _inputDecoration("Notes (optional)", theme),
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
                                  ? theme.primary
                                  : const Color(0x19000000),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (index < 3)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: index < step
                                      ? theme.primary
                                      : const Color(0x19000000),
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
                            final previousPreRide = Map<String, dynamic>.from(
                              widget.rideGroup["preRideInfo"] ?? {},
                            );
                            final rideTitle =
                                widget.rideGroup["title"]?.toString() ?? "ride";
                            final hadMeetingPoint =
                                (previousPreRide["meetingPoint"] ?? "")
                                    .toString()
                                    .trim()
                                    .isNotEmpty;

                            final requestPayload = {
                              "meetingPoint": meetingController.text.trim(),
                              "fuelStops": fuelController.text.trim(),
                              "checkpointList": checkpoints,
                              "ruleList": selectedRules,
                              "notes": notesController.text.trim(),
                            };

                            GroupService.updatePreRideInfo(
                                  widget.token,
                                  _groupUuid,
                                  requestPayload,
                                )
                                .then((savedPreRideInfo) async {
                                  if (!mounted) return;
                                  final meetingPoint =
                                      savedPreRideInfo["meetingPoint"]
                                          ?.toString() ??
                                      "";

                                  Navigator.pop(context);
                                  setState(() {
                                    widget.rideGroup["preRideInfo"] =
                                        savedPreRideInfo;
                                  });
                                  _showMessage("Pre-ride information saved");

                                  await NotificationService()
                                      .notifyPreRideInfoUpdated(
                                        token: widget.token,
                                        rideTitle: rideTitle,
                                      );

                                  if (!hadMeetingPoint &&
                                      meetingPoint.trim().isNotEmpty) {
                                    await NotificationService()
                                        .notifyMeetingPointSelected(
                                          token: widget.token,
                                          rideTitle: rideTitle,
                                          meetingPoint: meetingPoint,
                                        );
                                  }
                                })
                                .catchError((error) {
                                  _showMessage(
                                    error.toString().replaceFirst(
                                      "Exception: ",
                                      "",
                                    ),
                                    isError: true,
                                  );
                                });
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
    ).whenComplete(disposePreRideControllers);
  }

  // Common input decoration for all text fields
  InputDecoration _inputDecoration(String hint, AppThemeConfig theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.textPrimary.withValues(alpha: 0.4),
        fontSize: 14,
      ),
      filled: true,
      fillColor: theme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Preview row for the last section
  Widget _preview(String title, String content, AppThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              content.isEmpty ? "-" : content,
              style: TextStyle(color: theme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContainer({
    required String title,
    required Widget child,
    required AppThemeConfig theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
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
    required AppThemeConfig theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$index. $text",
              style: TextStyle(color: theme.textPrimary),
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

  Widget _previewCard(String text, AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: theme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _previewTile(String label, String value, AppThemeConfig theme) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    required AppThemeConfig theme,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: theme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textPrimary.withValues(alpha: 0.4)),
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x52B8C6DA)),
        ),
      ),
    );
  }

  Widget _locationField(
    String hint,
    TextEditingController controller,
    AppThemeConfig theme,
  ) {
    return TextField(
      controller: controller,
      readOnly: true, // 🔥 ready for map picker
      style: TextStyle(color: theme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textPrimary.withValues(alpha: 0.4)),
        prefixIcon: Icon(Icons.location_on, color: theme.primary),
        filled: true,
        fillColor: theme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x52B8C6DA)),
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
    AppThemeConfig theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.textPrimary),
        enabled: isEditable, // Enable or disable based on user role
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.65),
          ),
          filled: true,
          fillColor: theme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x52B8C6DA)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description =
        widget.rideGroup["description"] ??
        (_isSubGroup
            ? "This subgroup has its own member roles and access."
            : null);

    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.surface,
            title: Text(
              "Group Info",
              style: TextStyle(color: theme.textPrimary),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
            actions: [
              PopupMenuButton<String>(
                color: theme.surface,
                icon: Icon(Icons.more_vert, color: theme.textPrimary),
                onSelected: (value) {
                  final currentUserRole = (widget.rideGroup["myRole"] ?? "")
                      .toString();
                  if (value == "share") {
                    _shareGroupLink();
                  } else if (value == "rename") {
                    _renameCurrentGroup(currentUserRole, theme);
                  }
                },
                itemBuilder: (context) {
                  final currentUserRole = (widget.rideGroup["myRole"] ?? "")
                      .toString();
                  final items = <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      value: "share",
                      child: Text(
                        "Share Group Link",
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ),
                  ];
                  if (_canRenameGroup(currentUserRole) &&
                      (!_isSubGroup || _isGroupMember(widget.rideGroup))) {
                    items.add(
                      PopupMenuItem(
                        value: "rename",
                        child: Text(
                          "Change Group Name",
                          style: TextStyle(color: theme.textPrimary),
                        ),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ],
          ),
          body: FutureBuilder<List<dynamic>>(
            key: ValueKey(
              _refreshCounter,
            ), // Add key to refresh when counter changes
            future: fetchMembers(),
            builder: (context, snapshot) {
              List members = snapshot.data ?? [];
              final String currentUserRole = _currentUserRoleFromMembers(
                members,
              );

              if (searchQuery.isNotEmpty) {
                members = members.where((m) {
                  final name = (m["username"] ?? "").toString().trim().toLowerCase();
                  return name.contains(searchQuery.toLowerCase());
                }).toList();
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _groupHeader(currentUserRole, theme),
                  const SizedBox(height: 20),

                  /// DESCRIPTION
                  Text(
                    "Description",
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap:
                        (_isGroupLocked ||
                            _isSubGroup ||
                            !_canManageMembers(currentUserRole))
                        ? null
                        : () => _editDescription(theme),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x52B8C6DA)),
                      ),
                      child: Text(
                        description ?? "Add group description",
                        style: TextStyle(
                          color: description == null
                              ? theme.textPrimary.withValues(alpha: 0.4)
                              : theme.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (!_isSubGroup) ...[
                    Text(
                      "Subgroups",
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _subGroupsSection(theme),
                    const SizedBox(height: 20),
                  ],

                  _joinRequestsSection(currentUserRole, theme),

                  /// SETTINGS
                  Text(
                    "Settings",
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SwitchListTile(
                    value: true,
                    onChanged: _isGroupLocked ? null : (_) {},
                    title: Text(
                      "Notifications",
                      style: TextStyle(color: theme.textPrimary),
                    ),
                  ),

                  ListTile(
                    title: Text(
                      "Group Visibility",
                      style: TextStyle(color: theme.textPrimary),
                    ),
                    subtitle: Text(
                      widget.rideGroup["visibility"] ?? "PUBLIC",
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// PARTICIPANTS HEADER
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${members.length} $_memberNoun",
                        style: TextStyle(
                          color: theme.primary,
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
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Search riders...",
                      hintStyle: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.textPrimary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: theme.surface,
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
                    Text(
                      "No $_memberNoun found",
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.65),
                      ),
                    )
                  else
                    Column(
                      children: members.map((m) {
                        final member = Map<String, dynamic>.from(m);

                        final name =
                            (member["username"] ?? "").toString()
                                .trim();

                        return ListTile(
                          onTap: () => _openMemberSheet(
                            context,
                            member,
                            currentUserRole,
                            theme,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: theme.primary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "R",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(color: theme.textPrimary),
                          ),
                          trailing: Text(
                            member["role"] ?? "",
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.65),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 30),

                  /// EXIT GROUP
                  if (!_isSubGroup || _isGroupMember(widget.rideGroup))
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          _leaveCurrentGroup();
                        },
                        child: Text(
                          _isSubGroup ? "Exit Subgroup" : "Exit Group",
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
