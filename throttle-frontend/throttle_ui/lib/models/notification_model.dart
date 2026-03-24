import 'package:flutter/material.dart';

class NotificationItem {
  final int id;
  final String title;
  final String desc;
  final String time;
  bool unread;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.time,
    required this.unread,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json["id"],
      title: json["title"] ?? "",
      desc: json["message"] ?? "",
      time: json["createdAt"] ?? "",
      unread: !(json["read"] ?? false),
      type: json["type"] ?? "",
    );
  }
}