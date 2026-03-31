import 'package:flutter/material.dart';
import 'package:throttle_ui/core/globals.dart';
import 'package:throttle_ui/features/groups/presentation/widgets/group_info_sheet.dart';
import 'package:throttle_ui/features/groups/data/services/chat_service.dart';
import 'package:throttle_ui/features/groups/presentation/screens/create_subgroup_screen.dart';
import 'package:throttle_ui/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final String token;

  const GroupChatScreen({super.key, required this.group, required this.token});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late ChatService chatSocket;

  List subGroups = [];
  bool loadingSubGroups = true;

  String? activeSubGroupId;
  Map<String, dynamic>? activeSubGroup;

  List<Map<String, dynamic>> messages = [];
  bool loadingMessages = true;

  String currentUserRole = "MEMBER";

  /// ✅ SINGLE SOURCE OF TRUTH
  String get currentGroupId => activeSubGroupId ?? widget.group["groupId"];

  bool get _isGroupLocked {
    final groupStatus = (widget.group["status"] ?? "").toString().toLowerCase();
    final rideStatus = (widget.group["rideStatus"] ?? "")
        .toString()
        .toUpperCase();

    return groupStatus == "archive" ||
        {"CANCELLED", "COMPLETED", "ENDED"}.contains(rideStatus);
  }

  /// ================= SOCKET LISTENER =================
  void _onSocketMessage(dynamic data) {
    print(" UI received message: $data");

    setState(() {
      messages.add({
        "group": data["groupId"],
        "senderId": data["senderId"],
        "senderName": data["senderName"],
        "message": data["message"],
        "time": TimeOfDay.now().format(context),
      });
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ================= FETCH SUBGROUPS =================
  Future<void> fetchSubGroups() async {
    try {
      final result = await SubGroupService.fetchSubGroups(
        widget.token,
        widget.group["uuid"],
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
  Future<void> fetchMessages(String groupId) async {
    setState(() => loadingMessages = true);

    try {
      final data = await ChatService.fetchMessages(groupId);

      print("BACKEND DATA: $data");

      setState(() {
        messages = List<Map<String, dynamic>>.from(
          data.map(
            (m) => {
              "group": m["groupId"],
              "senderId": m["senderId"],
              "senderName": m["senderName"],
              "message": m["message"],
              "time": m["createdAt"],
            },
          ),
        );

        loadingMessages = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print("❌ fetchMessages error: $e");
      setState(() => loadingMessages = false);
    }
  }

  /// ================= INIT =================
  @override
  void initState() {
    super.initState();

    fetchSubGroups();

    chatSocket = ChatService();

    chatSocket.connect(
      groupId: currentGroupId,
      token: widget.token,
      onMessageReceived: _onSocketMessage,
    );

    fetchMessages(currentGroupId);
  }

  @override
  void dispose() {
    chatSocket.disconnect();
    super.dispose();
  }

  /// ================= GROUP SWITCH =================
  Future<void> _onGroupChange(String newGroupId) async {
    print("🔄 GROUP SWITCHED → $newGroupId");

    chatSocket.disconnect();

    chatSocket.connect(
      groupId: newGroupId,
      token: widget.token,
      onMessageReceived: _onSocketMessage,
    );

    await fetchMessages(newGroupId);
  }

  /// ================= SEND =================
  void sendMessage() {
    if (_isGroupLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("This group is locked")));
      return;
    }

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    chatSocket.sendMessage(groupId: currentGroupId, text: text);

    messageController.clear();
  }

  /// ================= MESSAGE UI =================
  Widget _buildMessage(Map<String, dynamic> msg) {
    bool isMe = msg["senderId"] == UserSession.userId;

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
              Text(
                msg["senderName"],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            Text(
              msg["message"],
              style: const TextStyle(color: AppColors.textPrimary),
            ),
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

    return Container(
      height: 50,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          /// MAIN GROUP
          GestureDetector(
            onTap: () async {
              setState(() {
                activeSubGroup = null;
                activeSubGroupId = null;
                messages.clear();
              });

              await _onGroupChange(currentGroupId);
            },
            child: _chip("All", activeSubGroupId == null),
          ),

          ...subGroups.map((g) {
            final isSelected = activeSubGroupId == g["uuid"];

            return GestureDetector(
              onTap: () async {
                setState(() {
                  activeSubGroupId = g["uuid"];
                  activeSubGroup = g;
                  messages.clear();
                });

                await _onGroupChange(currentGroupId);
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
        color: selected ? AppColors.primary : AppColors.background,
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
          ),
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
      ),
      body: Column(
        children: [
          _subGroupBar(),
          Expanded(child: _chatArea()),
          if (isActive) _messageInput(),
        ],
      ),
    );
  }
}
