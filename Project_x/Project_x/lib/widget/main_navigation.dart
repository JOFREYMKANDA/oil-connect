 import 'package:flutter/material.dart';
 import 'package:oil_connect/screens/truck%20owner%20screens/truck_owner_dashboard.dart';

 class MainNavigation extends StatefulWidget {
   const MainNavigation({super.key});

   @override
   _MainNavigationState createState() => _MainNavigationState();
 }

 class _MainNavigationState extends State<MainNavigation> {
   int _currentIndex = 0;
   late PageController _pageController;

   final List<Widget> _screens = [
     const TruckOwnerDashboardScreen(),
     //LoanScreen(),
     //ProfileScreen(),
   ];

   @override
   void initState() {
     super.initState();
     _pageController = PageController();
   }

   @override
   void dispose() {
     _pageController.dispose();
     super.dispose();
   }

   void _onTap(int index) {
     setState(() {
       _currentIndex = index;
       _pageController.animateToPage(
         index,
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeInOut,
       );
     });
   }
   void _onPageChanged(int index) {
     setState(() {
       _currentIndex = index;
     });
   }
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: PageView(
         controller: _pageController,
         onPageChanged: _onPageChanged,
         physics: const BouncingScrollPhysics(),
         children: _screens, // Optional: Add scroll physics
       ),
       bottomNavigationBar: BottomNavigationBar(
         currentIndex: _currentIndex,
         onTap: _onTap,
         items: const [
           BottomNavigationBarItem(
             icon: Icon(Icons.dashboard),
             label: 'Dashboard',
           ),
           // Add more items as needed
         ],
       ),
     );
   }
}
