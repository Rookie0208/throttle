import 'package:flutter/material.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const PublicProfileScreen({super.key, required this.user});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  String _ctx(String action, [Map<String, Object?> fields = const {}]) {
    final suffix = fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return suffix.isEmpty
        ? '[PUBLIC_PROFILE] action=$action'
        : '[PUBLIC_PROFILE] action=$action $suffix';
  }

  int mutualCount = 0;
  int friendCount = 0;
  bool isLoadingMutual = true;
  bool isActionLoading = true;
  bool isLoadingProfile = false;
  String relationshipStatus = 'unknown';
  int? incomingRequestId;
  late Map<String, dynamic> _profile;

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.user);
    _fetchProfile();
    _fetchMutualCount();
    _fetchFriendCount();
    _fetchRelationshipStatus();
  }

  String? get _targetUuid =>
      (_profile['uuid'] ?? widget.user['uuid']) as String?;

  Map<String, dynamic> get _displayUser => _profile;

  Future<void> _fetchProfile() async {
    final uuid = _targetUuid;
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    setState(() => isLoadingProfile = true);
    final profile = await UserService.getProfileByUuid(uuid);
    if (mounted) {
      setState(() {
        if (profile != null) {
          _profile = {..._profile, ...profile, 'uuid': uuid};
        }
        isLoadingProfile = false;
      });
    }
  }

  Future<void> _fetchFriendCount() async {
    final uuid = _targetUuid;
    if (uuid == null) return;
    await Logger.info(_ctx('fetch_friend_count', {'target': uuid}));
    final friends = await FriendService.getFriends(uuid);
    if (mounted) setState(() => friendCount = friends.length);
  }

  void _fetchMutualCount() async {
    final uuid = _targetUuid;
    if (uuid == null) {
      setState(() => isLoadingMutual = false);
      return;
    }
    await Logger.info(_ctx('fetch_mutual_count', {'target': uuid}));
    final count = await FriendService.getMutualFriendsCount(uuid);
    if (mounted) {
      setState(() {
        mutualCount = count;
        isLoadingMutual = false;
      });
    }
  }

  Future<void> _fetchRelationshipStatus() async {
    final uuid = _targetUuid;
    if (uuid == null) {
      if (mounted) {
        setState(() {
          relationshipStatus = 'unknown';
          isActionLoading = false;
        });
      }
      return;
    }

    await Logger.info(_ctx('fetch_relationship', {'target': uuid}));
    final data = await FriendService.getRelationshipStatus(uuid);
    if (mounted) {
      setState(() {
        relationshipStatus = (data['status'] ?? 'unknown').toString();
        incomingRequestId = data['requestId'] is int
            ? data['requestId'] as int
            : null;
        isActionLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    await Logger.info(_ctx('tap_add_friend', {'target': _targetUuid}));
    setState(() => isActionLoading = true);
    final success = await FriendService.sendRequest(_targetUuid!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Friend request sent' : 'Unable to send friend request',
        ),
      ),
    );

    await _fetchRelationshipStatus();
  }

  Future<void> _acceptFriendRequest() async {
    if (incomingRequestId == null) return;
    await Logger.info(
      _ctx('tap_accept_request', {
        'target': _targetUuid,
        'requestId': incomingRequestId,
      }),
    );
    setState(() => isActionLoading = true);
    final success = await FriendService.acceptRequest(incomingRequestId!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Friend request accepted' : 'Unable to accept request',
        ),
      ),
    );

    if (success) {
      await _fetchFriendCount();
    }
    await _fetchRelationshipStatus();
  }

  Future<void> _unfriend() async {
    await Logger.info(_ctx('tap_unfriend', {'target': _targetUuid}));
    setState(() => isActionLoading = true);
    final success = await FriendService.unfriend(_targetUuid!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Friend removed' : 'Unable to unfriend right now',
        ),
      ),
    );

    if (success) {
      setState(() {
        friendCount = friendCount > 0 ? friendCount - 1 : 0;
      });
    }
    await _fetchRelationshipStatus();
  }

  Widget _buildRelationshipButton() {
    final colorScheme = Theme.of(context).colorScheme;
    if (isActionLoading) {
      return SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    }

    switch (relationshipStatus) {
      case 'friends':
        return ElevatedButton(
          onPressed: _unfriend,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Unfriend'),
        );
      case 'request_sent':
        return const ElevatedButton(
          onPressed: null,
          child: Text('Request Sent'),
        );
      case 'request_received':
        return ElevatedButton(
          onPressed: _acceptFriendRequest,
          child: const Text('Accept Request'),
        );
      case 'self':
        return const SizedBox.shrink();
      case 'none':
      default:
        return ElevatedButton(
          onPressed: _sendFriendRequest,
          child: const Text('Add Friend'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = _displayUser;
    final String name = (user["username"] ?? "").toString().trim();
    final String riderId = (user["riderId"] ?? "").toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Rider Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    name.isNotEmpty ? name[0] : "R",
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (riderId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "@$riderId",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        user["bio"] ?? "Motorcycle enthusiast",
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 13,
                            color: textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$friendCount Friends",
                            style: textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                          if (!isLoadingMutual && mutualCount > 0) ...[
                            const SizedBox(width: 10),
                            Text("·", style: textTheme.bodySmall),
                            const SizedBox(width: 10),
                            Text(
                              "$mutualCount Mutual",
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isLoadingMutual)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: SizedBox(
                            height: 10,
                            width: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildRelationshipButton(),
                    if (isLoadingProfile)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          "Loading profile...",
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat("Miles", "${user["totalMiles"] ?? 0}"),
              const SizedBox(width: 8),
              _stat("Rides", "${user["totalRides"] ?? 0}"),
              const SizedBox(width: 8),
              _stat(
                "Badges",
                "${(user["achievements"] is List ? (user["achievements"] as List).length : null) ?? user["badges"] ?? 0}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
