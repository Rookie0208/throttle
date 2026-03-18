import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/create_subgroup_screen.dart';
import 'package:throttle_ui/screens/group_info_sheet.dart';
import 'package:throttle_ui/screens/invite_member_screen.dart';
import 'package:throttle_ui/screens/ride_start_screen.dart';
import 'package:throttle_ui/services/sub_groups_service.dart';

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

  String currentUserRole = "MEMBER"; // TODO: replace from backend

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
          color: isMe ? const Color(0xfffe6603) : const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg["sender"],
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(msg["message"],
                style: const TextStyle(color: Colors.white)),
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
    List visibleGroups = subGroups.where((g) {
      if (g["visibility"] == "PUBLIC") return true;

      if (g["visibility"] == "ADMINS_ONLY") {
        return currentUserRole == "ADMIN" ||
            currentUserRole == "CAPTAIN";
      }

      return true;
    }).toList();

    return Container(
      height: 50,
      color: const Color(0xff1a1c20),
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

          ...visibleGroups.map((g) {
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
            ? const Color(0xfffe6603)
            : const Color(0xff0f1114),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
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
          style: TextStyle(color: Colors.white70),
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
      color: const Color(0xff1a1c20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Type message...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xfffe6603)),
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
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: Text(
          activeSubGroup != null
              ? "${widget.group["name"]} • ${activeSubGroup!["name"]}"
              : widget.group["name"],
        ),
      ),
      body: Column(
        children: [
          _subGroupBar(),

          if (!isActive)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Messaging disabled",
                style: TextStyle(color: Colors.white70),
              ),
            ),

          Expanded(child: _chatArea()),

          if (isActive) _messageInput(),
        ],
      ),
    );
  }
}