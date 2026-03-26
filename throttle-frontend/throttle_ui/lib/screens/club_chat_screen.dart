import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/club_info_screen.dart';
import 'package:throttle_ui/utils/app_colors.dart';

class ClubChatScreen extends StatefulWidget {
  final Map<String, dynamic> club;

  const ClubChatScreen({super.key, required this.club});

  @override
  State<ClubChatScreen> createState() => _ClubChatScreenState();
}

class _ClubChatScreenState extends State<ClubChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [
    {
      "sender": "Mike T.",
      "message": "Welcome to the club!",
      "time": "08:00 AM",
    },
    {
      "sender": "You",
      "message": "Excited to ride together!",
      "time": "08:05 AM",
    },
  ];

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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg["sender"],
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(msg["message"], style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              msg["time"],
              style: const TextStyle(color: AppColors.textHint, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _openClubInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubInfoScreen(club: widget.club)),
    );
  }

  void _openSubClubCreation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Create Subclub",
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          "Here you can implement subclub creation UI.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'info':
        _openClubInfo();
        break;
      case 'leave':
        // Implement leave club logic here
        break;
      case 'subclub':
        _openSubClubCreation();
        break;
      case 'manage':
        // Implement manage clubs logic here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if current user is captain
    final members = widget.club["members"];
bool isCaptain = false;

// Only run .any if members is a List
if (members is List) {
  isCaptain = members.any(
    (m) => m["role"] == "CAPTAIN" && m["id"] == "u1",
  );
}

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.club["name"],
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppColors.surface,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'info',
                child: Text(
                  "Show Club Info",
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Text(
                  "Leave Club",
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              if (isCaptain)
                const PopupMenuItem(
                  value: 'subclub',
                  child: Text(
                    "Create Subclub",
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              const PopupMenuItem(
                value: 'manage',
                child: Text(
                  "Manage Clubs",
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
            onSelected: _handleMenuSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
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
          ),
        ],
      ),
    );
  }
}
