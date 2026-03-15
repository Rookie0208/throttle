import 'package:flutter/material.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final friends = [
    {"id": "1", "name": "John Rider"},
    {"id": "2", "name": "Sarah Blaze"},
    {"id": "3", "name": "Mike Torque"},
  ];

  List<String> selected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Friends")),
      body: ListView(
        children: friends.map((friend) {
          return CheckboxListTile(
            title: Text(friend["name"]!),
            value: selected.contains(friend["id"]),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selected.add(friend["id"]!);
                } else {
                  selected.remove(friend["id"]);
                }
              });
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context, selected),
        child: const Icon(Icons.check),
      ),
    );
  }
}
