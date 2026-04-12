import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _premiumTheme = AppThemeConfig(
    preset: AppThemePreset.premiumConnectivity,
    label: "Premium Connectivity",
    primary: Color(0xff0047DE),
    secondary: Color(0xff3463F7),
    tertiary: Color(0xff4B600E),
    background: Color(0xffFAF9FF),
    surface: Color(0xffFFFFFF),
    textPrimary: Color(0xff191B22),
    brightness: Brightness.light,
    fontFamily: "Lexend",
    headlineFontFamily: "Lexend",
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final baseTheme = ThemeController.instance.theme;
        final theme = baseTheme.preset == AppThemePreset.premiumConnectivity
            ? baseTheme
            : _premiumTheme;

        final lowSurface = const Color(0xffF1F4FF);
        final lowestSurface = theme.surface;
        final glassSurface = theme.background.withValues(alpha: 0.8);
        final headlineStyle = GoogleFonts.lexend(
          color: theme.textPrimary,
          fontWeight: FontWeight.w700,
        );
        final bodyStyle = GoogleFonts.lexend(
          color: theme.textPrimary.withValues(alpha: 0.72),
        );

        return Scaffold(
          backgroundColor: theme.background,
          floatingActionButton: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xff0047DE), Color(0xff3463F7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {},
              icon: const Icon(Icons.navigation_rounded, color: Colors.white),
              label: Text(
                'Start Ride',
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffFAF9FF), Color(0xffEEF4FF)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: glassSurface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'KINETIC HORIZON',
                                      style: GoogleFonts.lexend(
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.62,
                                        ),
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Throttle',
                                      style: headlineStyle.copyWith(
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.notifications_none_rounded,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/150?u=amit',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connected to the road.',
                            style: headlineStyle.copyWith(
                              fontSize: 34,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Live telemetry, social ride planning, and a cockpit feel that stays light on its feet.',
                            style: bodyStyle.copyWith(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff0047DE), Color(0xff3463F7)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE RANGE',
                            style: GoogleFonts.lexend(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '164',
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontSize: 56,
                                  height: 0.92,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'km',
                                  style: GoogleFonts.lexend(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _metricPill('ECO MODE', const Color(0xffD2ED8D)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _telemetryValue(
                                  label: 'BATTERY',
                                  value: '82%',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _telemetryValue(
                                  label: 'AVG SPEED',
                                  value: '48',
                                  suffix: 'km/h',
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _tonalStatCard(
                            background: lowSurface,
                            accent: theme.tertiary,
                            title: 'TRIP ENERGY',
                            value: '5.4',
                            suffix: 'kWh',
                            textColor: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _tonalStatCard(
                            background: lowestSurface,
                            accent: theme.primary,
                            title: 'TYRE PRESS',
                            value: '34',
                            suffix: 'PSI',
                            textColor: theme.textPrimary,
                            ghostBorder: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Upcoming rides',
                              style: headlineStyle.copyWith(fontSize: 24),
                            ),
                          ),
                          Text(
                            'View map',
                            style: GoogleFonts.lexend(
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _rideCard(
                      theme: theme,
                      background: lowSurface,
                      title: 'Sunday Morning Blast',
                      time: 'Sunday, 15 Oct • 06:30 AM',
                      location: 'Lonavala, MH',
                      riders: '08 riders',
                      highlight: 'PACK LEAD',
                    ),
                    const SizedBox(height: 12),
                    _rideCard(
                      theme: theme,
                      background: lowestSurface,
                      title: 'Coastal Cruise',
                      time: 'Saturday, 21 Oct • 05:00 AM',
                      location: 'Alibaug, MH',
                      riders: '12 riders',
                      highlight: 'OPEN SLOT',
                      ghostBorder: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _telemetryValue({
    required String label,
    required String value,
    required Color color,
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            color: color.withValues(alpha: 0.72),
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.lexend(color: color),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (suffix.isNotEmpty)
                TextSpan(
                  text: ' $suffix',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricPill(String label, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.lexend(
          color: const Color(0xff2E3C08),
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tonalStatCard({
    required Color background,
    required Color accent,
    required String title,
    required String value,
    required String suffix,
    required Color textColor,
    bool ghostBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: ghostBorder
            ? Border.all(color: const Color(0xffB9C2DA).withValues(alpha: 0.15))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.bolt_rounded, color: accent, size: 18),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.lexend(
              color: textColor.withValues(alpha: 0.65),
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.lexend(color: textColor),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideCard({
    required AppThemeConfig theme,
    required Color background,
    required String title,
    required String time,
    required String location,
    required String riders,
    required String highlight,
    bool ghostBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: ghostBorder
            ? Border.all(color: const Color(0xffB9C2DA).withValues(alpha: 0.15))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    color: theme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _metricPill(highlight, const Color(0xffEAF0FF)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _rideMeta(theme, Icons.schedule_rounded, time),
              _rideMeta(theme, Icons.place_outlined, location),
              _rideMeta(theme, Icons.people_alt_outlined, riders),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rideMeta(AppThemeConfig theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.tertiary, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.lexend(
              color: theme.textPrimary.withValues(alpha: 0.72),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
