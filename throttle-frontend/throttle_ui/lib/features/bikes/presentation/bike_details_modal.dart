import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/bikes/presentation/bike_display_formatters.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/core/utils/app_feedback.dart';

class BikeDetailsModal extends StatefulWidget {
  final Map<String, dynamic> bike;
  final Map<String, dynamic>? userData;
  final VoidCallback onBikeUpdated;

  const BikeDetailsModal({
    super.key,
    required this.bike,
    this.userData,
    required this.onBikeUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> bike,
    Map<String, dynamic>? userData,
    required VoidCallback onBikeUpdated,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BikeDetailsModal(
        bike: bike,
        userData: userData,
        onBikeUpdated: onBikeUpdated,
      ),
    );
  }

  @override
  State<BikeDetailsModal> createState() => _BikeDetailsModalState();
}

class _BikeDetailsModalState extends State<BikeDetailsModal> {
  bool _isLoading = false;

  Map<String, dynamic> get _bike => widget.bike;
  bool get _isPrimary => (_bike['primary'] ?? false) == true;
  bool get _isVerified => (_bike['verified'] ?? false) == true;

  int? get _bikeId => int.tryParse((_bike['id'] ?? '').toString());

  // Derive ride stats for this bike
  // If user has totalKm or totalRides, primary bike displays primary journey share
  Map<String, dynamic> _getJourneyStats() {
    final totalKm =
        (widget.userData?['totalKm'] as num?)?.toDouble() ??
        (widget.userData?['weeklyMiles'] as num?)?.toDouble() ??
        0.0;
    final totalRides = (widget.userData?['totalRides'] as num?)?.toInt() ?? 0;

    // Estimate based on primary status
    final bikeKm = _isPrimary ? totalKm : 0.0;
    final bikeTrips = _isPrimary ? totalRides : 0;

    return {
      'trips': bikeTrips,
      'km': bikeKm.toStringAsFixed(1),
    };
  }

  Future<void> _handleSetPrimary() async {
    if (_bikeId == null) {
      AppFeedback.showError('Unable to identify bike ID', context: context);
      return;
    }

    setState(() => _isLoading = true);
    final result = await UserService.setPrimaryBike(_bikeId!);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      AppFeedback.showSuccess(
        result['message'] ?? 'Set as primary bike',
        context: context,
      );
      Navigator.pop(context);
      widget.onBikeUpdated();
    } else {
      AppFeedback.showError(
        result['message'] ?? 'Failed to update primary bike',
        context: context,
      );
    }
  }

  Future<void> _handleDelete() async {
    if (_bikeId == null) {
      AppFeedback.showError('Unable to identify bike ID', context: context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = ThemeController.instance.theme;
        return AlertDialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Remove Bike',
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to remove this bike from your garage?',
            style: GoogleFonts.plusJakartaSans(
              color: theme.textPrimary.withValues(alpha: 0.75),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final result = await UserService.deleteBike(_bikeId!);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      AppFeedback.showSuccess(
        result['message'] ?? 'Bike removed',
        context: context,
      );
      Navigator.pop(context);
      widget.onBikeUpdated();
    } else {
      AppFeedback.showError(
        result['message'] ?? 'Failed to remove bike',
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance.theme;
    final title = BikeDisplayFormatters.title(_bike);
    final variant = (_bike['variant'] ?? '').toString().trim();
    final model = (_bike['model'] ?? '').toString().trim();
    final brand = (_bike['brand'] ?? _bike['make'] ?? '').toString().trim();
    final year = (_bike['year'] ?? '').toString().trim();
    final engineCc = (_bike['engineCc'] ?? '').toString().trim();
    final category = (_bike['category'] ?? '').toString().trim();
    final stats = _getJourneyStats();

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: theme.textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Bike Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: theme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : 'Bike Details',
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (_isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Primary Bike',
                                style: GoogleFonts.lexend(
                                  color: theme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isVerified
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _isVerified ? 'Verified' : 'Custom / Unverified',
                              style: GoogleFonts.lexend(
                                color: _isVerified
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Journeys Covered by that Bike
            Text(
              'Journeys Covered',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statMetricCard(
                    theme: theme,
                    icon: Icons.alt_route_rounded,
                    label: 'Trips Completed',
                    value: '${stats['trips']}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statMetricCard(
                    theme: theme,
                    icon: Icons.speed_rounded,
                    label: 'Distance Covered',
                    value: '${stats['km']} km',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Complete Technical Info
            Text(
              'Bike Specifications',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0x52B8C6DA).withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  _specRow(theme, 'Brand / Make', brand.isNotEmpty ? brand : '—'),
                  _divider(theme),
                  _specRow(theme, 'Model', model.isNotEmpty ? model : '—'),
                  _divider(theme),
                  _specRow(theme, 'Variant', variant.isNotEmpty ? variant : '—'),
                  _divider(theme),
                  _specRow(theme, 'Engine CC', engineCc.isNotEmpty && engineCc != '0' ? '$engineCc cc' : '—'),
                  _divider(theme),
                  _specRow(theme, 'Model Year', year.isNotEmpty ? year : '—'),
                  _divider(theme),
                  _specRow(theme, 'Category', category.isNotEmpty ? category.toUpperCase() : '—'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  if (!_isPrimary) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _handleSetPrimary,
                        icon: const Icon(Icons.star_rounded),
                        label: Text(
                          'Set as Primary Bike',
                          style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: Text(
                        'Delete Bike',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statMetricCard({
    required dynamic theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x52B8C6DA).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(dynamic theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontSize: 13.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(dynamic theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.textPrimary.withValues(alpha: 0.06),
    );
  }
}
