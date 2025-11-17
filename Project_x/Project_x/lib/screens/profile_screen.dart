import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/screens/customer%20screens/personalDetailsPage.dart';
import 'package:oil_connect/screens/customer%20screens/registered_station.dart';
import 'package:oil_connect/screens/settings_screens.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/url_utils.dart';
import 'package:oil_connect/utils/themes/theme_controller.dart';
import 'package:oil_connect/widget/AppBar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oil_connect/screens/personal_info.dart' as personal_info;
import 'package:oil_connect/screens/truck%20owner%20screens/truck%20registration/truck_list.dart';

class ProfileScreen extends StatelessWidget {
  final RegisterController userController = Get.put(RegisterController());
  final String role; // Add role parameter

  ProfileScreen({super.key, required this.role});

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
            const SizedBox(
              width: 16,
            ),

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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

  // Add this function to your class
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Theme.of(context).brightness == Brightness.dark
        //   ? const Color(0xFF121212)
        //   : const Color(0xFFF8F9FA),
        appBar: const BackAppBar(title: 'Account'),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Column(
                children: [
                  //Header
                  Container(
                    width: double.infinity,
                    // padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
                  ),

                  // const SizedBox(height: 20),

                  // _buildProfileHeader(context), // ✅ Pass context here
                  // const SizedBox(height: 24),

                  //Personal Info & Privacy section
                  _buildSection(context, "Settings", [
                    _buildProfileOption(
                      "Personal Info",
                      Icons.person,
                      const PersonalDetailsPage(),
                      onTap: () => Get.to(() =>const PersonalDetailsPage()),
                    ),
                    // _buildProfileOption(
                    //   "Password Update",
                    //   Icons.lock_reset,
                    //   SettingsScreen(),
                    //   onTap: () => Get.to(() => SettingsScreen()),
                    // ),
                    _buildProfileOption(
                      "Privacy Policy",
                      Icons.policy,
                      null,
                      onTap: () => _launchURL(
                          "https://www.ietf.org/policies/?utm_source=chatgpt.com"),
                    ),
                    _buildProfileOption(
                      "Term Of Use",
                      Icons.description,
                      null,
                      onTap: () => _launchURL(
                          "https://www.ietf.org/policies/?utm_source=chatgpt.com"),
                    ),
                    if (role == 'Customer')
                      _buildProfileOption(
                        "Stations",
                        Icons.local_gas_station,
                        RegisteredStationsScreen(),
                        onTap: () => Get.to(() => RegisteredStationsScreen())
                      ),
                    if (role == 'TruckOwner')
                      _buildProfileOption(
                        "Trucks",
                        Icons.local_shipping,
                        SettingsScreen(),
                        onTap: () => Get.to(() => const TruckListScreen()),
                      ),
                  ]),

                  _buildSection(context, "Actions", [
                    _buildProfileOption(
                      "Delete Account",
                      Icons.delete,
                      null,
                      onTap:     () {
                        //TODO: Implement a delete functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Delete account feature will be available soon"),
                            duration: Duration(seconds: 5),
                            backgroundColor: Colors.orange,
                          )
                        );
                      } ,
                    ),
                    _buildProfileOption(
                      "Logout",
                      Icons.logout,
                      null,
                      onTap:() async {
                        Get.back();
                        await Get.find<RegisterController>().logout();
                      },
                    ),
                  ]),

                  // ✅ Conditionally Render Group 2 (Saved Places)
                  // if (role == 'Customer')
                  //   _buildSection(
                  //     context,
                  //     "Stations",
                  //     [
                  //     _buildProfileOption(
                  //       "Registered Station",
                  //       Icons.local_gas_station_outlined,
                  //       RegisteredStationsScreen(),
                  //       "View your registered gas stations",
                  //       onTap: ()  => Get.to(() => RegisteredStationsScreen()),
                  //     ),
                  //     _buildProfileOption(
                  //       "Add Station",
                  //       Icons.add_business_outlined,
                  //       const StationRegistration(),
                  //       "Register a new gas station",
                  //       onTap: () => Get.to(() => const StationRegistration()),
                  //     ),
                  //   ]),
                  // if (role == 'TruckOwner')
                  //   _buildSection(context,
                  //   "Trucks",
                  //   [
                  //   _buildProfileOption(
                  //       "Registered Trucks",
                  //       Icons.local_shipping_outlined,
                  //       const TruckListScreen(),
                  //       "Manage your registered trucks",
                  //       onTap: () => Get.to(() => const TruckListScreen())
                  //     ),
                  //     _buildProfileOption(
                  //       "Add Truck",
                  //       Icons.add_circle_outline,
                  //       const CarRegistrationTemplate(),
                  //       "Register a new truck",
                  //       onTap: () => Get.to(() => const CarRegistrationTemplate()),
                  //     ),
                  //   ]),

