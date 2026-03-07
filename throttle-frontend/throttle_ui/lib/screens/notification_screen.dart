import 'package:flutter/material.dart';

class NotificationItem {
  final int id;
  final String type;
  final IconData icon;
  final String title;
  final String desc;
  final String time;
  final bool unread;

  NotificationItem({
    required this.id,
    required this.type,
    required this.icon,
    required this.title,
    required this.desc,
    required this.time,
    required this.unread,
  });
}

class NotificationsScreen extends StatelessWidget {
  final VoidCallback onClose;

  NotificationsScreen({super.key, required this.onClose});

  final List<NotificationItem> notifications = [
    NotificationItem(
      id: 1,
      type: "invite",
      icon: Icons.location_on,
      title: "Ride Invitation",
      desc: "Mike T. invited you to Sunday Mountain Run",
      time: "5m ago",
      unread: true,
    ),
    NotificationItem(
      id: 2,
      type: "join",
      icon: Icons.person_add,
      title: "Join Request",
      desc: "Chris M. wants to join Weekend Warriors",
      time: "20m ago",
      unread: true,
    ),
    NotificationItem(
      id: 3,
      type: "streak",
      icon: Icons.local_fire_department,
      title: "Streak Reminder",
      desc: "Don't break your 12-day streak! Go for a ride today.",
      time: "1h ago",
      unread: true,
    ),
    NotificationItem(
      id: 4,
      type: "competition",
      icon: Icons.emoji_events,
      title: "Competition Update",
      desc: "You moved to #3 in the February Miles Challenge!",
      time: "3h ago",
      unread: false,
    ),
    NotificationItem(
      id: 5,
      type: "complete",
      icon: Icons.check_circle,
      title: "Ride Complete",
      desc: "Great ride! You covered 68 miles in 2h 15m on Canyon Loop.",
      time: "Yesterday",
      unread: false,
    ),
    NotificationItem(
      id: 6,
      type: "invite",
      icon: Icons.group,
      title: "Group Invite",
      desc: "Sarah K. invited you to join Canyon Cruisers",
      time: "Yesterday",
      unread: false,
    ),
  ];

  int get unreadCount =>
      notifications.where((n) => n.unread).length;

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
                    onTap: onClose,
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
              child: ListView(
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