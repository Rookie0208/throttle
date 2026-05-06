import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:throttle_ui/features/clubs/presentation/screens/clubs_screen.dart';
import 'package:throttle_ui/features/profile/presentation/screens/friends_screen.dart';
import 'package:throttle_ui/features/groups/presentation/screens/groups_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/plan_ride_screen.dart';
import 'package:throttle_ui/features/profile/presentation/screens/profile_screen.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/permissions/presentation/widgets/location_permission_sheet.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/services/app_permission_service.dart';
import 'package:throttle_ui/features/dashboard/presentation/screens/dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _locationPromptSeenKey = 'location_permission_prompt_seen_v1';

  int _currentIndex = 0;
  String? _token;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isPromptingForPermissions = false;

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

    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePromptForLocationPermission();
      });
    }
  }

  Future<void> _maybePromptForLocationPermission() async {
    if (!mounted || _isPromptingForPermissions) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenPrompt = prefs.getBool(_locationPromptSeenKey) ?? false;
    final accessState = await AppPermissionService.getLocationAccessState();

    if (!mounted || accessState == LocationAccessState.granted) {
      return;
    }

    if (hasSeenPrompt &&
        accessState != LocationAccessState.deniedForever &&
        accessState != LocationAccessState.serviceDisabled) {
      return;
    }

    _isPromptingForPermissions = true;
    await prefs.setBool(_locationPromptSeenKey, true);
    if (!mounted) {
      _isPromptingForPermissions = false;
      return;
    }

    var currentState = accessState;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeController.instance.theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> refreshState() async {
              final nextState =
                  await AppPermissionService.getLocationAccessState();
              if (!mounted) {
                return;
              }
              setModalState(() {
                currentState = nextState;
              });
              if (nextState == LocationAccessState.granted && context.mounted) {
                Navigator.of(context).pop();
              }
            }

            return LocationPermissionSheet(
              state: currentState,
              onRequestPermission: () async {
                final nextState =
                    await AppPermissionService.requestLocationAccess();
                if (!context.mounted) {
                  return;
                }
                setModalState(() {
                  currentState = nextState;
                });
                if (nextState == LocationAccessState.granted) {
                  Navigator.of(context).pop();
                }
              },
              onOpenSettings: () async {
                if (currentState == LocationAccessState.serviceDisabled) {
                  await AppPermissionService.openLocationSettings();
                } else {
                  await AppPermissionService.openAppSettings();
                }
                await refreshState();
              },
            );
          },
        );
      },
    );

    _isPromptingForPermissions = false;
  }

  List<Widget> get _screens => [
    DashboardScreen(userData: _userData, token: _token!),
    GroupsScreen(token: _token!),
    const ClubsScreen(),
    const FriendsScreen(),
    ProfileScreen(userData: _userData),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
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
      listenable: ThemeController.instance,
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

        return Scaffold(
          backgroundColor: theme.background,
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabChanged,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard_rounded),
                    label: "Dashboard",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.two_wheeler_outlined),
                    selectedIcon: Icon(Icons.two_wheeler_rounded),
                    label: "Rides",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.groups_2_outlined),
                    selectedIcon: Icon(Icons.groups_2_rounded),
                    label: "Clubs",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.diversity_3_outlined),
                    selectedIcon: Icon(Icons.diversity_3_rounded),
                    label: "Friends",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Container(
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
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
