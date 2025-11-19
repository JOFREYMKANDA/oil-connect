import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/screens/aboutUs_screen.dart';
import 'package:oil_connect/screens/customerSupport_screen.dart';
import 'package:oil_connect/screens/profile_screen.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck%20registration/truck_list.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/screens/settings_screens.dart';
import 'package:oil_connect/screens/customer%20screens/orders.dart';

class CustomerDrawer extends StatelessWidget {
  final String role; // Add role parameter

  const CustomerDrawer({super.key, required this.role}); // Require role

  void _showLogoutDialog() {
    Get.dialog(
      PopScope(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            "Are you sure you want to logout?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            //cancel button
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (_, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: OutlinedButton(
                onPressed: () { 
                  Get.back();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text(
                  "No",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16,),
            
            //Logging out accept
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.8, end: 1.0),
              builder: (_, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await Get.find<RegisterController>().logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text(
                  "Yes, logout",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54.withOpacity(0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Profile
                _buildDrawerItem(
                  icon: Icons.person_outlined,
                  title: "Profile",
                  subtitle: "Manage your account", 
                  onTap: () {
                    Get.to(() => ProfileScreen(role: role));
                  },
                ),

                // History
                _buildDrawerItem(
                  icon: Icons.history,
                  title: "History",
                  subtitle: "View past requests",
                  onTap: () {
                    Get.to(() => const OrderScreen());
                  },
                ),

                // Settings
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  subtitle: "App preferences",
                  onTap: () {
                    Get.to(() => SettingsScreen());
                  },
                ),

               // ✅ Role-based extra menu item
                if (role == 'TruckOwner')
                  _buildDrawerItem(
                    icon: Icons.local_shipping_outlined,
                    title: "My Trucks",
                    subtitle: "Manage your fleet",
                    onTap: () {
                      Get.to(() => const TruckListScreen()); // Truck owner-specific screen
                    },
                  ),

                // Customer Support
                _buildDrawerItem(
                  icon: Icons.headset_mic_outlined,
                  title: "Customer Support",
                  subtitle: "Get help & support",
                  onTap: () {
                    Get.to(() => const SupportScreen()); // ✅ Open Support Screen First
                  },
                ),

                // About Us
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: "About Us",
                  subtitle: "Learn more about us",
                  onTap: () {
                    Get.to(() => const AboutUsScreen());
                  },
                ),
              ],
            ),
          ),

          const Divider(thickness: 5,height: 1, color: AppColors.borderColor,),

          // Logout
          _buildLogoutItem(),
        ],
      ),
    );
  }

  /// **Builds the Drawer Header**
  Widget _buildDrawerHeader() {
    return GetBuilder<RegisterController>(
      builder: (controller) {
        final user = controller.user.value;
        final profileImage = user?.profileImage;
        final firstName = user?.firstname ?? 'User';
        final lastName = user?.lastname ?? '';
        final userRole = user?.role ?? role;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 20, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.rectangleColor,
                AppColors.rectangleColor.withOpacity(0.8),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.avatarPlaceholder,
                    backgroundImage: profileImage != null && profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null || profileImage.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.rectangleColor,
                          )
                        : null,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User Name
              Center(
                child: Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User Role Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatRole(userRole),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// **Builds each drawer item**
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.black87,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        subtitle: Text(
          subtitle!,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelTextColor,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.unselectedNavItemColor,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

   /// **Builds the logout item with modern styling**
  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.logoutButtonColor.withOpacity(0.1),
        border: Border.all(
          color: AppColors.logoutButtonColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.logoutButtonColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child:const Icon(
            Icons.logout,
            color: AppColors.logoutButtonColor,
            size: 22,
          ),
        ),
        title: const Text(
          "Log out",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.logoutButtonColor,
          ),
        ),
        subtitle: const Text(
          "Sign out of your account",
          style: TextStyle(
            fontSize: 13,
            color: AppColors.labelTextColor,
          ),
        ),
        onTap: _showLogoutDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// **Formats the user role for display**
  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'driver':
        return 'Driver';
      case 'truckowner':
        return 'Truck Owner';
      case 'admin':
        return 'Administrator';
      case 'staff':
        return 'Staff Member';
      default:
        return role;
    }
  }
}