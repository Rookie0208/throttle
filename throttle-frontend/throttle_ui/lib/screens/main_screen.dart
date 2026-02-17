import 'package:flutter/material.dart';
import 'package:throttle_ui/screens/group-screen.dart';
import 'package:throttle_ui/screens/plan_ride_screen.dart';
import 'package:throttle_ui/screens/profile_screen.dart';
import 'package:throttle_ui/services/auth_service.dart';
import 'dashboard_screen.dart';
import 'placeholder_screen.dart'; // For other tabs

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const GroupsScreen(),
    const PlaceholderScreen(label: "Track"),
    const PlaceholderScreen(label: "Stats"),
    const ProfileScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
          BottomNavigationBarItem(icon: Icon(Icons.navigation), label: "Track"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () async {
          final token = await AuthService.getToken(); // await the Future
  if (token == null) {
    // Handle missing token, maybe ask user to login again
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Token not found. Please login again.")),
    );
    return;
  }
          // Navigate to PlanRideScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlanRideScreen(token: token)),
          );
        },
      ),
    );
  }
}
