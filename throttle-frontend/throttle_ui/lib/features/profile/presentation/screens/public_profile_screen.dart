import 'package:flutter/material.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
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
  String relationshipStatus = 'unknown';
  int? incomingRequestId;

  @override
  void initState() {
    super.initState();
    _fetchMutualCount();
    _fetchFriendCount();
    _fetchRelationshipStatus();
  }

  Future<void> _fetchFriendCount() async {
    if (widget.user['uuid'] == null) return;
    await Logger.info(
      _ctx('fetch_friend_count', {'target': widget.user['uuid']}),
    );
    final friends = await FriendService.getFriends(widget.user['uuid']);
    if (mounted) setState(() => friendCount = friends.length);
  }

  void _fetchMutualCount() async {
    if (widget.user['uuid'] == null) {
      setState(() => isLoadingMutual = false);
      return;
    }
    await Logger.info(
      _ctx('fetch_mutual_count', {'target': widget.user['uuid']}),
    );
    final count = await FriendService.getMutualFriendsCount(
      widget.user['uuid'],
    );
    if (mounted) {
      setState(() {
        mutualCount = count;
        isLoadingMutual = false;
      });
    }
  }

  Future<void> _fetchRelationshipStatus() async {
    if (widget.user['uuid'] == null) {
      if (mounted) {
        setState(() {
          relationshipStatus = 'unknown';
          isActionLoading = false;
        });
      }
      return;
    }

    await Logger.info(
      _ctx('fetch_relationship', {'target': widget.user['uuid']}),
    );
    final data = await FriendService.getRelationshipStatus(widget.user['uuid']);
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
    await Logger.info(_ctx('tap_add_friend', {'target': widget.user['uuid']}));
    setState(() => isActionLoading = true);
    final success = await FriendService.sendRequest(widget.user['uuid']);
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
        'target': widget.user['uuid'],
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
    await Logger.info(_ctx('tap_unfriend', {'target': widget.user['uuid']}));
    setState(() => isActionLoading = true);
    final success = await FriendService.unfriend(widget.user['uuid']);
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
    if (isActionLoading) {
      return const SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xfffe6603),
        ),
      );
    }

    switch (relationshipStatus) {
      case 'friends':
        return ElevatedButton(
          onPressed: _unfriend,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Unfriend'),
        );
      case 'request_sent':
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey,
            disabledForegroundColor: Colors.white,
          ),
          child: const Text('Request Sent'),
        );
      case 'request_received':
        return ElevatedButton(
          onPressed: _acceptFriendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xfffe6603),
            foregroundColor: Colors.white,
          ),
          child: const Text('Accept Request'),
        );
      case 'self':
        return const SizedBox.shrink();
      case 'none':
      default:
        return ElevatedButton(
          onPressed: _sendFriendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xfffe6603),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Friend'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        "${widget.user["firstName"] ?? ""} ${widget.user["lastName"] ?? ""}"
            .trim();

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      appBar: AppBar(
        backgroundColor: const Color(0xff1a1c20),
        title: const Text("Rider Profile"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1a1c20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xfffe6603),
                  child: Text(
                    name.isNotEmpty ? name[0] : "R",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user["bio"] ?? "Motorcycle enthusiast",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 13,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$friendCount Friends",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (!isLoadingMutual && mutualCount > 0) ...[
                            const SizedBox(width: 10),
                            const Text(
                              "·",
                              style: TextStyle(color: Colors.white38),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "$mutualCount Mutual",
                              style: const TextStyle(
                                color: Color(0xfffe6603),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xfffe6603),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildRelationshipButton(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat("Miles", "${widget.user["totalMiles"] ?? 0}"),
              const SizedBox(width: 8),
              _stat("Rides", "${widget.user["totalRides"] ?? 0}"),
              const SizedBox(width: 8),
              _stat("Badges", "${widget.user["badges"] ?? 0}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xff1a1c20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
