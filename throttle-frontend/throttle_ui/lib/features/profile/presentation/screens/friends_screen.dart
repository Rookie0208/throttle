import 'package:flutter/material.dart';
import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List friends = []; // your API friends
  List suggested = []; // recommended users

  String query = "";

  @override
  void initState() {
    super.initState();

    /// TODO: Replace with API calls
    loadData();
  }

  void loadData() {
    /// Dummy data
    friends = []; // try empty & non-empty

    suggested = [
      {
        "name": "Amit Rawat",
        "bio": "Loves long rides 🏍️",
      },
      {
        "name": "Sara Khan",
        "bio": "Weekend rider",
      },
    ];

    setState(() {});
  }

  List get filteredFriends {
    return friends
        .where((f) =>
            f["name"].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List get filteredSuggested {
    return suggested
        .where((f) =>
            f["name"].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool hasFriends = friends.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Friends"),
      ),
      body: Column(
        children: [

          /// ================= SEARCH =================
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (val) {
                setState(() => query = val);
              },
              decoration: const InputDecoration(
                hintText: "Search riders...",
                hintStyle: TextStyle(color: AppColors.textHint),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.textHint),
              ),
            ),
          ),

          /// ================= LIST =================
          Expanded(
            child: hasFriends
                ? _buildFriendsList()
                : _buildSuggestedList(),
          )
        ],
      ),
    );
  }

  /// ================= FRIENDS LIST =================
  Widget _buildFriendsList() {
    final data = query.isEmpty ? friends : filteredFriends;

    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No matching friends",
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Text(
          "Your Friends",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        ...data.map((f) => _userCard(f, isFriend: true)).toList(),
      ],
    );
  }

  /// ================= SUGGESTED =================
  Widget _buildSuggestedList() {
    final data = query.isEmpty ? suggested : filteredSuggested;

    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No riders found",
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Text(
          "Suggested Riders",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        ...data.map((f) => _userCard(f)).toList(),
      ],
    );
  }

  /// ================= USER CARD =================
  Widget _userCard(Map user, {bool isFriend = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          /// AVATAR
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              user["name"][0],
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),

          const SizedBox(width: 12),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user["name"],
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user["bio"] ?? "",
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          /// ACTION BUTTON
          isFriend
              ? TextButton(
                  onPressed: () {
                    // MaterialPageRoute route = MaterialPageRoute(builder: PublicProfileScreen(user: user));
                    // Navigator.push(context, route);
                  },
                  child: const Text("View", style: TextStyle(color: AppColors.textMuted)),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    await NotificationService().notifyFriendRequestSent(
                      recipientName: user["name"],
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Friend request sent to ${user["name"]}"),
                      ),
                    );
                  },
                  child: const Text("Add", style: TextStyle(color: AppColors.white)),
                ),
        ],
      ),
    );
  }
}
