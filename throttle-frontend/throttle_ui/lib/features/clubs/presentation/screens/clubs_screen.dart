import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/clubs/data/services/club_service.dart';
import 'package:throttle_ui/features/clubs/presentation/screens/club_chat_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _creating = false;
  List<Map<String, dynamic>> _myClubs = [];
  List<Map<String, dynamic>> _discoverClubs = [];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs([String query = '']) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ClubService.fetchMyClubs(),
        ClubService.discoverClubs(query),
      ]);

      if (!mounted) return;
      setState(() {
        _myClubs = results[0];
        _discoverClubs = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(e, isError: true);
    }
  }

  Future<void> _joinClub(String clubUuid) async {
    try {
      await ClubService.joinClub(clubUuid);
      await _loadClubs(_searchController.text);
      if (!mounted) return;
      _showMessage('Joined club successfully');
    } catch (e) {
      _showMessage(e, isError: true);
    }
  }

  Future<void> _openClub(String clubUuid) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubChatScreen(clubUuid: clubUuid)),
    );
    if (!mounted) return;
    await _loadClubs(_searchController.text);
  }

  void _showMessage(Object error, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _showCreateClubSheet(AppThemeConfig theme) async {
    final nameController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

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
                _showMessage('Club name is required', isError: true);
                return;
              }

              setSheetState(() => _creating = true);
              try {
                final club = await ClubService.createClub({
                  'name': name,
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
                if (!mounted) return;
                navigator.pop();
                await _loadClubs(_searchController.text);
                if (!mounted) return;
                await _openClub(club['uuid'].toString());
              } catch (e) {
                if (!mounted) return;
                _showMessage(e, isError: true);
              } finally {
                if (mounted) {
                  setSheetState(() => _creating = false);
                }
              }
            }

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
                  Text(
                    'Create club',
                    style: GoogleFonts.lexend(
                      color: theme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Build a persistent community for riders around a shared interest.',
                    style: TextStyle(
                      color: theme.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sheetField(
                    controller: nameController,
                    label: 'Club name',
                    hint: 'Iron Riders',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    controller: titleController,
                    label: 'Tagline',
                    hint: 'Weekend machines. Everyday stories.',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    controller: descriptionController,
                    label: 'Description',
                    hint: 'Tell riders what this club is about.',
                    maxLines: 4,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _creating ? null : submit,
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
                      child: _creating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Club'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    titleController.dispose();
    descriptionController.dispose();
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppThemeConfig theme,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.45),
            ),
            filled: true,
            fillColor: theme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.textPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final textColor = theme.textPrimary;
        final myClubIds = _myClubs
            .map((club) => club['uuid']?.toString() ?? '')
            .where((uuid) => uuid.isNotEmpty)
            .toSet();
        final discoverClubs = _discoverClubs
            .where((club) => !myClubIds.contains(club['uuid']?.toString()))
            .toList();

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _loadClubs(_searchController.text),
              color: theme.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primary.withValues(alpha: 0.18),
                          theme.secondary.withValues(alpha: 0.12),
                          theme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Clubs',
                                style: GoogleFonts.lexend(
                                  color: textColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () => _showCreateClubSheet(theme),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor:
                                    theme.brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Persistent communities for riders, conversations, and interest-based subgroups.',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: _loadClubs,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Search clubs',
                            hintStyle: TextStyle(
                              color: textColor.withValues(alpha: 0.42),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.primary,
                            ),
                            filled: true,
                            fillColor: theme.background.withValues(alpha: 0.88),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle(
                    theme,
                    'Your clubs',
                    '${_myClubs.length} joined',
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    _loadingState(theme)
                  else if (_myClubs.isEmpty)
                    _emptyCard(
                      theme,
                      'No clubs yet',
                      'Create your first club or join one from the discovery list below.',
                    )
                  else
                    ..._myClubs.map(
                      (club) => _clubCard(
                        theme,
                        club,
                        actionLabel: 'Open',
                        onAction: () => _openClub(club['uuid'].toString()),
                        onTap: () => _openClub(club['uuid'].toString()),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _sectionTitle(
                    theme,
                    'Discover',
                    '${discoverClubs.length} communities',
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const SizedBox.shrink()
                  else if (discoverClubs.isEmpty)
                    _emptyCard(
                      theme,
                      'No clubs found',
                      'Try a different search term or create a new club.',
                    )
                  else
                    ...discoverClubs.map(
                      (club) => _clubCard(
                        theme,
                        club,
                        actionLabel: 'Join',
                        onAction: () => _joinClub(club['uuid'].toString()),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(AppThemeConfig theme, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lexend(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.58),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _loadingState(AppThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator(color: theme.primary)),
    );
  }

  Widget _emptyCard(AppThemeConfig theme, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.62),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubCard(
    AppThemeConfig theme,
    Map<String, dynamic> club, {
    required String actionLabel,
    required VoidCallback onAction,
    VoidCallback? onTap,
  }) {
    final name = (club['name'] ?? 'Club').toString();
    final title = (club['title'] ?? '').toString();
    final description = (club['description'] ?? '').toString();
    final memberCount = (club['memberCount'] ?? 0).toString();
    final subgroupCount = (club['subgroupCount'] ?? 0).toString();
    final initials = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0].toUpperCase())
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.textPrimary.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.95),
                    theme.secondary.withValues(alpha: 0.78),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isEmpty ? 'CL' : initials,
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.68),
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metricChip(theme, '$memberCount members'),
                      _metricChip(theme, '$subgroupCount subgroups'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(AppThemeConfig theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textPrimary.withValues(alpha: 0.72),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
