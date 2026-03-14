import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/club_chat_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  int _viewIndex = 0; // 0 = list, 1 = detail
  Map<String, dynamic>? selectedClub;
  String selectedTab = "members";

  final publicClubs = [
    {"name": "Iron Riders", "members": 48, "rides": 12, "avatar": "IR"},
    {"name": "Canyon Cruisers", "members": 32, "rides": 8, "avatar": "CC"},
    {"name": "Night Owls MC", "members": 21, "rides": 15, "avatar": "NO"},
  ];

  final privateClubs = [
    {"name": "Weekend Warriors", "members": 12, "rides": 6, "avatar": "WW"},
    {"name": "Sportbike Squad", "members": 8, "rides": 4, "avatar": "SS"},
  ];

  @override
  Widget build(BuildContext context) {
    if (_viewIndex == 1 && selectedClub != null) {
      return _buildDetailView();
    }
    return _buildListView();
  }

  /// ================= LIST VIEW =================

  Widget _buildListView() {
    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Clubs Community",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xfffe6603),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),

            /// Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xff1a1c20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white54),
                    SizedBox(width: 8),
                    Text(
                      "Search clubs...",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Public Clubs
            _sectionTitle("Public Clubs"),
            ...publicClubs.map((club) => _clubTile(club, isPrivate: false)),

            const SizedBox(height: 24),

            /// Private Clubs
            _sectionTitle("Private Clubs"),
            ...privateClubs.map((club) => _clubTile(club, isPrivate: true)),

            const SizedBox(height: 24),

            /// Top Clubs
            _sectionTitle("Top Clubs This Month"),
            ...[
              {"name": "Iron Riders", "miles": "12,400 mi", "rank": 1},
              {"name": "Canyon Cruisers", "miles": "9,800 mi", "rank": 2},
              {"name": "Night Owls MC", "miles": "8,200 mi", "rank": 3},
            ].map((club) => _topClubTile(club)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xfffe6603),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _clubTile(Map<String, dynamic> club, {required bool isPrivate}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClubChatScreen(club: club)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPrivate
                    ? Colors.grey.shade800
                    : const Color(0xfffe6603).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                club["avatar"],
                style: const TextStyle(
                  color: Color(0xfffe6603),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club["name"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${club["members"]} members • ${club["rides"]} rides/mo",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isPrivate)
              const Icon(Icons.lock, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _topClubTile(Map<String, dynamic> club) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: club["rank"] == 1
                ? const Color(0xfffe6603)
                : Colors.grey.shade800,
            child: Text(
              club["rank"].toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              club["name"],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            club["miles"],
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= DETAIL VIEW =================

  Widget _buildDetailView() {
    final members = ["Mike T.", "Sarah K.", "Jordan P.", "Alex R.", "Chris M."];

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _viewIndex = 0;
              selectedClub = null;
            });
          },
        ),
        title: Text(selectedClub!["name"]),
      ),
      body: Column(
        children: [
          /// Tabs
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ["members", "rides", "leaderboard"]
                  .map(
                    (tab) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = tab;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedTab == tab
                                ? const Color(0xfffe6603)
                                : const Color(0xff1a1c20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tab.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final isCaptain = index == 0;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1c20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      if (isCaptain)
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xfffe6603),
                          size: 18,
                        ),
                      if (isCaptain) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          members[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (isCaptain)
                        const Text(
                          "Captain",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
