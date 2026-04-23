import 'package:flutter/material.dart';
import 'package:throttle_ui/features/clubs/presentation/screens/club_chat_screen.dart';

class ClubInfoScreen extends StatelessWidget {
  final String clubUuid;

  const ClubInfoScreen({super.key, required this.clubUuid});

  @override
  Widget build(BuildContext context) {
    return ClubChatScreen(clubUuid: clubUuid, initialTabIndex: 0);
  }
}
