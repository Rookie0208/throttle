import 'package:flutter/material.dart';
import 'package:throttle_ui/features/groups/presentation/screens/create_subgroup_screen.dart';
import 'package:throttle_ui/features/groups/presentation/widgets/group_info_sheet.dart';
import 'package:throttle_ui/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final String token;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.token,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List subGroups = [];
  bool loadingSubGroups = true;

  /// NEW STATE
  String? activeSubGroupId;
  Map<String, dynamic>? activeSubGroup;

  /// messages per chat
  List<Map<String, dynamic>> messages = [];
  bool loadingMessages = true;

  String get _rideUuid =>
      (widget.group["rideUuid"] ?? widget.group["uuid"]).toString();

  String currentUserRole = "MEMBER";

  bool get _isGroupLocked {
    final groupStatus = (widget.group["status"] ?? "").toString().toLowerCase();
    final rideStatus = (widget.group["rideStatus"] ?? "").toString().toUpperCase();
    return groupStatus == "archive" ||
        {"CANCELLED", "COMPLETED", "ENDED"}.contains(rideStatus);
  }

  /// ================= FETCH SUBGROUPS =================
  Future<void> fetchSubGroups() async {
    try {
      final result = await SubGroupService.fetchSubGroups(
        widget.token,
        _rideUuid,
      );

      setState(() {
        subGroups = result;
        loadingSubGroups = false;
      });
    } catch (e) {
      loadingSubGroups = false;
    }
  }

  /// ================= FETCH MESSAGES =================
  Future<void> fetchMessages(String id) async {
    setState(() {
      loadingMessages = true;
    });

    try {
      /// TODO: Replace with API
      await Future.delayed(const Duration(milliseconds: 500));

      /// DEMO DATA
      List data = id == widget.group["uuid"]
          ? [
              {
                "sender": "Mike",
                "message": "Main group message",
                "time": "08:00 AM"
              }
            ]
          : [];

      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
        loadingMessages = false;
      });
    } catch (e) {
      loadingMessages = false;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSubGroups();

    /// load main chat initially
    fetchMessages(widget.group["uuid"]);
  }

  /// ================= SEND =================
  void sendMessage() {
    if (_isGroupLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This group is locked")),
      );
      return;
    }
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({
        "sender": "You",
        "message": text,
        "time": TimeOfDay.now().format(context),
      });
      messageController.clear();
    });
  }

  /// ================= UI =================
  Widget _buildMessage(Map<String, dynamic> msg) {
    bool isMe = msg["sender"] == "You";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg["sender"],
                  style:
                      const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(msg["message"],
                style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  /// ================= SUBGROUP BAR =================
  Widget _subGroupBar() {
    if (loadingSubGroups) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    /// ROLE BASED FILTER
    return Container(
      height: 50,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          /// MAIN GROUP
          GestureDetector(
            onTap: () {
              setState(() {
                activeSubGroup = null;
                activeSubGroupId = null;
              });
              fetchMessages(widget.group["uuid"]);
            },
            child: _chip(
              "All",
              activeSubGroupId == null,
            ),
          ),

          ...subGroups.map((g) {
            final isSelected = activeSubGroupId == g["uuid"];

            return GestureDetector(
              onTap: () {
                setState(() {
                  activeSubGroupId = g["uuid"];
                  activeSubGroup = g;
                });

                fetchMessages(g["uuid"]);
              },
              child: _chip(g["name"], isSelected),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ================= MESSAGE AREA =================
  Widget _chatArea() {
    if (loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          "No messages yet",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (_, i) => _buildMessage(messages[i]),
    );
  }

  Widget _messageInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: "Type message...",
                hintStyle: TextStyle(color: AppColors.textHint),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: sendMessage,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isActive =
        (activeSubGroup?["status"] ?? widget.group["status"]) == "active";

    return Scaffold(
      backgroundColor: AppColors.background,
     appBar: AppBar(
  backgroundColor: AppColors.surface,
  title: Text(
    activeSubGroup != null
        ? "${widget.group["name"]} • ${activeSubGroup!["name"]}"
        : widget.group["name"],
  ),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.white),
      color: AppColors.surface,
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'info',
          child: Text("Group Info", style: TextStyle(color: AppColors.white)),
        ),
        const PopupMenuItem(
          value: 'invite',
          child: Text("Invite Riders", style: TextStyle(color: AppColors.white)),
        ),
        const PopupMenuItem(
          value: 'subgroup',
          child: Text("Create Subgroup", style: TextStyle(color: AppColors.white)),
        ),
        const PopupMenuItem(
          value: 'leave',
          child: Text("Leave Group", style: TextStyle(color: AppColors.white)),
        ),
      ],
    ),
  ],
),
      body: Column(
        children: [
          _subGroupBar(),

          if (!isActive)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _isGroupLocked
                    ? "This group is locked. Editing and messaging are disabled."
                    : "Messaging disabled",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),

          Expanded(child: _chatArea()),

          if (isActive) _messageInput(),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
  switch (value) {
    case 'info':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideInfoScreen(
            rideGroup: widget.group,
            token: widget.token,
          ),
        ),
      );
      break;

    case 'invite':
      if (_isGroupLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This group is locked")),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InviteMemberScreen(
            rideUuid: _rideUuid,
            token: widget.token,
          ),
        ),
      );
      break;

    case 'subgroup':
      if (_isGroupLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This group is locked")),
        );
        return;
      }
      _openSubGroupCreation();
      break;

    case 'leave':
      _leaveGroup();
      break;
  }
}

void _openSubGroupCreation() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreateSubGroupScreen(
        rideUuid: _rideUuid,
        token: widget.token,
      ),
    ),
  );

  /// If subgroup created successfully
  if (result != null) {
    /// Refresh subgroup list
    await fetchSubGroups();

    /// Auto-switch to new subgroup
    setState(() {
      activeSubGroup = result;
      activeSubGroupId = result["uuid"];
    });

    /// Load its messages
    fetchMessages(result["uuid"]);
  }
}

void _leaveGroup() async {
  // TODO: call backend API

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Left group")),
  );

  Navigator.pop(context);
}
}
