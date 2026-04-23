import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/globals.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/clubs/data/services/club_chat_service.dart';
import 'package:throttle_ui/features/clubs/data/services/club_service.dart';
import 'package:throttle_ui/features/profile/presentation/screens/public_profile_screen.dart';

class ClubChatScreen extends StatefulWidget {
  final String clubUuid;
  final int initialTabIndex;

  const ClubChatScreen({
    super.key,
    required this.clubUuid,
    this.initialTabIndex = 2,
  });

  @override
  State<ClubChatScreen> createState() => _ClubChatScreenState();
}

class _ClubChatScreenState extends State<ClubChatScreen> {
  final ClubChatService _chatService = ClubChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late int _selectedTab;
  bool _loading = true;
  bool _loadingMessages = true;
  bool _submitting = false;

  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _subgroups = [];
  List<Map<String, dynamic>> _messages = [];

  String? _activeChannelUuid;
  String _activeChannelName = 'Club chat';

  bool get _isAdmin =>
      (_club?['myRole'] ?? '').toString().toUpperCase() == 'ADMIN';

  bool _canOpenSubgroup(Map<String, dynamic> subgroup) {
    if (_isAdmin) return true;
    return subgroup['member'] == true;
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _loadClub();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClub() async {
    setState(() => _loading = true);
    try {
      final clubDetails = await ClubService.fetchClubDetails(widget.clubUuid);
      final membersFuture = ClubService.fetchMembers(widget.clubUuid);
      final subgroupsFuture = ClubService.fetchSubgroups(widget.clubUuid);
      final results = await Future.wait([membersFuture, subgroupsFuture]);

      if (!mounted) return;
      setState(() {
        _club = clubDetails;
        _members = results[0];
        _subgroups = results[1];
        final activeChannelStillAllowed =
            _activeChannelUuid == null ||
            _activeChannelUuid == widget.clubUuid ||
            _subgroups.any(
              (item) =>
                  item['uuid']?.toString() == _activeChannelUuid &&
                  _canOpenSubgroup(item),
            );
        _activeChannelUuid = activeChannelStillAllowed
            ? (_activeChannelUuid ?? widget.clubUuid)
            : widget.clubUuid;
        _activeChannelName = _activeChannelUuid == widget.clubUuid
            ? 'Club chat'
            : _subgroups
                      .firstWhere(
                        (item) =>
                            item['uuid']?.toString() == _activeChannelUuid,
                        orElse: () => <String, dynamic>{},
                      )['name']
                      ?.toString() ??
                  'Club chat';
        _loading = false;
      });
      await _connectAndLoadMessages(_activeChannelUuid ?? widget.clubUuid);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(e, isError: true);
    }
  }

  Future<void> _openChannel(String channelUuid, String label) async {
    if (channelUuid != widget.clubUuid) {
      final subgroup = _subgroups.cast<Map<String, dynamic>?>().firstWhere(
        (item) => item?['uuid']?.toString() == channelUuid,
        orElse: () => null,
      );
      if (subgroup == null || !_canOpenSubgroup(subgroup)) {
        _showMessage(
          'Only members added by the club admin can open this subgroup chat',
          isError: true,
        );
        return;
      }
    }

    setState(() => _activeChannelName = label);
    await _connectAndLoadMessages(channelUuid);
  }

  Future<void> _connectAndLoadMessages(String channelUuid) async {
    setState(() => _loadingMessages = true);
    try {
      final token = await AuthService.getToken();
      final messages = await ClubChatService.fetchMessages(channelUuid);
      if (!mounted) return;

      _chatService.connect(
        channelUuid: channelUuid,
        token: token ?? '',
        onMessageReceived: (message) {
          if (!mounted) return;
          setState(() {
            _messages.add(Map<String, dynamic>.from(message as Map));
          });
          _scrollToLatest();
        },
      );

      setState(() {
        _activeChannelUuid = channelUuid;
        _messages = messages
            .whereType<Map>()
            .map((message) => Map<String, dynamic>.from(message))
            .toList()
            .reversed
            .toList();
        _loadingMessages = false;
      });
      _scrollToLatest();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMessages = false);
      _showMessage(e, isError: true);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(text: text);
    _messageController.clear();
  }

  Future<void> _leaveClub() async {
    try {
      await ClubService.leaveClub(widget.clubUuid);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showMessage(e, isError: true);
    }
  }

  void _showMessage(Object error, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _changeRole(String userUuid, String role) async {
    try {
      await ClubService.updateMemberRole(widget.clubUuid, userUuid, role);
      await _loadClub();
      _showMessage('Member role updated');
    } catch (e) {
      _showMessage(e, isError: true);
    }
  }

  Future<void> _removeMember(String userUuid) async {
    try {
      await ClubService.removeMember(widget.clubUuid, userUuid);
      await _loadClub();
      _showMessage('Member removed');
    } catch (e) {
      _showMessage(e, isError: true);
    }
  }

  Future<void> _showAddMembersSheet(AppThemeConfig theme) async {
    final searchController = TextEditingController();
    final selected = <String>{};
    List<Map<String, dynamic>> candidates = [];
    bool loading = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> loadCandidates([String query = '']) async {
              setSheetState(() => loading = true);
              try {
                final results = await ClubService.searchMemberCandidates(
                  widget.clubUuid,
                  query,
                );
                if (!mounted) return;
                setSheetState(() {
                  candidates = results;
                  loading = false;
                });
              } catch (e) {
                setSheetState(() => loading = false);
              }
            }

            Future<void> submit() async {
              final navigator = Navigator.of(sheetContext);
              if (selected.isEmpty) {
                _showMessage('Select at least one rider', isError: true);
                return;
              }
              setSheetState(() => loading = true);
              try {
                await ClubService.addMembers(
                  widget.clubUuid,
                  selected.toList(),
                );
                if (!mounted) return;
                navigator.pop();
                await _loadClub();
                _showMessage('Members added successfully');
              } catch (e) {
                if (!mounted) return;
                _showMessage(e, isError: true);
              } finally {
                if (mounted) {
                  setSheetState(() => loading = false);
                }
              }
            }

            if (candidates.isEmpty && loading) {
              loadCandidates();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                18 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add riders',
                      style: GoogleFonts.lexend(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: loadCandidates,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name, rider id, or email',
                        prefixIcon: Icon(Icons.search, color: theme.primary),
                        filled: true,
                        fillColor: theme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.textPrimary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: theme.primary,
                              ),
                            )
                          : candidates.isEmpty
                          ? Center(
                              child: Text(
                                'No riders found',
                                style: TextStyle(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: candidates.length,
                              itemBuilder: (context, index) {
                                final rider = candidates[index];
                                final uuid =
                                    rider['userUuid']?.toString() ?? '';
                                final label = _displayName(rider);
                                final subtitle = [
                                  if ((rider['riderId'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    '@${rider['riderId']}',
                                  if ((rider['bike'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    rider['bike'].toString(),
                                ].join(' • ');

                                return CheckboxListTile(
                                  value: selected.contains(uuid),
                                  activeColor: theme.primary,
                                  title: Text(
                                    label,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: subtitle.isEmpty
                                      ? null
                                      : Text(
                                          subtitle,
                                          style: TextStyle(
                                            color: theme.textPrimary.withValues(
                                              alpha: 0.62,
                                            ),
                                          ),
                                        ),
                                  onChanged: (_) {
                                    setSheetState(() {
                                      if (selected.contains(uuid)) {
                                        selected.remove(uuid);
                                      } else {
                                        selected.add(uuid);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Add to Club'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  Future<void> _showCreateSubgroupSheet(AppThemeConfig theme) async {
    final nameController = TextEditingController();
    final selected = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final navigator = Navigator.of(sheetContext);
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _showMessage('Subgroup name is required', isError: true);
                return;
              }
              setSheetState(() => _submitting = true);
              try {
                await ClubService.createSubgroup(widget.clubUuid, {
                  'name': name,
                  'memberUuids': selected.toList(),
                });
                if (!mounted) return;
                navigator.pop();
                await _loadClub();
                _showMessage('Subgroup created');
              } catch (e) {
                if (!mounted) return;
                _showMessage(e, isError: true);
              } finally {
                if (mounted) {
                  setSheetState(() => _submitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                18 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create subgroup',
                      style: GoogleFonts.lexend(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use subgroups for interest threads inside the club.',
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Coffee crew',
                        filled: true,
                        fillColor: theme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.textPrimary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add members',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final uuid = member['userUuid']?.toString() ?? '';
                          return CheckboxListTile(
                            value: selected.contains(uuid),
                            activeColor: theme.primary,
                            title: Text(
                              _displayName(member),
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _memberSubtitle(member),
                              style: TextStyle(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.62,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              setSheetState(() {
                                if (selected.contains(uuid)) {
                                  selected.remove(uuid);
                                } else {
                                  selected.add(uuid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Subgroup'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  String _displayName(Map<String, dynamic> rider) {
    final firstName = (rider['firstName'] ?? '').toString().trim();
    final lastName = (rider['lastName'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    final riderId = (rider['riderId'] ?? '').toString().trim();
    return riderId.isNotEmpty ? '@$riderId' : 'Unknown rider';
  }

  String _memberSubtitle(Map<String, dynamic> rider) {
    final pieces = <String>[];
    final riderId = (rider['riderId'] ?? '').toString().trim();
    final bike = (rider['bike'] ?? '').toString().trim();
    final role = (rider['role'] ?? '').toString().trim();
    if (riderId.isNotEmpty) pieces.add('@$riderId');
    if (bike.isNotEmpty) pieces.add(bike);
    if (role.isNotEmpty) pieces.add(role);
    return pieces.isEmpty ? 'Rider' : pieces.join(' • ');
  }

  bool _isCurrentUserMessage(Map<String, dynamic> message) {
    return message['senderId']?.toString() == UserSession.userId?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              (_club?['name'] ?? 'Club').toString(),
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
            actions: [
              PopupMenuButton<String>(
                color: theme.surface,
                onSelected: (value) {
                  if (value == 'leave') {
                    _leaveClub();
                  } else if (value == 'add_members') {
                    _showAddMembersSheet(theme);
                  } else if (value == 'create_subgroup') {
                    _showCreateSubgroupSheet(theme);
                  }
                },
                itemBuilder: (_) => [
                  if (_isAdmin)
                    const PopupMenuItem(
                      value: 'add_members',
                      child: Text('Add members'),
                    ),
                  if (_isAdmin)
                    const PopupMenuItem(
                      value: 'create_subgroup',
                      child: Text('Create subgroup'),
                    ),
                  const PopupMenuItem(
                    value: 'leave',
                    child: Text('Leave club'),
                  ),
                ],
              ),
            ],
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : Column(
                  children: [
                    _tabRow(theme),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTab,
                        children: [
                          _overviewTab(theme),
                          _membersTab(theme),
                          _chatTab(theme),
                          _subgroupsTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _tabRow(AppThemeConfig theme) {
    const labels = ['Overview', 'Members', 'Chat', 'Subgroups'];
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = _selectedTab == index;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: selected,
            labelStyle: TextStyle(
              color: selected
                  ? (theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white)
                  : theme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: theme.primary,
            backgroundColor: theme.surface,
            onSelected: (_) => setState(() => _selectedTab = index),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: labels.length,
      ),
    );
  }

  Widget _overviewTab(AppThemeConfig theme) {
    final club = _club ?? const <String, dynamic>{};
    final memberCount = (club['memberCount'] ?? 0).toString();
    final subgroupCount = (_subgroups.length).toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                theme.primary.withValues(alpha: 0.86),
                theme.secondary.withValues(alpha: 0.72),
                theme.tertiary.withValues(alpha: 0.64),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                (club['name'] ?? 'Club').toString(),
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (club['title'] ?? 'Rider community').toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _infoCard(
          theme,
          title: 'About',
          child: Text(
            (club['description'] ?? 'No club description yet.').toString(),
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.74),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(theme, 'Members', memberCount, Icons.groups_2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                theme,
                'Subgroups',
                subgroupCount,
                Icons.account_tree_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _membersTab(AppThemeConfig theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_members.length} members',
                  style: GoogleFonts.lexend(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isAdmin)
                TextButton.icon(
                  onPressed: () => _showAddMembersSheet(theme),
                  icon: Icon(Icons.person_add_alt_1, color: theme.primary),
                  label: Text('Add', style: TextStyle(color: theme.primary)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final userUuid = member['userUuid']?.toString() ?? '';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        user: {
                          'uuid': userUuid,
                          'firstName': member['firstName'],
                          'lastName': member['lastName'],
                          'riderId': member['riderId'],
                          'profileImage': member['profileImage'],
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.textPrimary.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.primary.withValues(alpha: 0.14),
                        child: Text(
                          _displayName(member)
                              .split(' ')
                              .where((item) => item.isNotEmpty)
                              .take(2)
                              .map((item) => item[0].toUpperCase())
                              .join(),
                          style: TextStyle(
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(member),
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _memberSubtitle(member),
                              style: TextStyle(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.64,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isAdmin && userUuid != UserSession.userId)
                        PopupMenuButton<String>(
                          color: theme.surface,
                          onSelected: (value) {
                            if (value == 'promote') {
                              _changeRole(userUuid, 'ADMIN');
                            } else if (value == 'demote') {
                              _changeRole(userUuid, 'MEMBER');
                            } else if (value == 'remove') {
                              _removeMember(userUuid);
                            }
                          },
                          itemBuilder: (_) => [
                            if ((member['role'] ?? '').toString() != 'ADMIN')
                              const PopupMenuItem(
                                value: 'promote',
                                child: Text('Promote to admin'),
                              ),
                            if ((member['role'] ?? '').toString() == 'ADMIN')
                              const PopupMenuItem(
                                value: 'demote',
                                child: Text('Demote to member'),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove from club'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chatTab(AppThemeConfig theme) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _channelChip(theme, widget.clubUuid, 'Club chat'),
              const SizedBox(width: 8),
              ..._subgroups
                  .where((item) => item['member'] == true || _isAdmin)
                  .map(
                    (subgroup) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _channelChip(
                        theme,
                        subgroup['uuid'].toString(),
                        subgroup['name']?.toString() ?? 'Subgroup',
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMessages
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMine = _isCurrentUserMessage(message);
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMine ? theme.primary : theme.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMine)
                              Text(
                                (message['senderName'] ?? 'Rider').toString(),
                                style: TextStyle(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (!isMine) const SizedBox(height: 4),
                            Text(
                              (message['message'] ?? '').toString(),
                              style: TextStyle(
                                color: isMine
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.black
                                          : Colors.white)
                                    : theme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: theme.background,
            border: Border(
              top: BorderSide(color: theme.textPrimary.withValues(alpha: 0.06)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message $_activeChannelName',
                      hintStyle: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.45),
                      ),
                      filled: true,
                      fillColor: theme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: theme.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _subgroupsTab(AppThemeConfig theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_subgroups.length} subgroups',
                style: GoogleFonts.lexend(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_isAdmin)
              TextButton.icon(
                onPressed: () => _showCreateSubgroupSheet(theme),
                icon: Icon(Icons.add, color: theme.primary),
                label: Text('Create', style: TextStyle(color: theme.primary)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_subgroups.isEmpty)
          _infoCard(
            theme,
            title: 'No subgroups yet',
            child: Text(
              'Create focused spaces for bike types, city chapters, coffee meetups, or build diaries.',
              style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.68),
                height: 1.35,
              ),
            ),
          )
        else
          ..._subgroups.map(
            (subgroup) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.textPrimary.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subgroup['name']?.toString() ?? 'Subgroup',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${subgroup['memberCount'] ?? 0} members',
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: _canOpenSubgroup(subgroup)
                        ? () {
                            setState(() => _selectedTab = 2);
                            _openChannel(
                              subgroup['uuid'].toString(),
                              subgroup['name']?.toString() ?? 'Subgroup',
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primary.withValues(alpha: 0.18),
                      foregroundColor: theme.primary,
                    ),
                    child: Text(
                      _canOpenSubgroup(subgroup)
                          ? 'Open chat'
                          : 'Admin adds members',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _channelChip(AppThemeConfig theme, String channelUuid, String label) {
    final selected = _activeChannelUuid == channelUuid;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _openChannel(channelUuid, label),
      selectedColor: theme.primary,
      backgroundColor: theme.surface,
      labelStyle: TextStyle(
        color: selected
            ? (theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white)
            : theme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoCard(
    AppThemeConfig theme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _statCard(
    AppThemeConfig theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.64)),
          ),
        ],
      ),
    );
  }
}
