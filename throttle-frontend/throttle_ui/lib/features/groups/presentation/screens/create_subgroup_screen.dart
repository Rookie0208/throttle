import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class CreateSubGroupScreen extends StatefulWidget {
  final String rideUuid;
  final String token;
  final bool preRideFrozen;

  const CreateSubGroupScreen({
    super.key,
    required this.rideUuid,
    required this.token,
    this.preRideFrozen = false,
  });

  @override
  State<CreateSubGroupScreen> createState() => _CreateSubGroupScreenState();
}

class _CreateSubGroupScreenState extends State<CreateSubGroupScreen> {
  final TextEditingController nameController = TextEditingController();
  String? visibility;

  bool membersCanMessage = true;
  bool membersCanAddMembers = false;
  bool adminApprovalRequired = true;

  List<String> selectedMembers = [];
  bool _saving = false;

  void _selectMembers() async {
    if (widget.preRideFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride setup is frozen after start')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InviteMemberScreen(
          rideUuid: widget.rideUuid,
          token: widget.token,
          selectionOnly: true,
          preselectedMemberUuids: selectedMembers,
          preRideFrozen: widget.preRideFrozen,
        ),
      ),
    );

    if (result is List) {
      setState(() {
        selectedMembers = result.map((item) => item.toString()).toList();
      });
    }
  }

  Future<void> _createSubGroup() async {
    if (widget.preRideFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride setup is frozen after start')),
      );
      return;
    }

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subgroup name is required")),
      );
      return;
    }
    if (visibility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select subgroup visibility")),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = {
      "rideUuid": widget.rideUuid,
      "name": nameController.text.trim(),
      "visibility": visibility,
      "membersCanSendMessages": membersCanMessage,
      "membersCanAddMembers": membersCanAddMembers,
      "adminsApproveMembers": adminApprovalRequired,
      "memberUuids": selectedMembers,
    };

    try {
      final result = await SubGroupService.createSubGroup(
        widget.token,
        payload,
      );

      await NotificationService().notifySubGroupCreated(
        token: widget.token,
        subgroupName: nameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subgroup created successfully")),
      );
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            title: Text(
              "CREATE SUBGROUP",
              style: GoogleFonts.bebasNeue(
                color: theme.textPrimary,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// GROUP NAME
              _sectionHeader("Subgroup Name", theme),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Ex: Breakfast Crew",
                  hintStyle: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.textPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// VISIBILITY
              _sectionHeader("Visibility", theme),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.textPrimary.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: "PUBLIC",
                      groupValue: visibility,
                      activeColor: theme.primary,
                      title: Text(
                        "Public",
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      subtitle: Text(
                        "Anyone in the ride can join",
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      onChanged: (v) => setState(() => visibility = v),
                    ),
                    RadioListTile<String>(
                      value: "PRIVATE",
                      groupValue: visibility,
                      activeColor: theme.primary,
                      title: Text(
                        "Invite Only",
                        style: TextStyle(color: theme.textPrimary),
                      ),
                      subtitle: Text(
                        "Admin approval required",
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      onChanged: (v) => setState(() => visibility = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// PERMISSIONS
              _sectionHeader("Permissions", theme),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.textPrimary.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      "Members can send messages",
                      membersCanMessage,
                      theme,
                      (v) => setState(() => membersCanMessage = v),
                    ),
                    _buildSwitchTile(
                      "Members can add riders",
                      membersCanAddMembers,
                      theme,
                      (v) => setState(() => membersCanAddMembers = v),
                    ),
                    _buildSwitchTile(
                      "Admin approval required",
                      adminApprovalRequired,
                      theme,
                      (v) => setState(() => adminApprovalRequired = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ADD MEMBERS
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.group_add, color: theme.primary),
                label: Text(
                  "ADD MEMBERS (${selectedMembers.length})",
                  style: GoogleFonts.bebasNeue(
                    color: theme.primary,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
                onPressed: widget.preRideFrozen ? null : _selectMembers,
              ),

              const SizedBox(height: 24),

              /// CREATE BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _saving || widget.preRideFrozen ? null : _createSubGroup,
                child: Text(
                  _saving ? "CREATING..." : "CREATE SUBGROUP",
                  style: GoogleFonts.bebasNeue(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, AppThemeConfig theme) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.bebasNeue(
        color: theme.textPrimary,
        fontSize: 18,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    AppThemeConfig theme,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      activeColor: theme.primary,
      value: value,
      title: Text(
        title,
        style: TextStyle(color: theme.textPrimary, fontSize: 14),
      ),
      onChanged: onChanged,
    );
  }
}
