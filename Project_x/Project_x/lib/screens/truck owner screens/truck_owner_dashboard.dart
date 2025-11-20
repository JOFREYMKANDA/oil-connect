import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oil_connect/backend/api/api_config.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/backend/controllers/truckownerController.dart';
import 'package:oil_connect/screens/personal_info.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/driver%20registration/added_driver_list.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/new_orders.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/truck%20registration/truck_list.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/drawer_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TruckOwnerDashboardScreen extends StatefulWidget {
  const TruckOwnerDashboardScreen({super.key});

  @override
  State<TruckOwnerDashboardScreen> createState() => _TruckOwnerDashboardScreenState();
}

class _TruckOwnerDashboardScreenState extends State<TruckOwnerDashboardScreen> {
  final RegisterController userController = Get.put(RegisterController());
  final TruckOwnerController truckOwnerController = Get.put(TruckOwnerController(), permanent: true);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      truckOwnerController.fetchDriverCount();
      truckOwnerController.fetchTruckCount();
      if (truckOwnerController.orders.isEmpty) truckOwnerController.fetchOrders();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final file = File(picked.path);
      Get.dialog(Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.rectangleColor))), barrierDismissible: false);
      final user = userController.user.value;
      if (user != null) {
        await userController.updateUserProfile(file, user);
      }
      Get.back();
      Get.snackbar('Success', 'Profile photo updated', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to pick/change image', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showProfileOptions(String? profileImageUrl, String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.avatarPlaceholder,
                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl == null ? Icon(Icons.person, size: 40, color: AppColors.rectangleColor.withOpacity(0.8)) : null,
                ),
                const SizedBox(height: 12),
                Text(userName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPersonalInfoModal(context);
                        },
                        icon: const Icon(Icons.person_outline, color: Colors.white),
                        label: const Text('Profile', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.rectangleColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showImagePickerSheet();
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Change Photo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Choose photo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.rectangleColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ])
            ]),
          ),
        );
      },
    );
  }

  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const SafeArea(child: PersonalInfoScreen()),
    );
  }


  Widget _statTile(String label, String value, IconData icon, Color color) {
    final bool isLoading = value.trim() == '...';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isLoading ? Colors.grey[400] : color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap, {int? badge}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(icon, size: 70, color: Colors.white),
                ),
              ),
              if (badge != null && badge > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge.toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'View details',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomerDrawer(role: 'TruckOwner'),
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 26),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            final user = userController.user.value;
            final String? profileImage = user?.profileImage;
            String? profileUrl;
            if (profileImage != null && profileImage.isNotEmpty) {
              profileUrl = profileImage.startsWith('http') 
                  ? profileImage 
                  : '${Config.baseUrl}/storage/$profileImage';
            }
            final userName = user?.firstname.isNotEmpty == true ? user!.firstname : 'User';
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () => _showProfileOptions(profileUrl, userName),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                    child: profileUrl == null 
                        ? const Icon(Icons.person, color: Colors.black87, size: 20)
                        : null,
                  ),
                ),
              ),
            );
          })
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            // Calculate heights: Greeting (~40), Stats Grid (~110), Spacing (~28), Quick Actions header (~26), Action cards spacing (~16)
            // Remaining space for 3 action cards
            const usedSpace = 40 + 110 + 28 + 26 + 16; // Fixed space for other elements
            final remainingSpace = availableHeight - usedSpace - 24; // 24 for padding
            final actionCardHeight = (remainingSpace / 3).clamp(70.0, 120.0);
            
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Section
                      Text(
                        'Welcome back 👋',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        if (userController.isLoading.value) {
                          return const SizedBox(
                            height: 24,
                            child: ShimmerLoader(width: 100),
                          );
                        }
                        final user = userController.user.value;
                        final name = user?.firstname.isNotEmpty == true ? user!.firstname : 'Driver';
                        return Text(
                          'Hi, $name!',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                        children: [
                          Obx(() => _statTile(
                            'Trucks',
                            truckOwnerController.isLoadingTruckCount.value ? '...' : truckOwnerController.truckCount.value.toString(),
                            Icons.local_shipping_rounded,
                            AppColors.primaryColor,
                          )),
                          Obx(() => _statTile(
                            'Drivers',
                            truckOwnerController.isLoadingDriverCount.value ? '...' : truckOwnerController.driverCount.value.toString(),
                            Icons.people_rounded,
                            Colors.blue,
                          )),
                          Obx(() => _statTile(
                            'Orders',
                            truckOwnerController.isLoading.value ? '...' : truckOwnerController.orders.length.toString(),
                            Icons.receipt_long_rounded,
                            Colors.orange,
                          )),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action Cards with calculated height
                      SizedBox(
                        height: actionCardHeight,
                        child: _actionCard(
                          'Manage Trucks',
                          FontAwesomeIcons.truck,
                          AppColors.primaryColor,
                          () => Get.to(() => const TruckListScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: actionCardHeight,
                        child: _actionCard(
                          'Manage Drivers',
                          FontAwesomeIcons.users,
                          const Color(0xFF2196F3),
                          () => Get.to(const DriversListScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: actionCardHeight,
                        child: Obx(() => _actionCard(
                          'New Requests',
                          FontAwesomeIcons.clipboardList,
                          const Color(0xFFFF9800),
                          () => Get.to(() => NewOrdersScreen()),
                          badge: truckOwnerController.orders.length,
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Add this shimmer loader widget for better loading states
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  
  const ShimmerLoader({super.key, this.width = double.infinity, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}