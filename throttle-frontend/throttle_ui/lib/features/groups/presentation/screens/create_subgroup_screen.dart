import 'package:flutter/material.dart';
import 'package:throttle_ui/features/groups/presentation/screens/invite_member_screen.dart';

import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class CreateSubGroupScreen extends StatefulWidget {
  final String rideUuid;
  final String token;

  const CreateSubGroupScreen({
    super.key,
    required this.rideUuid,
    required this.token,
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InviteMemberScreen(
          rideUuid: widget.rideUuid,
          token: widget.token,
          selectionOnly: true,
          preselectedMemberUuids: selectedMembers,
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
      final result = await SubGroupService.createSubGroup(widget.token, payload);

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

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Create Subgroup"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// GROUP NAME
          const Text(
            "Subgroup Name",
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: "Ex: Breakfast Crew",
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// VISIBILITY
          const Text(
            "Visibility",
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [

                RadioListTile<String>(
                  value: "PUBLIC",
                  groupValue: visibility,
                  activeColor: AppColors.primary,
                  title: const Text("Public", style: TextStyle(color: AppColors.white)),
                  subtitle: const Text(
                    "Anyone in the ride can join",
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  onChanged: (v) {
                    setState(() {
                      visibility = v;
                    });
                  },
                ),

                RadioListTile<String>(
                  value: "PRIVATE",
                  groupValue: visibility,
                  activeColor: AppColors.primary,
                  title: const Text("Invite Only", style: TextStyle(color: AppColors.white)),
                  subtitle: const Text(
                    "Admin approval required",
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  onChanged: (v) {
                    setState(() {
                      visibility = v;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// PERMISSIONS
          const Text(
            "Permissions",
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [

                SwitchListTile(
                  activeColor: AppColors.primary,
                  value: membersCanMessage,
                  title: const Text(
                    "Members can send messages",
                    style: TextStyle(color: AppColors.white),
                  ),
                  onChanged: (v) {
                    setState(() {
                      membersCanMessage = v;
                    });
                  },
                ),

                SwitchListTile(
                  activeColor: AppColors.primary,
                  value: membersCanAddMembers,
                  title: const Text(
                    "Members can add riders",
                    style: TextStyle(color: AppColors.white),
                  ),
                  onChanged: (v) {
                    setState(() {
                      membersCanAddMembers = v;
                    });
                  },
                ),

                SwitchListTile(
                  activeColor: AppColors.primary,
                  value: adminApprovalRequired,
                  title: const Text(
                    "Admin approval required",
                    style: TextStyle(color: AppColors.white),
                  ),
                  onChanged: (v) {
                    setState(() {
                      adminApprovalRequired = v;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// ADD MEMBERS
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.group_add, color: AppColors.white),
            label: const Text("Add Members",style: TextStyle(color: AppColors.white),),
            onPressed: _selectMembers,
          ),

          const SizedBox(height: 24),

          /// CREATE BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _saving ? null : _createSubGroup,
            child: Text(
              _saving ? "Creating..." : "Create Subgroup",
              style: TextStyle(fontSize: 16, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
