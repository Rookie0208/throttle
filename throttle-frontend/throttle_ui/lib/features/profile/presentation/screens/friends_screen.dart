import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              (f["username"] ?? "").toLowerCase().contains(normalizedQuery) ||
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
              (f["username"] ?? "").toLowerCase().contains(normalizedQuery) ||
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
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          title: Text(
            "Friends",
            style: GoogleFonts.lexend(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: TabBar(
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
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
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
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filteredFriends.isEmpty
              ? Center(
                  child: Text("No friends found", style: textTheme.bodyMedium),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredFriends.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (ctx, i) =>
                      _userCard(filteredFriends[i], type: UserCardType.friend),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    final textTheme = Theme.of(context).textTheme;
    if (pendingRequests.isEmpty) {
      return Center(
        child: Text("No pending requests", style: textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pendingRequests.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 56,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
      ),
      itemBuilder: (ctx, i) => _requestCard(pendingRequests[i]),
    );
  }

  Widget _buildDiscoverTab() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filteredSuggested.isEmpty
              ? Center(
                  child: Text(
                    "No recommendations found",
                    style: textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredSuggested.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
              ),
      child: TextField(
        style: textTheme.bodyLarge,
        onChanged: (val) => setState(() => query = val),
        decoration: InputDecoration(
          hintText: "Search riders...",
          hintStyle: textTheme.bodyMedium,
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _userCard(Map user, {required UserCardType type}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    String name = (user['username'] ?? '').toString().trim();
    final riderId = (user['riderId'] ?? '').toString();
    if (name.isEmpty) name = "Unknown Rider";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            backgroundImage: user['profileImage'] != null
                ? NetworkImage(user['profileImage'])
                : null,
            child: user['profileImage'] == null
                ? Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.lexend(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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
                  style: GoogleFonts.lexend(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (riderId.isNotEmpty)
                  Text(
                    "@$riderId",
                    style: GoogleFonts.lexend(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (user['mutualFriends'] != null &&
                    (user['mutualFriends'] as int) > 0)
                  Text(
                    "${user['mutualFriends']} Mutual Friends",
                    style: textTheme.bodyMedium,
                  )
                else if (user['city'] != null)
                  Text(user['city'], style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (type == UserCardType.suggested)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _openPublicProfile(user),
                  child: Text(
                    "Profile",
                    style: GoogleFonts.lexend(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: colorScheme.outlineVariant,
                    backgroundColor: user['requestSent'] == true
                        ? colorScheme.outlineVariant
                        : colorScheme.primary,
                  ),
                  onPressed: user['requestSent'] == true
                      ? null
                      : () => _sendRequest(user['uuid']),
                  child: Text(
                    user['requestSent'] == true ? "Sent" : "Add",
                    style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: () => _openPublicProfile(user),
              child: Text(
                "View Profile",
                style: GoogleFonts.lexend(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _requestCard(Map req) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    String name = (req['senderUsername'] ?? '').toString().trim();
    if (name.isEmpty) name = "Unknown Rider";
    final riderId = (req['senderRiderId'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            backgroundImage: req['senderProfileImage'] != null
                ? NetworkImage(req['senderProfileImage'])
                : null,
            child: req['senderProfileImage'] == null
                ? Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.lexend(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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
                  style: GoogleFonts.lexend(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (riderId.isNotEmpty)
                  Text(
                    "@$riderId",
                    style: GoogleFonts.lexend(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (req['mutualCount'] != null && req['mutualCount'] > 0)
                  Text(
                    "${req['mutualCount']} Mutual Friends",
                    style: textTheme.bodyMedium,
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
            child: Text(
              "Profile",
              style: GoogleFonts.lexend(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.check_circle_rounded, color: colorScheme.primary),
            onPressed: () => _acceptRequest(req['requestId']),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
            onPressed: () => _rejectRequest(req['requestId']),
          ),
        ],
      ),
    );
  }
}

enum UserCardType { friend, suggested }
