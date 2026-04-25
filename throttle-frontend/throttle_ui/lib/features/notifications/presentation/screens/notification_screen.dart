import 'package:flutter/material.dart';
import 'package:throttle_ui/features/notifications/data/models/notification_model.dart';
import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
import 'package:throttle_ui/features/profile/presentation/screens/public_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onClose;
  final String token;
  final List<NotificationItem>? initialNotifications;

  const NotificationsScreen({
    super.key,
    required this.onClose,
    required this.token,
    this.initialNotifications,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<NotificationItem> notifications = [];
  bool loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialNotifications != null) {
      notifications = _recentNotifications(widget.initialNotifications!);
      loading = false;
    } else {
      loadNotifications();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    final data = await NotificationService().fetchNotifications(widget.token);

    setState(() {
      notifications = _recentNotifications(data);
      loading = false;
    });
  }

  List<NotificationItem> _recentNotifications(List<NotificationItem> items) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));

    return items.where((item) {
      final date = DateTime.tryParse(item.time)?.toLocal();
      return date != null && !date.isBefore(cutoff);
    }).toList()..sort((a, b) => b.time.compareTo(a.time));
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

  void _removeNotification(NotificationItem notification) {
    setState(() {
      notifications.removeWhere((item) => item.id == notification.id);
    });
  }

  String _extractFriendNameFromMessage(NotificationItem notification) {
    final message = notification.desc.trim();
    const suffix = " sent you a friend request.";
    if (message.endsWith(suffix)) {
      return message.substring(0, message.length - suffix.length).trim();
    }
    return message.isNotEmpty ? message : "A friend";
  }

  bool _matchesSenderName(Map<String, dynamic> request, String expectedName) {
    final fullName = (request['senderUsername'] ?? "").toString().trim().toLowerCase();
    return fullName.isNotEmpty && fullName == expectedName.trim().toLowerCase();
  }

  void toggleRead(NotificationItem n, bool markRead) {
    setState(() {
      n.unread = !markRead;
    });

    NotificationService().markAsRead(n.id, markRead, widget.token);
  }

  String formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String formatDateTime(String isoTime) {
    final dt = DateTime.parse(isoTime).toLocal();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final suffix = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month}/${dt.year} • $hour:$minute $suffix";
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    if (notification.referenceId == null) {
      return;
    }

    try {
      if (_isRideInviteNotification(notification.type)) {
        await _handleRideInviteNotification(notification);
      } else if (notification.type == "FRIEND_REQUEST") {
        await _handleFriendRequestNotification(notification);
      } else if (notification.type == "SUBGROUP_JOIN_REQUEST") {
        await _handleSubgroupJoinRequestNotification(notification);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  bool _isRideInviteNotification(String type) {
    return type == "RIDE_INVITE" || type == "RIDE_GROUP_INVITE";
  }

  Future<void> _handleRideInviteNotification(
    NotificationItem notification,
  ) async {
    final invitation = await RideService.fetchInvitationDetails(
      widget.token,
      notification.referenceId!,
    );
    if (!mounted) return;

    if (notification.unread) {
      toggleRead(notification, true);
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _invitationSheet(sheetContext, invitation),
    );

    if (action == null) return;

    if (action == "accept") {
      await RideService.acceptInvitation(
        widget.token,
        notification.referenceId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ride invitation accepted")));
    } else if (action == "reject") {
      await RideService.rejectInvitation(
        widget.token,
        notification.referenceId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ride invitation rejected")));
    }

    await loadNotifications();
  }

  Future<void> _handleFriendRequestNotification(
    NotificationItem notification,
  ) async {
    final fallbackSenderName = _extractFriendNameFromMessage(notification);

    if (notification.unread) {
      toggleRead(notification, true);
    }

    // Fetch pending requests to get actual sender details
    try {
      final pendingRequests = await FriendService.getPendingRequests();
      if (!mounted) return;

      Map<String, dynamic>? matchingRequest;
      for (final request in pendingRequests) {
        if (request is! Map<String, dynamic>) continue;
        final reqId = request['requestId'];
        final parsedRequestId = reqId is int
            ? reqId
            : int.tryParse(reqId.toString());
        if ((notification.referenceId != null &&
                parsedRequestId == notification.referenceId) ||
            _matchesSenderName(request, fallbackSenderName)) {
          matchingRequest = request;
          break;
        }
      }

      if (matchingRequest == null) {
        await _showFriendRequestBottomSheet(
          notification: notification,
          requestId: notification.referenceId,
          senderName: fallbackSenderName,
          senderUuid: null,
          senderProfileImage: null,
          mutualCount: 0,
          isPending: false,
        );
        return;
      }

      final senderName = (matchingRequest['senderUsername'] ?? "").toString().trim();
      final dynamic mutualValue = matchingRequest['mutualCount'];
      final mutualCount = mutualValue is int
          ? mutualValue
          : int.tryParse(mutualValue?.toString() ?? '') ?? 0;
      final dynamic resolvedRequestIdValue = matchingRequest['requestId'];
      final resolvedRequestId = resolvedRequestIdValue is int
          ? resolvedRequestIdValue
          : int.tryParse(resolvedRequestIdValue?.toString() ?? '');

      await _showFriendRequestBottomSheet(
        notification: notification,
        requestId: resolvedRequestId,
        senderName: senderName.isEmpty ? fallbackSenderName : senderName,
        senderUuid: matchingRequest['senderUuid'],
        senderProfileImage: matchingRequest['senderProfileImage'],
        mutualCount: mutualCount,
        isPending: true,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error loading friend request: ${e.toString().replaceFirst("Exception: ", "")}",
          ),
        ),
      );
    }
  }

  Future<void> _showFriendRequestBottomSheet({
    required NotificationItem notification,
    required int? requestId,
    required String senderName,
    String? senderUuid,
    String? senderProfileImage,
    required int mutualCount,
    required bool isPending,
  }) async {
    final requestData = {
      "requestId": requestId,
      "senderName": senderName,
      "senderUuid": senderUuid,
      "senderProfileImage": senderProfileImage,
      "mutualCount": mutualCount,
      "isPending": isPending,
    };

    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _friendRequestSheet(sheetContext, requestData),
    );

    if (action == null) {
      return;
    }

    if (action == "accept") {
      if (requestId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This friend request could not be resolved."),
          ),
        );
        return;
      }
      try {
        await FriendService.acceptRequest(requestId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Friend request accepted")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    } else if (action == "reject") {
      if (requestId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This friend request could not be resolved."),
          ),
        );
        return;
      }
      try {
        await FriendService.rejectRequest(requestId);
        await NotificationService().deleteNotification(
          notification.id,
          widget.token,
        );
        _removeNotification(notification);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Friend request rejected")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    } else if (action == "view_profile") {
      if (senderUuid != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              user: {
                "uuid": senderUuid,
                "username": senderName,
                "profileImage": senderProfileImage,
              },
            ),
          ),
        );
        return;
      }
    }

    await loadNotifications();
  }

  Future<void> _handleSubgroupJoinRequestNotification(
    NotificationItem notification,
  ) async {
    final requestId = notification.referenceId;
    if (requestId == null) return;

    Map<String, dynamic> details;
    try {
      details = await SubGroupService.fetchJoinRequestDetails(
        widget.token,
        requestId,
      );
    } catch (_) {
      details = {
        "requestId": requestId,
        "groupName": notification.title.isNotEmpty
            ? notification.title
            : "subgroup",
      };
    }

    if (!mounted) return;
    if (notification.unread) {
      toggleRead(notification, true);
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) =>
          _subgroupJoinRequestSheet(sheetContext, details),
    );

    if (action == null) return;

    if (action == "accept") {
      await SubGroupService.approveJoinRequestById(widget.token, requestId);
      await NotificationService().deleteNotification(
        notification.id,
        widget.token,
      );
      _removeNotification(notification);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Join request approved")));
    } else if (action == "reject") {
      await SubGroupService.rejectJoinRequestById(widget.token, requestId);
      await NotificationService().deleteNotification(
        notification.id,
        widget.token,
      );
      _removeNotification(notification);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Join request rejected")));
    } else if (action == "view_profile") {
      final userUuid = details["userUuid"]?.toString();
      if (userUuid != null && userUuid.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              user: {
                "uuid": userUuid,
                "username": details["username"],
                "profileImage": details["profileImage"],
              },
            ),
          ),
        );
        return;
      }
    }

    await loadNotifications();
  }

  Widget _subgroupJoinRequestSheet(
    BuildContext sheetContext,
    Map<String, dynamic> details,
  ) {
    final colorScheme = Theme.of(sheetContext).colorScheme;
    final textTheme = Theme.of(sheetContext).textTheme;
    final requesterName = (details["username"] ?? "").toString().trim().isEmpty
        ? "Rider"
        : (details["username"] ?? "").toString().trim();
    final subgroupName = (details["groupName"] ?? "subgroup").toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Subgroup Join Request",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$requesterName requested to join $subgroupName",
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext, "reject"),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext, "accept"),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(sheetContext, "view_profile"),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text("View Profile"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invitationSheet(
    BuildContext sheetContext,
    Map<String, dynamic> invitation,
  ) {
    final colorScheme = Theme.of(sheetContext).colorScheme;
    final textTheme = Theme.of(sheetContext).textTheme;
    final status = (invitation["status"] ?? "PENDING").toString();
    final isPending = status == "PENDING";
    final meetingPoint = (invitation["meetingPoint"] ?? "").toString().trim();
    final description = (invitation["rideDescription"] ?? "").toString().trim();
    final rideStartTime = invitation["rideStartTime"]?.toString();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation["rideTitle"]?.toString() ?? "Ride invitation",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Invited by ${invitation["inviterName"] ?? "Unknown"}",
                  style: textTheme.bodyMedium,
                ),
                if (rideStartTime != null && rideStartTime.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _inviteMetaRow(
                    sheetContext,
                    Icons.schedule,
                    formatDateTime(rideStartTime),
                  ),
                ],
                if (meetingPoint.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _inviteMetaRow(
                    sheetContext,
                    Icons.place_outlined,
                    meetingPoint,
                  ),
                ],
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          if (!isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status == "ACCEPTED"
                    ? "You already accepted this invitation."
                    : "You already rejected this invitation.",
                style: textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(sheetContext, isPending ? "reject" : null),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isPending
                          ? colorScheme.outline
                          : colorScheme.outlineVariant,
                    ),
                    foregroundColor: isPending
                        ? colorScheme.onSurface
                        : textTheme.bodySmall?.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isPending ? "Reject" : "Close"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPending
                      ? () => Navigator.pop(sheetContext, "accept")
                      : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor:
                        colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: textTheme.bodySmall?.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inviteMetaRow(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.tertiary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
      ],
    );
  }

  Widget _friendRequestSheet(
    BuildContext sheetContext,
    Map<String, dynamic> requestData,
  ) {
    final colorScheme = Theme.of(sheetContext).colorScheme;
    final textTheme = Theme.of(sheetContext).textTheme;
    final senderName = (requestData["senderName"] ?? "A friend").toString();
    final mutualCount = requestData["mutualCount"] as int? ?? 0;
    final isPending = requestData["isPending"] as bool? ?? true;
    final hasProfile =
        (requestData["senderUuid"]?.toString().isNotEmpty ?? false);
    final canResolveRequest = requestData["requestId"] != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Friend Request",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text("From $senderName", style: textTheme.bodyMedium),
                if (mutualCount > 0) ...[
                  const SizedBox(height: 8),
                  _inviteMetaRow(
                    sheetContext,
                    Icons.people_outline,
                    "$mutualCount mutual friend${mutualCount > 1 ? 's' : ''}",
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "This friend request is no longer pending.",
                style: textTheme.bodyMedium,
              ),
            ),
          if (!isPending) const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    isPending && canResolveRequest ? "reject" : null,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isPending
                          ? colorScheme.outline
                          : colorScheme.outlineVariant,
                    ),
                    foregroundColor: isPending
                        ? (canResolveRequest
                              ? colorScheme.onSurface
                              : textTheme.bodySmall?.color)
                        : textTheme.bodySmall?.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPending && canResolveRequest
                      ? () => Navigator.pop(sheetContext, "accept")
                      : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor:
                        colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: textTheme.bodySmall?.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasProfile
                  ? () => Navigator.pop(sheetContext, "view_profile")
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outlineVariant),
                foregroundColor: textTheme.bodyMedium?.color,
                disabledForegroundColor: textTheme.bodySmall?.color,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text("View Profile"),
            ),
          ),
        ],
      ),
    );
  }

  String _sectionKey(NotificationItem n) {
    final dt = DateTime.parse(n.time).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return "Last 7 Days";
  }

  Map<String, List<NotificationItem>> _groupByDate(
    List<NotificationItem> items,
  ) {
    final grouped = <String, List<NotificationItem>>{
      "Today": [],
      "Yesterday": [],
      "Last 7 Days": [],
    };

    for (final item in items) {
      grouped[_sectionKey(item)]!.add(item);
    }

    return grouped;
  }

  Widget _buildNotificationList(
    List<NotificationItem> items, {
    required bool unreadSection,
  }) {
    final textTheme = Theme.of(context).textTheme;
    if (items.isEmpty) {
      return Center(
        child: Text("No notifications", style: textTheme.bodyMedium),
      );
    }

    final grouped = _groupByDate(items);
    final sections = ["Today", "Yesterday", "Last 7 Days"];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final section in sections)
          if (grouped[section]!.isNotEmpty) ...[
            Text(
              section,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...grouped[section]!.map(
              (notification) =>
                  _notificationCard(notification, unreadSection: unreadSection),
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unread = notifications.where((n) => n.unread).toList();
    final read = notifications.where((n) => !n.unread).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    "Notifications",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$unreadCount",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () {
                      Navigator.pop(context, notifications);
                      widget.onClose();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: textTheme.bodySmall?.color,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: "Unread (${unread.length})"),
                    Tab(text: "Read (${read.length})"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationList(unread, unreadSection: true),
                  _buildNotificationList(read, unreadSection: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(NotificationItem n, {required bool unreadSection}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canMarkRead = unreadSection && n.unread;
    final canMarkUnread = !unreadSection && !n.unread;

    return Dismissible(
      key: Key("${n.id}_${n.unread}"),
      direction: canMarkRead
          ? DismissDirection.startToEnd
          : canMarkUnread
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.mark_email_read, color: colorScheme.onSecondary),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.tertiary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.mark_email_unread, color: colorScheme.onTertiary),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && canMarkRead) {
          toggleRead(n, true);
        } else if (direction == DismissDirection.endToStart && canMarkUnread) {
          toggleRead(n, false);
        }
        return false;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleNotificationTap(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: n.unread
                ? colorScheme.primary.withValues(alpha: 0.08)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.unread
                  ? colorScheme.primary.withValues(alpha: 0.25)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: n.unread
                      ? colorScheme.primary.withValues(alpha: 0.14)
                      : colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  n.unread
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: n.unread
                      ? colorScheme.primary
                      : textTheme.bodySmall?.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.desc,
                      style: TextStyle(
                        color: textTheme.bodyMedium?.color,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatTime(n.time),
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: canMarkRead
                    ? "Mark as read"
                    : canMarkUnread
                    ? "Mark as unread"
                    : null,
                onPressed: canMarkRead
                    ? () => toggleRead(n, true)
                    : canMarkUnread
                    ? () => toggleRead(n, false)
                    : null,
                icon: Icon(
                  canMarkRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  color: canMarkRead
                      ? colorScheme.secondary
                      : canMarkUnread
                      ? colorScheme.tertiary
                      : textTheme.bodySmall?.color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
