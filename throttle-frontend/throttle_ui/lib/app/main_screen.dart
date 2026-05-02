import 'package:flutter/material.dart';
import 'package:throttle_ui/features/clubs/presentation/screens/clubs_screen.dart';
import 'package:throttle_ui/features/profile/presentation/screens/friends_screen.dart';
import 'package:throttle_ui/features/groups/presentation/screens/groups_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/plan_ride_screen.dart';
import 'package:throttle_ui/features/profile/presentation/screens/profile_screen.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/resources/frontend_resource_config.dart';
import 'package:throttle_ui/features/dashboard/presentation/screens/dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _currentTabId = 'dashboard';
  String? _token;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await AuthService.getToken();
    Map<String, dynamic>? userData;

    if (token != null) {
      userData = await UserService.getMe();
    }

    setState(() {
      _token = token;
      _userData = userData;
      _isLoading = false;
    });
  }

  List<FrontendNavigationTabResource> get _visibleTabs {
    final tabs =
        FrontendResourceConfig.instance.navigation.tabs
            .where((tab) => tab.enabled && _screenBuilders.containsKey(tab.id))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return tabs;
  }

  Map<String, Widget Function()> get _screenBuilders => {
    'dashboard': () => DashboardScreen(userData: _userData, token: _token!),
    'rides': () => GroupsScreen(token: _token!),
    'clubs': () => const ClubsScreen(),
    'friends': () => const FriendsScreen(),
    'profile': () => ProfileScreen(userData: _userData),
  };

  void _onTabChanged(List<FrontendNavigationTabResource> tabs, int index) {
    if (index < 0 || index >= tabs.length) return;
    setState(() {
      _currentTabId = tabs[index].id;
    });
  }

  void _ensureActiveTab(List<FrontendNavigationTabResource> tabs) {
    if (tabs.isEmpty) return;
    final hasActive = tabs.any((tab) => tab.id == _currentTabId);
    if (!hasActive) {
      _currentTabId = tabs.first.id;
    }
  }

  Future<void> _openCreateRideSheet() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return PlanRideScreen(token: _token!);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        FrontendResourceConfig.instance,
      ]),
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        if (_token == null) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: Text(
                "Session expired. Please login again.",
                style: TextStyle(color: theme.textPrimary),
              ),
            ),
          );
        }

        final tabs = _visibleTabs;
        if (tabs.isEmpty) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Center(
              child: Text(
                'No navigation items are enabled in the frontend resource config.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textPrimary),
              ),
            ),
          );
        }

        _ensureActiveTab(tabs);
        final selectedIndex = tabs.indexWhere((tab) => tab.id == _currentTabId);
        final screens = tabs
            .map((tab) => _screenBuilders[tab.id]!())
            .toList(growable: false);
        final navActions = FrontendResourceConfig.instance.navigation.actions;

        return Scaffold(
          backgroundColor: theme.background,
          body: IndexedStack(index: selectedIndex, children: screens),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onTabChanged(tabs, index),
                destinations: tabs
                    .map(
                      (tab) => NavigationDestination(
                        icon: Icon(
                          FrontendResourceConfig.resolveIcon(tab.icon),
                        ),
                        selectedIcon: Icon(
                          FrontendResourceConfig.resolveIcon(tab.selectedIcon),
                        ),
                        label: tab.label,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          floatingActionButton: navActions.createRideFabEnabled
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    highlightElevation: 0,
                    onPressed: _openCreateRideSheet,
                    child: Icon(
                      FrontendResourceConfig.resolveIcon(
                        navActions.createRideFabIcon,
                      ),
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
