import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/screens/customer%20screens/personalDetailsPage.dart';
import 'package:oil_connect/screens/customer%20screens/registered_station.dart';
import 'package:oil_connect/screens/settings_screens.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';
import 'package:url_launcher/url_launcher.dart';
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
                      onTap:() {
                        _showLogoutDialog();
                      },
                    ),
                  ]),

                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ));
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
}
