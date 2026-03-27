import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xfffe6603);
  static const background = Color(0xff0f1114);
  static const card = Color(0xff16181d);
  static const textSecondary = Colors.white70;
}

class BottomNav extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTabChange;

  const BottomNav({
    super.key,
    required this.activeIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          /// DASHBOARD
          _navItem(
            icon: Icons.dashboard_outlined,
            label: "Dashboard",
            index: 0,
          ),

          /// GROUPS
          _navItem(
            icon: Icons.group_outlined,
            label: "Groups",
            index: 1,
          ),

          /// TRACK (CENTER FLOATING)
          _centerTrackButton(),

          /// STATS
          _navItem(
            icon: Icons.people_outline,
            label: "Stats",
            index: 3,
          ),

          /// PROFILE
          _navItem(
            icon: Icons.person_outline,
            label: "Profile",
            index: 4,
          ),
        ],
      ),
    );
  }

  /// NORMAL NAV ITEM
  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = activeIndex == index;

    return GestureDetector(
      onTap: () => onTabChange(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// CENTER TRACK BUTTON
  Widget _centerTrackButton() {
    final bool isActive = activeIndex == 2;

    return GestureDetector(
      onTap: () => onTabChange(2),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Track",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            )
          ],
        ),
      ),
    );
  }
}
