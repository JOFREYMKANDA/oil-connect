import 'package:flutter/material.dart';
import 'package:oil_connect/screens/customer%20screens/dashboard.dart';
import 'package:oil_connect/screens/customer%20screens/orders.dart';
import 'package:oil_connect/screens/driver%20screens/driver_order.dart';
import 'package:oil_connect/screens/driver%20screens/driver_screen.dart';
import 'package:oil_connect/screens/profile_screen.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck_owner_dashboard.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck_owner_order.dart';
import 'package:oil_connect/utils/colors.dart';

class RoleBasedBottomNavScreen extends StatefulWidget {
  final String role;

  const RoleBasedBottomNavScreen({super.key, required this.role});

  @override
  _RoleBasedBottomNavScreenState createState() =>
      _RoleBasedBottomNavScreenState();
}

class _RoleBasedBottomNavScreenState extends State<RoleBasedBottomNavScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    print(
        '🔍 [DEBUG] RoleBasedBottomNavScreen - Received role: ${widget.role}');
    print(
        '🔍 [DEBUG] RoleBasedBottomNavScreen - Role type: ${widget.role.runtimeType}');
    _screens = _buildScreens(widget.role);
    print(
        '🔍 [DEBUG] RoleBasedBottomNavScreen - Built ${_screens.length} screens for role: ${widget.role}');
    _pageController = PageController(initialPage: _selectedIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  List<Widget> _buildScreens(String role) {
    print('🔍 [DEBUG] _buildScreens - Processing role: "$role"');
    print('🔍 [DEBUG] _buildScreens - Role length: ${role.length}');
    print(
        '🔍 [DEBUG] _buildScreens - Role == "Customer": ${role == 'Customer'}');
    print('🔍 [DEBUG] _buildScreens - Role == "Driver": ${role == 'Driver'}');
    print(
        '🔍 [DEBUG] _buildScreens - Role == "TruckOwner": ${role == 'TruckOwner'}');

    if (role == 'Customer') {
      print('🔍 [DEBUG] _buildScreens - Building Customer screens');
      return [
        const CustomerDashboard(),
        const OrderScreen(),
        ProfileScreen(role: 'Customer'),
      ];
    } else if (role == 'Driver') {
      print('🔍 [DEBUG] _buildScreens - Building Driver screens');
      return [
        const DriverScreen(),
        DriverOrdersScreen(),
        ProfileScreen(role: 'Driver'),
      ];
    } else if (role == 'TruckOwner') {
      print('🔍 [DEBUG] _buildScreens - Building TruckOwner screens');
      return [
        const TruckOwnerDashboardScreen(),
        const TruckOwnerOrdersScreen(),
        ProfileScreen(role: 'TruckOwner'),
      ];
    } else {
      print(
          '🔍 [DEBUG] _buildScreens - Unknown role, defaulting to Customer screens');
      print(
          '⚠️ [DEBUG] _buildScreens - Role "$role" did not match any known role');
      print(
          '⚠️ [DEBUG] _buildScreens - Expected roles: Customer, Driver, TruckOwner');
      print('⚠️ [DEBUG] _buildScreens - Role length: ${role.length}');
      print('⚠️ [DEBUG] _buildScreens - Role bytes: ${role.codeUnits}');
      return [
        const CustomerDashboard(),
        const OrderScreen(),
        ProfileScreen(role: 'Customer'),
      ];
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    //Animation with bounce effect
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    //Navigate instantly with smooth navigation
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          // If not on Home, go to Home instead of exiting
          _onItemTapped(0);
          return false;
        }
        return true; // Allow app to close if on Home
      },
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     blurRadius: 20,
        //     offset: const Offset(0, -5),
        //   ),
        // ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
              ),
              Expanded(
                child: _buildNavItem(1, Icons.receipt_long_outlined,
                    Icons.receipt_long, "Orders"),
              ),
              Expanded(
                child: _buildNavItem(
                    2, Icons.person_outlined, Icons.person, "Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: isSelected ? 300 : 200),
                curve: isSelected ? Curves.elasticOut : Curves.easeInOut,
                tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isSelected ? selectedIcon : unselectedIcon,
                        key: ValueKey<String>(label),
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.unselectedNavItemColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.unselectedNavItemColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
