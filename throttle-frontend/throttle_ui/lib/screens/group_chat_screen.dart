import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/create_subgroup_screen.dart';
import 'package:throttle_ui/screens/group_info_sheet.dart';
import 'package:throttle_ui/screens/invite_member_screen.dart';
import 'package:throttle_ui/screens/ride_start_screen.dart';
import 'package:throttle_ui/services/sub_groups_service.dart';

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

  /// NEW: subgroup state
  List subGroups = [];
  bool loadingSubGroups = true;

  List<Map<String, dynamic>> messages = [
    {"sender": "Mike T.", "message": "Hey everyone!", "time": "08:00 AM"},
    {
      "sender": "Alex R.",
      "message": "Morning! Ready for the ride?",
      "time": "08:05 AM",
    },
    {
      "sender": "You",
      "message": "Absolutely! Let's meet at the usual spot.",
      "time": "08:10 AM",
    },
  ];

  /// FETCH SUBGROUPS
  Future<void> fetchSubGroups() async {
    try {
      final result = await SubGroupService.fetchSubGroups(
        widget.token,
        widget.group["uuid"],
      );

      setState(() {
        subGroups = result["data"] ?? [];
        loadingSubGroups = false;
      });
    } catch (e) {
      print("Error fetching subgroups: $e");
      setState(() {
        loadingSubGroups = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSubGroups();
  }

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

    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    bool isMe = msg["sender"] == "You";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xfffe6603) : const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg["sender"],
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 2),
            Text(msg["message"], style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              msg["time"],
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _openGroupInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RideInfoScreen(rideGroup: widget.group, token: widget.token),
      ),
    );
  }

  void _openSubGroupCreation() {
    print(widget.group);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSubGroupScreen(
          rideId: widget.group["uuid"],
          token: widget.token,
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'info':
        _openGroupInfo();
        break;

      case 'invite':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InviteMemberScreen(
              groupId: widget.group["uuid"],
              token: widget.token,
            ),
          ),
        );
        break;

      case 'subgroup':
        _openSubGroupCreation();
        break;
    }
  }

  void _startRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideStartScreen(
          groupName: widget.group["name"] ?? "Ride",
          rideDate: "Sunday",
          rideTime: "9:00 AM",
          location: "Start Point",
          memberCount: widget.group["members"]?.length ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = widget.group["status"] == "active";

    // Check if current user is the captain
    bool isCaptain =
        widget.group["members"].any(
          (m) => m["role"] == "CAPTAIN" && m["id"] == "u1",
        ) // Replace u1 with current userId
        ? true
        : false;

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        centerTitle: false,
        title: Text(
          widget.group["name"],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color(0xfffe6603)),
            tooltip: "Start Ride",
            onPressed: _startRide,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: const Color(0xff1a1c20),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'info',
                child: Text(
                  "Group Info",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Text(
                  "Leave Group",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'invite',
                child: Text(
                  "Invite Riders",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'subgroup',
                child: Text(
                  "Create Subgroup",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            onSelected: _handleMenuSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          /// SUBGROUP BAR
          _subGroupBar(),

          if (!isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade800,
              child: const Text(
                "This group is archived. Messaging is disabled.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(messages[index]),
            ),
          ),

          if (isActive) _messageInput(),
        ],
      ),
    );
  }

  Widget _messageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: const Color(0xff1a1c20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xfffe6603)),
              onPressed: sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subGroupBar() {
    if (loadingSubGroups) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xfffe6603)),
        ),
      );
    }

    if (subGroups.isEmpty) {
      return const SizedBox();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xff1a1c20),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subGroups.length,
        itemBuilder: (context, index) {
          final g = subGroups[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GroupChatScreen(group: g, token: widget.token),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xff0f1114),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    g["name"],
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
