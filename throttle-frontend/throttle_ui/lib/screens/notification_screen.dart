import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onClose;

  const NotificationsScreen({super.key, required this.onClose});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  late Future<List<NotificationItem>> futureNotifications;

  @override
  void initState() {
    super.initState();
    futureNotifications = NotificationService().fetchNotifications();
  }

  int _unreadCount(List<NotificationItem> notifications) {
    return notifications.where((n) => n.unread).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xffeeeeee),
                      child: Icon(Icons.close, size: 18),
                    ),
                  )
                ],
              ),
            ),

            /// BODY
            Expanded(
              child: FutureBuilder<List<NotificationItem>>(
                future: futureNotifications,
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No notifications"),
                    );
                  }

                  final notifications = snapshot.data!;
                  final unreadCount = _unreadCount(notifications);

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    children: [

                      /// NEW COUNT
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "$unreadCount new ",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const TextSpan(
                              text: "notifications",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// NOTIFICATION LIST
                      ...notifications.map((n) => _notificationCard(n)).toList(),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(NotificationItem n) {
    Color iconBg;
    Color iconColor;

    switch (n.type) {
      case "invite":
        iconBg = Colors.blue.withOpacity(.1);
        iconColor = Colors.blue;
        break;
      case "join":
        iconBg = Colors.green.withOpacity(.1);
        iconColor = Colors.green;
        break;
      case "streak":
        iconBg = Colors.orange.withOpacity(.1);
        iconColor = Colors.orange;
        break;
      case "competition":
        iconBg = Colors.blue.withOpacity(.1);
        iconColor = Colors.blue;
        break;
      default:
        iconBg = Colors.grey.withOpacity(.2);
        iconColor = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: n.unread ? Colors.blue.withOpacity(.2) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(14),
        color: n.unread ? Colors.blue.withOpacity(.05) : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ICON
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(n.icon, size: 18, color: iconColor),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (n.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      )
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  n.desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  n.time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}