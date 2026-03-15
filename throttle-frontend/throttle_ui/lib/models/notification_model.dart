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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json["id"],
      type: json["type"],
      icon: Icons.notifications, // backend won't send icon
      title: json["title"],
      desc: json["desc"],
      time: json["time"],
      unread: json["unread"] ?? false,
    );
  }
}