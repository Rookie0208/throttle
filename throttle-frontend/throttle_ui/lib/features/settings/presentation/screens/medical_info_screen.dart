import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final _formKey = GlobalKey<FormState>();
  final _allergiesController = TextEditingController();
  final _medicationController = TextEditingController();

  String? _selectedBloodGroup;
  bool _isLoading = true;
  bool _isSaving = false;

  ThemeController get _themeController => ThemeController.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.getMe();
    final bloodGroup = (profile?['bloodGroup'] ?? '').toString().trim();

    _selectedBloodGroup = _bloodGroups.contains(bloodGroup) ? bloodGroup : null;
    _allergiesController.text = (profile?['allergies'] ?? '').toString();
    _medicationController.text = (profile?['currentMedication'] ?? '')
        .toString();

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await UserService.updateProfile({
      'bloodGroup': _selectedBloodGroup,
      'allergies': _allergiesController.text.trim(),
      'currentMedication': _medicationController.text.trim(),
    });
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Medical info saved.' : 'Failed to save medical info.',
        ),
      ),
    );
    if (success) {
      Navigator.pop(context);
    }
  }

  InputDecoration _decoration(AppThemeConfig theme, String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: theme.textPrimary.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: theme.textPrimary.withValues(alpha: 0.35)),
      filled: true,
      fillColor: theme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        final theme = _themeController.theme;
        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textPrimary),
            title: Text(
              'Medical Info',
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Keep essential medical details ready for safer rides.',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.textPrimary.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedBloodGroup,
                                dropdownColor: theme.surface,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: _decoration(
                                  theme,
                                  'Blood Group',
                                  'Select blood group',
                                ),
                                items: _bloodGroups
                                    .map(
                                      (group) => DropdownMenuItem(
                                        value: group,
                                        child: Text(group),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedBloodGroup = value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Blood group is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _allergiesController,
                                minLines: 3,
                                maxLines: 5,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: _decoration(
                                  theme,
                                  'Allergies / Other',
                                  'Mention allergies or other key notes',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _medicationController,
                                minLines: 3,
                                maxLines: 5,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: _decoration(
                                  theme,
                                  'Current Medication',
                                  'Mention current medication details',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isSaving ? 'Saving...' : 'Save Medical Info',
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
}
