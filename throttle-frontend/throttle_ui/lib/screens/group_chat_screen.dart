import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/group_info_sheet.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Demo messages (Old functionality preserved)
  List<Map<String, dynamic>> messages = [
    {"sender": "Mike T.", "message": "Hey everyone!", "time": "08:00 AM"},
    {"sender": "Alex R.", "message": "Morning! Ready for the ride?", "time": "08:05 AM"},
    {"sender": "You", "message": "Absolutely! Let's meet at the usual spot.", "time": "08:10 AM"},
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

    // Auto scroll to bottom
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
            Text(
              msg["message"],
              style: const TextStyle(color: Colors.white),
            ),
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
      builder: (_) => RideInfoScreen(rideGroup: widget.group),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    bool isActive = widget.group["status"] == "active";

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: Text(
          widget.group["name"],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _openGroupInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Archived Banner (kept from new version)
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

          // Chat messages (Old style)
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessage(messages[index]),
            ),
          ),

          // Input field (disabled if archived)
          if (isActive)
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
            ),
        ],
      ),
    );
  }
}