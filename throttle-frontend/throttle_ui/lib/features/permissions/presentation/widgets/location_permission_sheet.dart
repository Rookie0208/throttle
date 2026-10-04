import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/services/app_permission_service.dart';

class LocationPermissionSheet extends StatelessWidget {
  final LocationAccessState state;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onOpenSettings;

  const LocationPermissionSheet({
    super.key,
    required this.state,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  String get _title {
    switch (state) {
      case LocationAccessState.serviceDisabled:
        return 'Turn on location services';
      case LocationAccessState.deniedForever:
        return 'Allow location from settings';
      case LocationAccessState.denied:
      case LocationAccessState.granted:
        return 'Allow location access';
    }
  }

  String get _description {
    switch (state) {
      case LocationAccessState.serviceDisabled:
        return 'Throttle uses your location for nearby rides, weather on the dashboard, and live ride navigation. Enable device location services, then come back here.';
      case LocationAccessState.deniedForever:
        return 'Location permission was blocked at the system level. Open app settings and allow location while using the app to unlock nearby rides and live tracking.';
      case LocationAccessState.denied:
      case LocationAccessState.granted:
        return 'Throttle needs location while you use the app so riders can see nearby rides, pick better meeting points, and track live rides on the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance.theme;
    final isSettingsAction =
        state == LocationAccessState.deniedForever ||
        state == LocationAccessState.serviceDisabled;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: theme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _title,
              style: GoogleFonts.lexend(
                color: theme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _description,
              style: GoogleFonts.plusJakartaSans(
                color: theme.textPrimary.withValues(alpha: 0.72),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(20),
                              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required now',
                    style: GoogleFonts.lexend(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location while using the app',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Needed for ride maps, route previews, nearby weather, and live navigation.',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.textPrimary.withValues(alpha: 0.68),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSettingsAction
                    ? onOpenSettings
                    : onRequestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(
                  isSettingsAction ? 'Open Settings' : 'Allow Location',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: GoogleFonts.lexend(
                    color: theme.textPrimary.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
