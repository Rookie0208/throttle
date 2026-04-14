import 'package:flutter/material.dart';
import 'package:throttle_ui/core/globals.dart';
import 'package:throttle_ui/features/groups/data/services/chat_service.dart';
import 'package:throttle_ui/features/groups/presentation/screens/create_subgroup_screen.dart';
import 'package:throttle_ui/features/groups/presentation/widgets/group_info_sheet.dart';
import 'package:throttle_ui/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/rides/presentation/screens/live_ride_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_start_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final String token;

  const GroupChatScreen({super.key, required this.group, required this.token});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List subGroups = [];
  bool loadingSubGroups = true;

  /// NEW STATE
  String? activeSubGroupId;
  Map<String, dynamic>? activeSubGroup;

  /// messages per chat
  List<Map<String, dynamic>> messages = [];
  bool loadingMessages = true;

  String get _rideUuid =>
      (widget.group["rideUuid"] ?? widget.group["uuid"]).toString();

  String get _groupUuid => widget.group["uuid"].toString();

  String currentUserRole = "";

  List<Map<String, dynamic>> _orderedMessagesFromHistory(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
        .reversed
        .toList();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  bool get _canManageRide =>
      {"CAPTAIN", "ADMIN", "CO_CAPTAIN"}.contains(currentUserRole);

  bool _isSubgroupMember(Map<dynamic, dynamic>? group) =>
      group?["isMember"] == true || group?["member"] == true;

  bool get _isGroupLocked {
    final groupStatus = (widget.group["status"] ?? "").toString().toLowerCase();
    final rideStatus = (widget.group["rideStatus"] ?? "")
        .toString()
        .toUpperCase();
    return groupStatus == "archive" ||
        {"CANCELLED", "COMPLETED", "ENDED"}.contains(rideStatus);
  }

  bool get _isRideStarted {
    final rideStatus = (widget.group["rideStatus"] ?? "")
        .toString()
        .toUpperCase();
    return {
      "PARTIAL_STARTED",
      "READY_TO_START",
      "ACTIVE",
      "IN_PROGRESS",
      "COMPLETED",
      "CANCELLED",
      "ENDED",
    }.contains(rideStatus);
  }

  /// ================= FETCH SUBGROUPS =================
  Future<void> fetchSubGroups() async {
    try {
      final result = await SubGroupService.fetchSubGroups(
        widget.token,
        _rideUuid,
      );

      Map<String, dynamic>? refreshedActive;
      if (activeSubGroupId != null) {
        for (final group in result) {
          if (group["uuid"]?.toString() == activeSubGroupId) {
            refreshedActive = group;
            break;
          }
        }
      }

      setState(() {
        subGroups = result;
        if (refreshedActive != null) {
          activeSubGroup = refreshedActive;
        }
        loadingSubGroups = false;
      });
    } catch (e) {
      loadingSubGroups = false;
    }
  }

  Future<void> _loadGroupContext() async {
    try {
      final details = _groupUuid == _rideUuid
          ? await SubGroupService.fetchMainGroupDetails(widget.token, _rideUuid)
          : await SubGroupService.fetchSubGroupDetails(
              widget.token,
              _groupUuid,
            );
      if (!mounted) return;
      setState(() {
        widget.group.addAll(details);
        currentUserRole =
            (details["myRole"] ?? widget.group["myRole"] ?? currentUserRole)
                .toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        currentUserRole = (widget.group["myRole"] ?? currentUserRole)
            .toString();
      });
    }
  }

  /// ================= FETCH MESSAGES =================
  Future<void> fetchMessages(String id) async {
    setState(() {
      loadingMessages = true;
    });

    try {
      final data = await ChatService.fetchMessages(id);
      if (!mounted) return;
      setState(() {
        messages = _orderedMessagesFromHistory(data);
        loadingMessages = false;
      });
      _scrollToLatest();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingMessages = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    currentUserRole = (widget.group["myRole"] ?? "").toString();
    _loadGroupContext();
    fetchSubGroups();
    _connectChat(_groupUuid);

    /// load main chat initially
    fetchMessages(widget.group["uuid"].toString());
  }

  @override
  void dispose() {
    _chatService.disconnect();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _connectChat(String groupId) {
    _chatService.disconnect();
    _chatService.connect(
      groupId: groupId,
      token: widget.token,
      onMessageReceived: (dynamic message) {
        if (!mounted) return;
        setState(() {
          messages.add(Map<String, dynamic>.from(message as Map));
        });
        _scrollToLatest();
      },
    );
  }

  /// ================= SEND =================
  void sendMessage() {
    if (_isGroupLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("This group is locked")));
      return;
    }
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      groupId: (activeSubGroupId ?? _groupUuid),
      text: text,
    );
    messageController.clear();
  }

  /// ================= UI =================
  bool _isCurrentUserMessage(Map<String, dynamic> msg) {
    final currentUserId = UserSession.userId?.toString().trim();
    final senderId = msg["senderId"]?.toString().trim();

    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        senderId != null &&
        senderId == currentUserId) {
      return true;
    }

    final senderName = (msg["senderName"] ?? msg["sender"] ?? "")
        .toString()
        .trim()
        .toLowerCase();
    return senderName == "you";
  }

  String _systemMessageText(Map<String, dynamic> msg) {
    final body = (msg["message"] ?? "").toString();

    if (!_isCurrentUserMessage(msg)) {
      return body;
    }

    final trimmedBody = body.trimLeft();
    final actionMatch = RegExp(
      r'^(.*?)(\s+(joined|left|is en route|accepted|declined)\b.*)$',
      caseSensitive: false,
    ).firstMatch(trimmedBody);

    if (actionMatch != null) {
      final suffix = actionMatch.group(2) ?? "";
      return "You$suffix";
    }

    return body;
  }

  Widget _buildMessage(Map<String, dynamic> msg, AppThemeConfig theme) {
    final senderName = (msg["senderName"] ?? msg["sender"] ?? "Rider")
        .toString();
    final isSystem =
        (msg["messageType"] ?? "").toString().toUpperCase() == "SYSTEM";
    final isMe = _isCurrentUserMessage(msg);
    final body = isSystem
        ? _systemMessageText(msg)
        : (msg["message"] ?? "").toString();

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            body,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isMe ? theme.primary : theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isMe ? null : Border.all(color: const Color(0x52B8C6DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            Text(
              body,
              style: TextStyle(color: isMe ? Colors.white : theme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SUBGROUP BAR =================
  Widget _subGroupBar(AppThemeConfig theme) {
    if (loadingSubGroups) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    /// ROLE BASED FILTER
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.surface,
        border: const Border(bottom: BorderSide(color: Color(0x52B8C6DA))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          /// MAIN GROUP
          GestureDetector(
            onTap: () {
              setState(() {
                activeSubGroup = null;
                activeSubGroupId = null;
              });
              _connectChat(_groupUuid);
              fetchMessages(widget.group["uuid"]);
            },
            child: _chip("All", activeSubGroupId == null, theme),
          ),

          ...subGroups.map((g) {
            final isSelected = activeSubGroupId == g["uuid"];
            final isMember = _isSubgroupMember(g);
            final canOpenChat = isMember || _canManageRide;
            final joinLabel = g["joinRequestPending"] == true
                ? "Pending"
                : g["canJoinDirectly"] == true
                ? "Join"
                : g["canRequestToJoin"] == true
                ? "Request"
                : "Join";

            return GestureDetector(
              onTap: () {
                if (!canOpenChat) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RideInfoScreen(
                        rideGroup: {
                          ...widget.group,
                          ...Map<String, dynamic>.from(g),
                          "isSubGroup": true,
                        },
                        token: widget.token,
                      ),
                    ),
                  ).then((_) => fetchSubGroups());
                  return;
                }
                setState(() {
                  activeSubGroupId = g["uuid"];
                  activeSubGroup = g;
                });

                _connectChat(g["uuid"].toString());
                fetchMessages(g["uuid"]);
              },
              child: _chip(
                canOpenChat ? g["name"] : "${g["name"]} • $joinLabel",
                isSelected,
                theme,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected, AppThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selected ? theme.primary : theme.background,
        borderRadius: BorderRadius.circular(20),
        border: selected ? null : Border.all(color: const Color(0x52B8C6DA)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ================= MESSAGE AREA =================
  Widget _chatArea(AppThemeConfig theme) {
    if (loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Text(
          "No messages yet",
          style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (_, i) => _buildMessage(messages[i], theme),
    );
  }

  Widget _messageInput(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surface,
        border: const Border(top: BorderSide(color: Color(0x52B8C6DA))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: "Type message...",
                hintStyle: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.primary),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        bool isActive =
            (activeSubGroup?["status"] ?? widget.group["status"]) == "active";

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            title: Text(
              activeSubGroup != null
                  ? "${widget.group["title"] ?? widget.group["name"]} • ${activeSubGroup!["name"]}"
                  : (widget.group["title"] ?? widget.group["name"]).toString(),
              style: TextStyle(color: theme.textPrimary, fontSize: 18),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
            actions: [
              if (activeSubGroup == null)
                IconButton(
                  icon: Icon(
                    Icons.dashboard_outlined,
                    color: theme.textPrimary,
                  ),
                  onPressed: _openRideConsole,
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.textPrimary),
                color: theme.surface,
                onSelected: (val) => _handleMenuSelection(val),
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      value: 'info',
                      child: Text(
                        "Group Info",
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ),
                  ];
                  if (_canManageRide &&
                      activeSubGroup == null &&
                      !_isRideStarted) {
                    items.add(
                      PopupMenuItem(
                        value: 'invite',
                        child: Text(
                          "Invite Riders",
                          style: TextStyle(color: theme.textPrimary),
                        ),
                      ),
                    );
                    items.add(
                      PopupMenuItem(
                        value: 'subgroup',
                        child: Text(
                          "Create Subgroup",
                          style: TextStyle(color: theme.textPrimary),
                        ),
                      ),
                    );
                  }
                  items.add(
                    PopupMenuItem(
                      value: 'leave',
                      child: Text(
                        "Leave Group",
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ),
                  );
                  return items;
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _subGroupBar(theme),
              if (!isActive)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _isGroupLocked
                        ? "This group is locked. Editing and messaging are disabled."
                        : "Messaging disabled",
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              Expanded(child: _chatArea(theme)),
              if (isActive &&
                  (activeSubGroup == null ||
                      _isSubgroupMember(activeSubGroup) ||
                      _canManageRide))
                _messageInput(theme),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'info':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideInfoScreen(
              rideGroup: activeSubGroup == null
                  ? widget.group
                  : {
                      ...widget.group,
                      ...activeSubGroup!,
                      "isSubGroup": true,
                      "myRole":
                          activeSubGroup?["myRole"] ?? widget.group["myRole"],
                    },
              token: widget.token,
            ),
          ),
        ).then((_) async {
          await _loadGroupContext();
          await fetchSubGroups();
        });
        break;

      case 'invite':
        if (_isGroupLocked || _isRideStarted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ride setup is frozen after start")),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                InviteMemberScreen(rideUuid: _rideUuid, token: widget.token),
          ),
        );
        break;

      case 'subgroup':
        if (_isGroupLocked || _isRideStarted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ride setup is frozen after start")),
          );
          return;
        }
        _openSubGroupCreation();
        break;

      case 'leave':
        _leaveGroup();
        break;
    }
  }

  void _openRideConsole() {
    final group = widget.group;

    final rideStatus = (group["rideStatus"] ?? group["status"] ?? "")
        .toString()
        .toUpperCase();

    final title = (group["title"] ?? group["name"] ?? "Ride").toString();

    /// ✅ Parse start time safely
    DateTime? parsedTime;
    try {
      parsedTime = DateTime.parse(group["startTime"] ?? "");
    } catch (_) {}

    /// ✅ Format date & time
    final rideDate = parsedTime != null
        ? "${parsedTime.day} ${_month(parsedTime.month)}, ${parsedTime.year}"
        : "N/A";

    final rideTime = parsedTime != null
        ? "${_formatHour(parsedTime.hour)}:${parsedTime.minute.toString().padLeft(2, '0')} ${parsedTime.hour >= 12 ? "PM" : "AM"}"
        : "N/A";

    /// ✅ Location handling
    final locations = List<Map<String, dynamic>>.from(
      group["locations"] ?? const [],
    );

    final startLocation = locations.isNotEmpty
        ? (locations.first["name"] ?? "Start point").toString()
        : (group["meetingPoint"] ?? group["startLocation"] ?? "Start point")
              .toString();

    /// ✅ Rider count (prefer joined riders if available)
    final memberCount =
        int.tryParse(
          (group["joinedRiders"] ?? group["members"] ?? group["maxRiders"] ?? 0)
              .toString(),
        ) ??
        0;

    /// ✅ Navigation target
    final Widget target = rideStatus == "ACTIVE"
        ? LiveRideScreen(
            groupName: title,
            onEndRide: () {},
            token: widget.token,
            rideUuid: _rideUuid,
          )
        : RideStartScreen(
            groupName: title,
            rideDate: rideDate,
            rideTime: rideTime,
            location: startLocation,
            memberCount: memberCount,
            token: widget.token,
            rideUuid: _rideUuid,
          );

    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  String _month(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m - 1];
  }

  String _formatHour(int hour) {
    if (hour == 0) return "12";
    if (hour > 12) return (hour - 12).toString();
    return hour.toString();
  }

  void _openSubGroupCreation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateSubGroupScreen(rideUuid: _rideUuid, token: widget.token),
      ),
    );

    /// If subgroup created successfully
    if (result != null) {
      /// Refresh subgroup list
      await fetchSubGroups();

      /// Auto-switch to new subgroup
      setState(() {
        activeSubGroup = result;
        activeSubGroupId = result["uuid"];
      });

      /// Load its messages
      fetchMessages(result["uuid"]);
    }
  }

  void _leaveGroup() async {
    try {
      if (activeSubGroup != null) {
        await SubGroupService.leaveSubGroup(
          widget.token,
          activeSubGroup!["uuid"].toString(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Exited subgroup")));
        setState(() {
          activeSubGroup = null;
          activeSubGroupId = null;
        });
        await fetchSubGroups();
        await fetchMessages(widget.group["uuid"]);
        return;
      }

      await RideService.leaveRide(widget.token, _rideUuid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Exited ride")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }
}
