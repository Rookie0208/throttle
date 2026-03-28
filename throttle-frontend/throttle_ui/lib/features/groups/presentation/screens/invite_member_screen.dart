import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/features/groups/data/services/group_service.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';

class InviteMemberScreen extends StatefulWidget {
  final String groupId;
  final String token;

  const InviteMemberScreen({
    super.key,
    required this.groupId,
    required this.token,
  });

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _friends = [];
  Set<String> _existingMemberUuids = <String>{};
  final Set<String> _invitingUuids = <String>{};
  final Set<String> _invitedUuids = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final me = await UserService.getMe();
      final currentUserUuid = me?['id']?.toString();
      if (currentUserUuid == null || currentUserUuid.isEmpty) {
        throw Exception("Unable to load your profile");
      }

      final friendsFuture = FriendService.getFriends(currentUserUuid);
      final membersFuture = GroupService.fetchRideMembers(
        widget.token,
        widget.groupId,
      );

      final results = await Future.wait([friendsFuture, membersFuture]);
      final friends = (results[0] as List)
          .whereType<Map>()
          .map((friend) => Map<String, dynamic>.from(friend))
          .toList();
      final membersResponse = Map<String, dynamic>.from(results[1] as Map);
      final members = (membersResponse['data'] as List? ?? const [])
          .whereType<Map>()
          .map((member) => Map<String, dynamic>.from(member))
          .toList();

      if (!mounted) return;
      setState(() {
        _friends = friends;
        _existingMemberUuids = members
            .map((member) => member['userUuid']?.toString() ?? '')
            .where((uuid) => uuid.isNotEmpty)
            .toSet();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _inviteFriend(Map<String, dynamic> friend) async {
    final friendUuid = friend['uuid']?.toString();
    if (friendUuid == null || friendUuid.isEmpty) return;

    setState(() => _invitingUuids.add(friendUuid));
    try {
      await RideService.inviteMember(widget.token, widget.groupId, friendUuid);
      if (!mounted) return;
      setState(() {
        _invitingUuids.remove(friendUuid);
        _invitedUuids.add(friendUuid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invitation sent to ${_displayName(friend)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _invitingUuids.remove(friendUuid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _displayName(Map<String, dynamic> user) {
    final firstName = user['firstName']?.toString().trim() ?? '';
    final lastName = user['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Unknown Rider' : fullName;
  }

  List<Map<String, dynamic>> get _filteredFriends {
    final query = _searchController.text.trim().toLowerCase();
    return _friends.where((friend) {
      final uuid = friend['uuid']?.toString() ?? '';
      if (_existingMemberUuids.contains(uuid)) {
        return false;
      }
      if (query.isEmpty) return true;
      final fullName = _displayName(friend).toLowerCase();
      final email = friend['email']?.toString().toLowerCase() ?? '';
      return fullName.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Add Members',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search friends',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _filteredFriends.isEmpty
                        ? const Center(
                            child: Text(
                              'No friends available to invite.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredFriends.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final friend = _filteredFriends[index];
                              final friendUuid =
                                  friend['uuid']?.toString() ?? '';
                              final isInviting =
                                  _invitingUuids.contains(friendUuid);
                              final isInvited =
                                  _invitedUuids.contains(friendUuid);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.borderSoft),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.surfaceMuted,
                                      backgroundImage:
                                          (friend['profileImage'] != null &&
                                              friend['profileImage']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              friend['profileImage'].toString(),
                                            )
                                          : null,
                                      child: (friend['profileImage'] == null ||
                                              friend['profileImage']
                                                  .toString()
                                                  .isEmpty)
                                          ? const Icon(
                                              Icons.person,
                                              color: AppColors.textSecondary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayName(friend),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if ((friend['email'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              friend['email'].toString(),
                                              style: const TextStyle(
                                                color: AppColors.textHint,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: isInviting || isInvited
                                          ? null
                                          : () => _inviteFriend(friend),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isInvited
                                            ? AppColors.surfaceMuted
                                            : AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        disabledBackgroundColor:
                                            AppColors.surfaceMuted,
                                        disabledForegroundColor:
                                            AppColors.textMuted,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: isInviting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.white,
                                              ),
                                            )
                                          : Text(isInvited ? 'Sent' : 'Invite'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
