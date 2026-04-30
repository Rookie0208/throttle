import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  static const int _maxContacts = 3;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _contacts = [];

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
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserService.getMe();
    final contacts = (profile?['emergencyContacts'] as List?) ?? const [];

    _contacts
      ..clear()
      ..addAll(
        contacts.whereType<Map>().map(
          (contact) => {
            'name': (contact['name'] ?? '').toString(),
            'relation': (contact['relation'] ?? '').toString(),
            'phoneNumber': (contact['phoneNumber'] ?? '').toString(),
          },
        ),
      );

    if (!mounted) return;
    setState(() => _isLoading = false);
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

  Future<void> _persistContacts(List<Map<String, dynamic>> contacts) async {
    setState(() => _isSaving = true);
    final success = await UserService.updateProfile({
      'emergencyContacts': contacts,
    });
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Emergency contacts updated.'
              : 'Failed to save emergency contacts.',
        ),
      ),
    );
  }

  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contacts.length >= _maxContacts) return;

    final updatedContacts = [
      ..._contacts,
      {
        'name': _nameController.text.trim(),
        'relation': _relationController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      },
    ];

    await _persistContacts(updatedContacts);
    if (!mounted) return;
    if (_isSaving) return;

    setState(() {
      _contacts
        ..clear()
        ..addAll(updatedContacts);
      _nameController.clear();
      _relationController.clear();
      _phoneController.clear();
    });
  }

  Future<void> _removeContact(int index) async {
    final updatedContacts = [..._contacts]..removeAt(index);
    await _persistContacts(updatedContacts);
    if (!mounted) return;
    if (_isSaving) return;

    setState(() {
      _contacts
        ..clear()
        ..addAll(updatedContacts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        final theme = _themeController.theme;
        final canAddMore = _contacts.length < _maxContacts;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textPrimary),
            title: Text(
              'Emergency Contacts',
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Add up to 3 people we can reach during an emergency.',
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                canAddMore
                                    ? 'Contact ${_contacts.length + 1}'
                                    : 'All 3 contacts added',
                                style: GoogleFonts.lexend(
                                  color: theme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                canAddMore
                                    ? 'Save this contact to unlock the next slot.'
                                    : 'You have reached the emergency contact limit.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.65,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nameController,
                                enabled: canAddMore && !_isSaving,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: _decoration(
                                  theme,
                                  'Name',
                                  'Enter full name',
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Name is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _relationController,
                                enabled: canAddMore && !_isSaving,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: _decoration(
                                  theme,
                                  'Relation',
                                  'Parent, sibling, spouse',
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Relation is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                enabled: canAddMore && !_isSaving,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: theme.textPrimary),
                                decoration: _decoration(
                                  theme,
                                  'Phone Number',
                                  'Enter contact number',
                                ),
                                validator: (value) {
                                  final phone = (value ?? '').trim();
                                  if (phone.isEmpty) {
                                    return 'Phone number is required.';
                                  }
                                  if (phone.length < 7) {
                                    return 'Enter a valid phone number.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: canAddMore && !_isSaving
                                      ? _addContact
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    _isSaving ? 'Saving...' : 'Save Contact',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Saved Contacts',
                        style: GoogleFonts.lexend(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_contacts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Text(
                            'No emergency contacts saved yet.',
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.textPrimary.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      for (var index = 0; index < _contacts.length; index++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x52B8C6DA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_contacts[index]['name'] ?? '')
                                          .toString(),
                                      style: GoogleFonts.lexend(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_contacts[index]['relation'] ?? '')
                                          .toString(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (_contacts[index]['phoneNumber'] ?? '')
                                          .toString(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => _removeContact(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
