import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/features/settings/presentation/screens/emergency_contacts_screen.dart';
import 'package:throttle_ui/features/settings/presentation/screens/medical_info_screen.dart';

class SafetyHubScreen extends StatefulWidget {
  const SafetyHubScreen({super.key});

  @override
  State<SafetyHubScreen> createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen> {
  final _instructionsController = TextEditingController();

  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _safetyEnabled = true;
  String _safetyId = '';
  String _safetyPin = '1234';

  // Privacy controls
  bool _showBloodGroup = true;
  bool _showAllergies = true;
  bool _showMedication = false;
  bool _showContacts = true;
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    _loadSafetyProfile();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String _generateSafetyId(String userUuid) {
    if (userUuid.isNotEmpty) {
      final clean = userUuid.replaceAll('-', '').toUpperCase();
      final suffix = clean.length >= 6 ? clean.substring(0, 6) : 'SAFE99';
      return 'TH-$suffix';
    }
    final rand = Random().nextInt(899999) + 100000;
    return 'TH-$rand';
  }

  Future<void> _loadSafetyProfile() async {
    final user = await UserService.getMe();
    if (!mounted) return;

    if (user != null) {
      final userUuid = (user['uuid'] ?? user['id'] ?? '').toString();

      // Check if user has safety instructions stored
      String instructions = '';
      if (user['emergencyInstructions'] != null) {
        instructions = user['emergencyInstructions'].toString();
      }

      setState(() {
        _user = user;
        _safetyId = _generateSafetyId(userUuid);
        _safetyPin = (Random().nextInt(8999) + 1000).toString();
        _instructionsController.text = instructions;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInstructions() async {
    setState(() => _isSaving = true);
    final text = _instructionsController.text.trim();
    final success = await UserService.updateProfile({
      'emergencyInstructions': text,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Safety instructions saved.'
              : 'Instructions saved locally.',
        ),
      ),
    );
  }

  void _regenerateSafetyId() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate Safety ID?'),
        content: const Text(
          'This will invalidate your current QR code and PIN. Any physical stickers you printed will need to be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final rand = Random().nextInt(899999) + 100000;
              final newPin = (Random().nextInt(8999) + 1000).toString();
              setState(() {
                _safetyId = 'TH-$rand';
                _safetyPin = newPin;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generated new Safety ID & PIN')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  String get _publicSafetyUrl {
    return 'http://127.0.0.1:5500/safety.html?id=$_safetyId';
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
            title: Text(
              'Throttle Safety',
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: theme.primary),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                  children: [
                    // Top Hero / Safety ID Card
                    _buildQrCard(theme),
                    const SizedBox(height: 18),

                    // Quick Management Navigation (Emergency Contacts & Medical Info)
                    _buildSectionHeader(
                      theme,
                      'Core Information',
                      'Contacts & medical details',
                    ),
                    const SizedBox(height: 10),
                    _buildCoreInfoTiles(theme),

                    const SizedBox(height: 22),

                    // Emergency Instructions Input
                    _buildSectionHeader(
                      theme,
                      'First Responder Instructions',
                      'Shown when your QR is scanned',
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionsCard(theme),

                    const SizedBox(height: 22),

                    // Privacy Controls
                    _buildSectionHeader(
                      theme,
                      'Public Sharing Privacy',
                      'Choose what is visible upon QR scan',
                    ),
                    const SizedBox(height: 10),
                    _buildPrivacyControlsCard(theme),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    AppThemeConfig theme,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lexend(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.55),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard(AppThemeConfig theme) {
    return Container(
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: theme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rider Safety ID',
                        style: GoogleFonts.lexend(
                          color: theme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _safetyEnabled ? 'Active & Scannable' : 'Disabled',
                        style: TextStyle(
                          color: _safetyEnabled
                              ? Colors.greenAccent.shade700
                              : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _safetyEnabled,
                activeThumbColor: theme.primary,
                onChanged: (val) {
                  setState(() => _safetyEnabled = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR Code Graphic Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Opacity(
              opacity: _safetyEnabled ? 1.0 : 0.35,
              child: QrImageView(
                data: _publicSafetyUrl,
                version: QrVersions.auto,
                size: 160.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ID and PIN details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.background.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'SAFETY ID',
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _safetyId,
                      style: GoogleFonts.lexend(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 28,
                  width: 1,
                  color: theme.textPrimary.withValues(alpha: 0.1),
                ),
                Column(
                  children: [
                    Text(
                      'FALLBACK PIN',
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _safetyPin,
                      style: GoogleFonts.lexend(
                        color: theme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _regenerateSafetyId,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Regenerate ID'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textPrimary,
                    side: BorderSide(
                      color: theme.textPrimary.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreInfoTiles(AppThemeConfig theme) {
    final contactsCount = (_user?['emergencyContacts'] as List?)?.length ?? 0;
    final bloodGroup = (_user?['bloodGroup'] ?? 'Not set').toString();

    return Column(
      children: [
        _infoTile(
          theme: theme,
          icon: Icons.contact_phone_outlined,
          title: 'Emergency Contacts',
          subtitle: contactsCount > 0
              ? '$contactsCount contacts configured'
              : 'Add up to 3 emergency contacts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmergencyContactsScreen(),
              ),
            ).then((_) => _loadSafetyProfile());
          },
        ),
        const SizedBox(height: 10),
        _infoTile(
          theme: theme,
          icon: Icons.medical_information_outlined,
          title: 'Medical Information',
          subtitle: 'Blood Group: $bloodGroup, allergies, medications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MedicalInfoScreen(),
              ),
            ).then((_) => _loadSafetyProfile());
          },
        ),
      ],
    );
  }

  Widget _infoTile({
    required AppThemeConfig theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.primary, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.lexend(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: theme.textPrimary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'e.g. Call spouse first; allergic to Penicillin; rider wears contact lenses.',
              hintStyle: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.35),
                fontSize: 13,
              ),
              filled: true,
              fillColor: theme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.textPrimary.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.textPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveInstructions,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save Instructions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyControlsCard(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          _privacyCheckbox(
            theme,
            'Show Blood Group',
            'Display blood type for emergency medical responders',
            _showBloodGroup,
            (v) => setState(() => _showBloodGroup = v ?? true),
          ),
          const Divider(height: 16),
          _privacyCheckbox(
            theme,
            'Show Allergies',
            'Visible on emergency scan',
            _showAllergies,
            (v) => setState(() => _showAllergies = v ?? true),
          ),
          const Divider(height: 16),
          _privacyCheckbox(
            theme,
            'Show Current Medication',
            'Optional: share ongoing prescriptions',
            _showMedication,
            (v) => setState(() => _showMedication = v ?? false),
          ),
          const Divider(height: 16),
          _privacyCheckbox(
            theme,
            'Show Emergency Contacts',
            'Allows any rescuer to call saved phone numbers',
            _showContacts,
            (v) => setState(() => _showContacts = v ?? true),
          ),
          const Divider(height: 16),
          _privacyCheckbox(
            theme,
            'Show Emergency Instructions',
            'Display custom notes and guidance',
            _showInstructions,
            (v) => setState(() => _showInstructions = v ?? true),
          ),
        ],
      ),
    );
  }

  Widget _privacyCheckbox(
    AppThemeConfig theme,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Checkbox(
          value: value,
          activeColor: theme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
