import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/features/notifications/data/models/notification_model.dart';
import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';

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
    }).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  int get unreadCount => notifications.where((n) => n.unread).length;

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
    if (notification.type != "RIDE_GROUP_INVITE" ||
        notification.referenceId == null) {
      return;
    }

    try {
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
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => _invitationSheet(sheetContext, invitation),
      );

      if (action == null) return;

      if (action == "accept") {
        await RideService.acceptInvitation(widget.token, notification.referenceId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride invitation accepted")),
        );
      } else if (action == "reject") {
        await RideService.rejectInvitation(widget.token, notification.referenceId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride invitation rejected")),
        );
      }

      await loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Widget _invitationSheet(
    BuildContext sheetContext,
    Map<String, dynamic> invitation,
  ) {
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
              color: AppColors.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withOpacity(.24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation["rideTitle"]?.toString() ?? "Ride invitation",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Invited by ${invitation["inviterName"] ?? "Unknown"}",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (rideStartTime != null && rideStartTime.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _inviteMetaRow(Icons.schedule, formatDateTime(rideStartTime)),
                ],
                if (meetingPoint.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _inviteMetaRow(Icons.place_outlined, meetingPoint),
                ],
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status == "ACCEPTED"
                    ? "You already accepted this invitation."
                    : "You already rejected this invitation.",
                style: const TextStyle(color: AppColors.textSecondary),
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
                      color: isPending ? AppColors.border : AppColors.borderSoft,
                    ),
                    foregroundColor: isPending
                        ? AppColors.textPrimary
                        : AppColors.textHint,
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.surfaceMuted,
                    disabledForegroundColor: AppColors.textHint,
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

  Widget _inviteMetaRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.highlight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
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

  Map<String, List<NotificationItem>> _groupByDate(List<NotificationItem> items) {
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

  Widget _buildNotificationList(List<NotificationItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No notifications",
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ...grouped[section]!.map(_notificationCard),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unread = notifications.where((n) => n.unread).toList();
    final read = notifications.where((n) => !n.unread).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                      color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$unreadCount",
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
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
                  color: AppColors.white.withOpacity(.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.white12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x447D39EB),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.textMuted,
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
                  _buildNotificationList(unread),
                  _buildNotificationList(read),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(NotificationItem n) {
    return Dismissible(
      key: Key("${n.id}_${n.unread}"),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.mark_email_read, color: AppColors.black),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.highlight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.mark_email_unread, color: AppColors.black),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          toggleRead(n, true);
        } else {
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
                ? AppColors.primary.withOpacity(.05)
                : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.unread
                  ? AppColors.primary.withOpacity(.3)
                  : AppColors.primary.withOpacity(.15),
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
                      ? AppColors.secondary.withOpacity(.14)
                      : AppColors.white.withOpacity(.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  n.unread ? Icons.notifications_active : Icons.notifications_none,
                  color: n.unread ? AppColors.secondary : AppColors.white70,
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
                        color: n.unread ? AppColors.white : AppColors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.desc,
                      style: TextStyle(
                        color: n.unread ? AppColors.white : AppColors.white70,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatTime(n.time),
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: n.unread ? "Mark as read" : "Mark as unread",
                onPressed: () => toggleRead(n, n.unread),
                icon: Icon(
                  n.unread ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                  color: n.unread ? AppColors.secondary : AppColors.highlight,
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
