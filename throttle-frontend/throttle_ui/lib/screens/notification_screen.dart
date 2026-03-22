import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onClose;
  final String token;

  const NotificationsScreen({super.key, required this.onClose, required this.token});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  List<NotificationItem> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final data = await NotificationService().fetchNotifications(widget.token);

    setState(() {
      notifications = data;
      loading = false;
    });
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

  /// ================= MARK READ/UNREAD =================
  void toggleRead(NotificationItem n, bool markRead) {
    setState(() {
      n.unread = !markRead;
    });

    NotificationService().markAsRead(n.id, markRead, widget.token);
  }

  /// ================= TIME FORMAT =================
  String formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
  return Scaffold(
    body: Container(
      color: const Color.fromARGB(255, 20, 19, 19), // dark background
      child: const Center(
        child: Text(
          "No notifications",
          style: TextStyle(
            color: Colors.white, // white text
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}

    final unread = notifications.where((n) => n.unread).toList();
    final read = notifications.where((n) => !n.unread).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER WITH COUNT BADGE
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),

                  /// 🔥 COUNT BADGE
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$unreadCount",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),

                  const Spacer(),

                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  )
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  /// ================= UNREAD =================
                  if (unread.isNotEmpty) ...[
                    const Text("Unread",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...unread.map((n) => _notificationCard(n)),
                    const SizedBox(height: 20),
                  ],

                  /// ================= READ =================
                  if (read.isNotEmpty) ...[
                    const Text("Read",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...read.map((n) => _notificationCard(n)),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(NotificationItem n) {

  return Dismissible(
    key: Key(n.id.toString()),

    /// 👉 RIGHT = MARK READ
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: Colors.green,
      child: const Icon(Icons.mark_email_read, color: Colors.white),
    ),

    /// 👉 LEFT = MARK UNREAD
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.orange,
      child: const Icon(Icons.mark_email_unread, color: Colors.white),
    ),

    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd) {
        toggleRead(n, true);
      } else {
        toggleRead(n, false);
      }
      return false; // don't remove item
    },

    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // KEEP your existing unread blue color scheme
        color: n.unread ? Colors.blue.withOpacity(.05) : Colors.blue.withOpacity(.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: n.unread
              ? Colors.blue.withOpacity(.3) // original unread border
              : Colors.blue.withOpacity(.15), // subtle for read
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                n.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: n.unread ? const Color.fromARGB(255, 242, 242, 242) : const Color.fromARGB(221, 73, 73, 73),
                ),
              ),

              /// BUTTONS
              Row(
                children: [
                  TextButton(
                    onPressed: () => toggleRead(n, true),
                    child: const Text("Mark Read"),
                  ),
                  TextButton(
                    onPressed: () => toggleRead(n, false),
                    child: const Text("Unread"),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 4),

          Text(
            n.desc,
            style: TextStyle(
              color: n.unread ? const Color.fromARGB(255, 255, 255, 255) : Colors.grey[600], // subtle difference
            ),
          ),

          const SizedBox(height: 6),

          Text(
            formatTime(n.time),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
}