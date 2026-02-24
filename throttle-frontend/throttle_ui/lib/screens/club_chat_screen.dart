import 'package:flutter/material.dart';
import 'club_info_screen.dart';

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
    {"sender": "Mike T.", "message": "Welcome to the club!", "time": "08:00 AM"},
    {"sender": "You", "message": "Excited to ride together!", "time": "08:05 AM"},
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
            maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xfffe6603) : const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg["sender"],
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              msg["message"],
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              msg["time"],
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _openClubInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubInfoScreen(club: widget.club),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: Text(widget.club["name"]),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _openClubInfo,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessage(messages[index]),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xff1a1c20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      hintStyle:
                          TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color(0xfffe6603)),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}