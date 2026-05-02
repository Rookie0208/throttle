import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/features/groups/data/services/group_service.dart';
import 'package:throttle_ui/features/groups/data/services/sub_groups_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class InviteMemberScreen extends StatefulWidget {
  final String rideUuid;
  final String token;
  final String? subgroupUuid;
  final bool selectionOnly;
  final List<String> preselectedMemberUuids;
  final bool preRideFrozen;

  const InviteMemberScreen({
    super.key,
    required this.rideUuid,
    required this.token,
    this.subgroupUuid,
    this.selectionOnly = false,
    this.preselectedMemberUuids = const [],
    this.preRideFrozen = false,
  });

  bool get isRideInviteMode => subgroupUuid == null && !selectionOnly;
  bool get isSubGroupMode => subgroupUuid != null;

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _candidates = [];
  final Set<String> _invitingUuids = <String>{};
  final Set<String> _pendingInviteUuids = <String>{};
  final Set<String> _selectedUuids = <String>{};
  Set<String> _excludedUuids = <String>{};
  bool _loading = true;
  bool _submittingSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedUuids.addAll(widget.preselectedMemberUuids);
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
      if (widget.isRideInviteMode) {
        final candidates = await RideService.fetchInviteCandidates(
          widget.token,
          widget.rideUuid,
        );

        if (!mounted) return;
        setState(() {
          _candidates = candidates;
          _pendingInviteUuids.addAll(
            candidates
                .where((candidate) => candidate['invitationPending'] == true)
                .map((candidate) => candidate['userUuid']?.toString() ?? '')
                .where((uuid) => uuid.isNotEmpty),
          );
          _loading = false;
        });
        return;
      }

      final membersFuture = GroupService.fetchRideMembers(
        widget.token,
        widget.rideUuid,
      );
      final subgroupMembersFuture = widget.subgroupUuid == null
          ? Future.value(<Map<String, dynamic>>[])
          : SubGroupService.fetchSubGroupMembers(
              widget.token,
              widget.subgroupUuid!,
            );

      final results = await Future.wait([membersFuture, subgroupMembersFuture]);
      final rideMembers =
          (results[0] as Map<String, dynamic>)['data'] as List? ?? const [];
      final subgroupMembers = results[1] as List<Map<String, dynamic>>;

      final subgroupMemberUuids = subgroupMembers
          .map((member) => member['userUuid']?.toString() ?? '')
          .where((uuid) => uuid.isNotEmpty)
          .toSet();

      final candidates = rideMembers
          .whereType<Map>()
          .map((member) => Map<String, dynamic>.from(member))
          .where((member) {
            final role = (member['role'] ?? '').toString().toUpperCase();
            return role != 'CAPTAIN' && role != 'ADMIN';
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        _excludedUuids = subgroupMemberUuids;
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

  String _displayName(Map<String, dynamic> user) {
    final fullName = (user['username'] ?? '').toString();
    return fullName.isEmpty ? 'Unknown Rider' : fullName;
  }

  String _subtitle(Map<String, dynamic> user) {
    final riderId = user['riderId']?.toString().trim() ?? '';
    final email = user['email']?.toString().trim() ?? '';
    if (riderId.isNotEmpty) return '@$riderId';
    if (email.isNotEmpty) return email;
    return '';
  }

  List<Map<String, dynamic>> get _filteredCandidates {
    final query = _searchController.text.trim().toLowerCase();
    return _candidates.where((candidate) {
      final uuid =
          candidate['userUuid']?.toString() ??
          candidate['uuid']?.toString() ??
          '';
      if (_excludedUuids.contains(uuid)) {
        return false;
      }

      if (query.isEmpty) return true;
      final name = _displayName(candidate).toLowerCase();
      final riderId = (candidate['riderId'] ?? '').toString().toLowerCase();
      final email = (candidate['email'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          riderId.contains(query) ||
          email.contains(query);
    }).toList();
  }

  Future<void> _copyInviteLink() async {
    final link = "throttle://groups/${widget.rideUuid}";
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Invite link copied. Share it anywhere to invite riders.",
        ),
      ),
    );
  }

  Future<void> _inviteFriend(Map<String, dynamic> friend) async {
    if (widget.preRideFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride setup is frozen after start')),
      );
      return;
    }

    final friendUuid =
        friend['userUuid']?.toString() ?? friend['uuid']?.toString();
    if (friendUuid == null || friendUuid.isEmpty) return;

    setState(() => _invitingUuids.add(friendUuid));
    try {
      await RideService.inviteMember(widget.token, widget.rideUuid, friendUuid);
      if (!mounted) return;
      setState(() {
        _invitingUuids.remove(friendUuid);
        _pendingInviteUuids.add(friendUuid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation sent to ${_displayName(friend)}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _invitingUuids.remove(friendUuid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _submitSelectedMembers() async {
    if (widget.preRideFrozen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride setup is frozen after start')),
      );
      return;
    }

    final selected = _selectedUuids.toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one member')),
      );
      return;
    }

    if (widget.selectionOnly) {
      Navigator.pop(context, selected);
      return;
    }

    if (widget.subgroupUuid == null) {
      return;
    }

    setState(() => _submittingSelection = true);
    try {
      await SubGroupService.addSubGroupMembers(
        widget.token,
        widget.subgroupUuid!,
        selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Members added to subgroup')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingSelection = false);
      }
    }
  }

  String _screenTitle() {
    if (widget.isRideInviteMode) return 'Add Members';
    if (widget.selectionOnly) return 'Select Members';
    return 'Add Subgroup Members';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final candidates = _filteredCandidates;
        final hasInviteCandidates = _candidates.isNotEmpty;
        final showInviteLinkEmptyState =
            widget.isRideInviteMode && !hasInviteCandidates;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _screenTitle(),
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: theme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search riders',
                          hintStyle: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.4),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.textPrimary.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: theme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: candidates.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        showInviteLinkEmptyState
                                            ? 'No friends available to invite yet.'
                                            : widget.isRideInviteMode
                                            ? 'No riders match your search.'
                                            : 'No ride members available to add.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: theme.textPrimary.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                      if (showInviteLinkEmptyState) ...[
                                        const SizedBox(height: 14),
                                        TextButton(
                                          onPressed: _copyInviteLink,
                                          child: Text(
                                            "Invite through link",
                                            style: GoogleFonts.lexend(
                                              color: theme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: candidates.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final candidate = candidates[index];
                                  final uuid =
                                      candidate['userUuid']?.toString() ??
                                      candidate['uuid']?.toString() ??
                                      '';
                                  final isInviting = _invitingUuids.contains(
                                    uuid,
                                  );
                                  final isInvited = _pendingInviteUuids
                                      .contains(uuid);
                                  final isSelected = _selectedUuids.contains(
                                    uuid,
                                  );
                                  final subtitle = _subtitle(candidate);

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: theme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0x52B8C6DA),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: theme.primary
                                              .withValues(alpha: 0.1),
                                          backgroundImage:
                                              (candidate['profileImage'] !=
                                                      null &&
                                                  candidate['profileImage']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? NetworkImage(
                                                  candidate['profileImage']
                                                      .toString(),
                                                )
                                              : null,
                                          child:
                                              (candidate['profileImage'] ==
                                                      null ||
                                                  candidate['profileImage']
                                                      .toString()
                                                      .isEmpty)
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Color(0xff4F596E),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _displayName(candidate),
                                                      style: TextStyle(
                                                        color:
                                                            theme.textPrimary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (candidate['clubFriend'] ==
                                                      true)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme.primary
                                                            .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Club',
                                                        style: TextStyle(
                                                          color: theme.primary,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (subtitle.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  subtitle,
                                                  style: TextStyle(
                                                    color: theme.textPrimary
                                                        .withValues(alpha: 0.4),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (widget.isRideInviteMode)
                                          ElevatedButton(
                                            onPressed: isInviting || isInvited
                                                ? null
                                                : () =>
                                                      _inviteFriend(candidate),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isInvited
                                                  ? theme.primary.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : theme.primary,
                                              foregroundColor: isInvited
                                                  ? theme.primary
                                                  : Colors.white,
                                              disabledBackgroundColor:
                                                  theme.surface,
                                              disabledForegroundColor: theme
                                                  .textPrimary
                                                  .withValues(alpha: 0.4),
                                            ),
                                            child: isInviting
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Text(
                                                    isInvited
                                                        ? 'Invited'
                                                        : 'Send Invite',
                                                  ),
                                          )
                                        else
                                          Checkbox(
                                            value: isSelected,
                                            activeColor: theme.primary,
                                            onChanged: (_) {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedUuids.remove(uuid);
                                                } else {
                                                  _selectedUuids.add(uuid);
                                                }
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (!widget.isRideInviteMode) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _submittingSelection
                                ? null
                                : _submitSelectedMembers,
                            child: Text(
                              _submittingSelection
                                  ? 'Saving...'
                                  : widget.selectionOnly
                                  ? 'Use Selected'
                                  : 'Add Selected',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
