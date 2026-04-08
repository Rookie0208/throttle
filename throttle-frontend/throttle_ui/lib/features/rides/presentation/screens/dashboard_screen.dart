import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            centerTitle: false,
            title: Text(
              'Throttle',
              style: GoogleFonts.getFont(
                theme.headlineFontFamily ?? 'Manrope',
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: theme.textPrimary),
                onPressed: () {},
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=amit'),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildGreeting(theme),
                const SizedBox(height: 30),
                _buildStats(theme),
                const SizedBox(height: 40),
                _buildSectionHeader(theme, 'Upcoming Rides'),
                const SizedBox(height: 16),
                _buildRideCard(
                  theme,
                  'Sunday Morning Blast',
                  'Sunday, 15 Oct • 06:30 AM',
                  'Lonavala, MH',
                  8,
                ),
                const SizedBox(height: 16),
                _buildRideCard(
                  theme,
                  'Coastal Cruise',
                  'Saturday, 21 Oct • 05:00 AM',
                  'Alibaug, MH',
                  12,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: theme.primary,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        );
      },
    );
  }

  Widget _buildGreeting(AppThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, Amit!',
          style: GoogleFonts.getFont(
            theme.headlineFontFamily ?? 'Manrope',
            color: theme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready for your next adventure?',
          style: GoogleFonts.getFont(
            theme.fontFamily ?? 'Inter',
            color: theme.secondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AppThemeConfig theme) {
    return Row(
      children: [
        _statItem(theme, '1.2k', 'km ridden'),
        const SizedBox(width: 16),
        _statItem(theme, '24', 'rides'),
        const SizedBox(width: 16),
        _statItem(theme, '5', 'badges'),
      ],
    );
  }

  Widget _statItem(AppThemeConfig theme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.getFont(
                theme.headlineFontFamily ?? 'Manrope',
                color: theme.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.getFont(
                theme.fontFamily ?? 'Inter',
                color: theme.secondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppThemeConfig theme, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.getFont(
            theme.headlineFontFamily ?? 'Manrope',
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'See all',
          style: TextStyle(
            color: theme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(
    AppThemeConfig theme,
    String title,
    String time,
    String location,
    int riders,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.getFont(
                    theme.headlineFontFamily ?? 'Manrope',
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: theme.secondary, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          _rideDetail(theme, Icons.calendar_today, time),
          const SizedBox(height: 8),
          Row(
            children: [
              _rideDetail(theme, Icons.location_on, location),
              const Spacer(),
              _rideDetail(theme, Icons.people, '$riders riders'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rideDetail(AppThemeConfig theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: theme.tertiary, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.getFont(
            theme.fontFamily ?? 'Inter',
            color: theme.secondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}