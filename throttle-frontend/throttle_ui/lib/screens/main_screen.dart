import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/clubs_screen.dart';
import 'package:throttle_ui/screens/group-screen.dart';
import 'package:throttle_ui/screens/plan_ride_screen.dart';
import 'package:throttle_ui/screens/profile_screen.dart';
import 'package:throttle_ui/screens/stats_screen.dart';
import 'package:throttle_ui/services/auth_service.dart';
import 'dashboard_screen.dart';
import 'package:throttle_ui/services/user_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
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

  List<Widget> get _screens => [
    DashboardScreen(userData: _userData, token: _token!),
        GroupsScreen(token: _token!), // pass token here
        const ClubsScreen(),
        const StatsScreen(),
        ProfileScreen(userData: _userData),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Show loading while fetching token
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xff0f1114),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // 🔥 If token missing → force login logic (optional)
    if (_token == null) {
      return const Scaffold(
        backgroundColor: Color(0xff0f1114),
        body: Center(
          child: Text(
            "Session expired. Please login again.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff0f1114),
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff1a1c20),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.two_wheeler),
            label: "Rides",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Clubs"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlanRideScreen(token: _token!)),
          );
        },
      ),
    );
  }
}
