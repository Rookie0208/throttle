import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/invite_member_screen.dart';

import 'package:throttle_ui/services/sub_groups_service.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class CreateSubGroupScreen extends StatefulWidget {

  final String rideId;
  final String token;

  const CreateSubGroupScreen({
    super.key,
    required this.rideId,
    required this.token,
  });

  @override
  State<CreateSubGroupScreen> createState() => _CreateSubGroupScreenState();
}

class _CreateSubGroupScreenState extends State<CreateSubGroupScreen> {

  final TextEditingController nameController = TextEditingController();

  String visibility = "PRIVATE";

  bool membersCanMessage = true;
  bool membersCanAddMembers = false;
  bool adminApprovalRequired = true;

  List selectedMembers = [];

  void _selectMembers() async {
    // Navigate to member picker screen
    final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InviteMemberScreen(
        groupId: widget.rideId,
        token: widget.token,
      ),
    ),
  );

  if (result != null) {
    setState(() {
      selectedMembers = result;
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

  final payload = {
    "rideUuid": widget.rideId,   // ✅ ADDED
    "name": nameController.text.trim(),
    "visibility": visibility,
    "permissions": {
      "membersCanSendMessages": membersCanMessage,
      "membersCanAddMembers": membersCanAddMembers,
      "adminsApproveMembers": adminApprovalRequired
    },
    "members": selectedMembers
  };

  try {

    final result = await SubGroupService.createSubGroup(
      widget.token,
      payload,
    );

    Navigator.pop(context, result);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subgroup created successfully")),
    );

    Navigator.pop(context, result);

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to create subgroup")),
    );

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

                RadioListTile(
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
                      visibility = v!;
                    });
                  },
                ),

                RadioListTile(
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
                      visibility = v!;
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
            onPressed: _createSubGroup,
            child: const Text(
              "Create Subgroup",
              style: TextStyle(fontSize: 16, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}