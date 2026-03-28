import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/features/profile/presentation/screens/public_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  String _ctx(String action, [Map<String, Object?> fields = const {}]) {
    final suffix = fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return suffix.isEmpty
        ? '[FRIEND_SCREEN] action=$action'
        : '[FRIEND_SCREEN] action=$action $suffix';
  }

  List friends = [];
  List pendingRequests = [];
  List suggested = [];

  String query = "";
  bool isLoading = true;
  String? myUuid;
  StompClient? stompClient;

  @override
  void initState() {
    super.initState();
    _loadAllData().then((_) => _connectWebSocket());
  }

  void _connectWebSocket() async {
    if (myUuid == null) {
      await Logger.warn(_ctx('socket_skip', {'reason': 'missing_user'}));
      return;
    }

    final token = await AuthService.getToken();
    final socketUrl = AppConstants.baseUrl
        .replaceAll('http://', 'ws://')
        .replaceAll('https://', 'wss://')
        .replaceAll('/api/v1', '/ws-friends');

    stompClient = StompClient(
      config: StompConfig(
        url: socketUrl,
        webSocketConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onConnect: (StompFrame frame) {
          Logger.info(_ctx('socket_connected', {'userId': myUuid}));
          stompClient?.subscribe(
            destination: '/topic/friends/$myUuid',
            callback: (StompFrame frame) {
              Logger.info(_ctx('socket_refresh', {'userId': myUuid}));
              _loadAllData();
            },
          );
        },
        onWebSocketError: (dynamic error) {
          Logger.error(_ctx('socket_error', {'userId': myUuid}), error);
        },
        onStompError: (StompFrame frame) {
          Logger.warn(
            _ctx('socket_protocol_error', {
              'userId': myUuid,
              'body': frame.body,
            }),
          );
        },
        onDisconnect: (StompFrame frame) {
          Logger.info(_ctx('socket_disconnected', {'userId': myUuid}));
        },
      ),
    );
    stompClient?.activate();
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Logger.info(_ctx('load_data_start'));
    setState(() => isLoading = true);

    final me = await UserService.getMe();
    if (me != null && me['id'] != null) {
      myUuid = me['id'];
      await Logger.info(_ctx('load_data_identity', {'userId': myUuid}));

      final results = await Future.wait([
        FriendService.getFriends(myUuid!),
        FriendService.getPendingRequests(),
        FriendService.getRecommendations(myUuid!),
      ]);

      if (mounted) {
        setState(() {
          friends = results[0];
          pendingRequests = results[1];
          suggested = results[2];
          isLoading = false;
        });
      }
      await Logger.info(
        _ctx('load_data_success', {
          'friends': friends.length,
          'pending': pendingRequests.length,
          'suggested': suggested.length,
        }),
      );
    } else {
      await Logger.warn(_ctx('load_data_failed', {'reason': 'missing_user'}));
      setState(() => isLoading = false);
    }
  }

  void _acceptRequest(int requestId) async {
    await Logger.info(_ctx('tap_accept_request', {'requestId': requestId}));
    final success = await FriendService.acceptRequest(requestId);
    if (success) {
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    }
  }

  void _rejectRequest(int requestId) async {
    await Logger.info(_ctx('tap_reject_request', {'requestId': requestId}));
    final success = await FriendService.rejectRequest(requestId);
    if (success) {
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request rejected')),
        );
      }
    }
  }

  void _sendRequest(String receiverUuid) async {
    await Logger.info(_ctx('tap_send_request', {'target': receiverUuid}));
    final success = await FriendService.sendRequest(receiverUuid);
    if (success) {
      if (mounted) {
        setState(() {
          suggested = suggested.map((user) {
            if (user['uuid'] == receiverUuid) {
              return {...Map<String, dynamic>.from(user), 'requestSent': true};
            }
            return user;
          }).toList();
        });
      }
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request or already exists'),
          ),
        );
      }
    }
  }

  List get filteredFriends {
    if (query.isEmpty) return friends;
    final normalizedQuery = query.toLowerCase();
    return friends
        .where(
          (f) =>
              (f["firstName"] ?? "").toLowerCase().contains(normalizedQuery) ||
              (f["lastName"] ?? "").toLowerCase().contains(normalizedQuery) ||
              (f["riderId"] ?? "").toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  List get filteredSuggested {
    if (query.isEmpty) return suggested;
    final normalizedQuery = query.toLowerCase();
    return suggested
        .where(
          (f) =>
              (f["firstName"] ?? "").toLowerCase().contains(normalizedQuery) ||
              (f["lastName"] ?? "").toLowerCase().contains(normalizedQuery) ||
              (f["riderId"] ?? "").toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  void _openPublicProfile(Map user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PublicProfileScreen(user: Map<String, dynamic>.from(user)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xff0f1114),
        appBar: AppBar(
          backgroundColor: const Color(0xff1a1c20),
          title: const Text("Friends"),
          bottom: TabBar(
            indicatorColor: const Color(0xfffe6603),
            labelColor: const Color(0xfffe6603),
            unselectedLabelColor: Colors.white54,
            tabs: [
              const Tab(text: "My Friends"),
              Tab(
                text: pendingRequests.isNotEmpty
                    ? "Requests (${pendingRequests.length})"
                    : "Requests",
              ),
              const Tab(text: "Discover"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xfffe6603)),
              )
            : TabBarView(
                children: [
                  _buildFriendsTab(),
                  _buildRequestsTab(),
                  _buildDiscoverTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filteredFriends.isEmpty
              ? const Center(
                  child: Text(
                    "No friends found",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredFriends.length,
                  itemBuilder: (ctx, i) =>
                      _userCard(filteredFriends[i], type: UserCardType.friend),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    if (pendingRequests.isEmpty) {
      return const Center(
        child: Text(
          "No pending requests",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pendingRequests.length,
      itemBuilder: (ctx, i) => _requestCard(pendingRequests[i]),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filteredSuggested.isEmpty
              ? const Center(
                  child: Text(
                    "No recommendations found",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredSuggested.length,
                  itemBuilder: (ctx, i) => _userCard(
                    filteredSuggested[i],
                    type: UserCardType.suggested,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => setState(() => query = val),
        decoration: const InputDecoration(
          hintText: "Search riders...",
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.white38),
        ),
      ),
    );
  }

  Widget _userCard(Map user, {required UserCardType type}) {
    String name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final riderId = (user['riderId'] ?? '').toString();
    if (name.isEmpty) name = "Unknown Rider";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xfffe6603),
            backgroundImage: user['profileImage'] != null
                ? NetworkImage(user['profileImage'])
                : null,
            child: user['profileImage'] == null
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (riderId.isNotEmpty)
                  Text(
                    "@$riderId",
                    style: const TextStyle(
                      color: Color(0xfffe6603),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (user['mutualFriends'] != null &&
                    (user['mutualFriends'] as int) > 0)
                  Text(
                    "${user['mutualFriends']} Mutual Friends",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  )
                else if (user['city'] != null)
                  Text(
                    user['city'],
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (type == UserCardType.suggested)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _openPublicProfile(user),
                  child: const Text(
                    "Profile",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.grey,
                    backgroundColor: user['requestSent'] == true
                        ? Colors.grey
                        : const Color(0xfffe6603),
                  ),
                  onPressed: user['requestSent'] == true
                      ? null
                      : () => _sendRequest(user['uuid']),
                  child: Text(
                    user['requestSent'] == true ? "Sent" : "Add",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: () => _openPublicProfile(user),
              child: const Text(
                "View Profile",
                style: TextStyle(color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _requestCard(Map req) {
    String name =
        "${req['senderFirstName'] ?? ''} ${req['senderLastName'] ?? ''}".trim();
    final riderId = (req['senderRiderId'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff1a1c20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xfffe6603),
            backgroundImage: req['senderProfileImage'] != null
                ? NetworkImage(req['senderProfileImage'])
                : null,
            child: req['senderProfileImage'] == null
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (riderId.isNotEmpty)
                  Text(
                    "@$riderId",
                    style: const TextStyle(
                      color: Color(0xfffe6603),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (req['mutualCount'] != null && req['mutualCount'] > 0)
                  Text(
                    "${req['mutualCount']} Mutual Friends",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openPublicProfile({
              'uuid': req['senderUuid'],
              'riderId': req['senderRiderId'],
              'firstName': req['senderFirstName'],
              'lastName': req['senderLastName'],
              'profileImage': req['senderProfileImage'],
            }),
            child: const Text(
              "Profile",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _acceptRequest(req['requestId']),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => _rejectRequest(req['requestId']),
          ),
        ],
      ),
    );
  }
}

enum UserCardType { friend, suggested }