                  // // Group 3: Settings
                  // _buildSection(context,
                  // "Account Settings",
                  // [
                  //   _buildProfileOption(
                  //     "Language",
                  //     Icons.language_outlined,
                  //     SettingsScreen(),
                  //     "Change app language",
                  //     onTap: () => Get.to(() => SettingsScreen()),
                  //   ),
                  //   _buildProfileOption(
                  //     "Notifications",
                  //     Icons.notifications_outlined,
                  //     SettingsScreen(),
                  //     "Manage notification preferences",
                  //     onTap: () => Get.to(() => SettingsScreen()),
                  //   ),
                  //   _buildThemeSwitch(context),
                  // ]),

                  // // Group 4: Log Out & Delete Account
                  // _buildSection(
                  //   context,
                  // "Account",
                  // [
                  //   _buildLogoutButton(
                  //     "Log out",
                  //     Icons.logout_outlined,
                  //     _showLogoutDialog,
                  //     isDestructive: true,
                  //   ),
                  //   _buildLogoutButton(
                  //     "Delete account",
                  //     Icons.delete_outlined,
                  
                  //     isDestructive: true),
                  // ]),

                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ));
  }

  /// **Builds the Profile Header with Profile Image**
  Widget _buildProfileHeader(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value) {
        return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: Center(
                child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.rectangleColor),
            )));
      }

      final user = userController.user.value;
      final userName =
          user != null ? "${user.firstname} ${user.lastname}" : "User Name";
      final String? profileImage = user?.profileImage;
      final String userEmail = user?.email ?? "user@example.com";
      final String userRole = _getRoleDisplayName(role);

      print(user);

      // ✅ Ensure correct image URL formatting
      final String? profileImageUrl = UrlUtils.absoluteImageUrl(profileImage);

      final double diameter = MediaQuery.of(context).size.width * 0.72;
      return Container(
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Avatar with plus buttom overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  //Profile image container
                  GestureDetector(
                    onTap: () => _showPersonalInfoModal(context),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: diameter * 0.1,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl) as ImageProvider
                            : null,
                        child: profileImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: diameter * 0.1,
                                color:
                                    AppColors.rectangleColor.withOpacity(0.7),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: () => _onChangeProfilePhoto(context),
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.rectangleColor.withOpacity(0.7),
                        ),
                        child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo,
                              color: AppColors.rectangleColor,
                              size: 15,
                            )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              //User name
              Text(
                userName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              //User email
              Text(userEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  )),

              const SizedBox(height: 4),

              //Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.rectangleColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  userRole,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// **Reusable Section Container**
  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    // ✅ Accept context
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Section title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.grey.shade500,
                  letterSpacing: 1,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),

          //Section content
          Container(
              decoration: BoxDecoration(
                color: const Color(0xfffafafa),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xfff5f5f5)),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.01),
                //     blurRadius: 10,
                //     offset: const Offset(0, 5),
                //   ),
                // ],
              ),
              child: Column(
                children: children,
              )),
        ],
      ),
    );
  }

  /// **Profile Option Tile**
  Widget _buildProfileOption(String title, IconData icon, Widget? screen,
      {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      leading: Icon(
        icon,
        color: AppColors.primaryColor,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade500,
      ),
      onTap: onTap,
    );
  }

  //Dark mode switch tile for settings section
  Widget _buildThemeSwitch(BuildContext context) {
    final ThemeController themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());

    return Obx(() {
      final bool isDark = themeController.isDarkMode.value;
      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dark_mode_outlined,
              color: Colors.black87,
              size: 24,
            ),
          ),
          title: const Text(
            "Dark mode",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            "Switch to dark mode",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          trailing: Switch.adaptive(
            value: isDark,
            activeColor: AppColors.rectangleColor,
            onChanged: (_) => themeController.toggleTheme(),
          ),
          onTap: () => themeController.toggleTheme(),
        ),
      );
    });
  }

  void _onChangeProfilePhoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_back_outlined),
                title: const Text("Take a photo"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Camera upload feature coming sonn"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Choose from gallery"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gallery upload coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// **Logout & Delete Account Button**
  Widget _buildLogoutButton(String title, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : AppColors.rectangleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.rectangleColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  // Helper method to get display name for roles
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'Customer':
        return 'Customer';
      case 'Driver':
        return 'Driver';
      case 'TruckOwner':
        return 'Truck Owner';
      default:
        return 'User';
    }
  }

  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SafeArea(child: personal_info.PersonalInfoScreen()),
    );
  }
}
