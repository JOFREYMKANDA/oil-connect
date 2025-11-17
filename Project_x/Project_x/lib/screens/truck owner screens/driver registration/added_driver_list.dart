import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/models/driver_model.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/driver%20registration/add_new_driver.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/driver%20registration/driver_information.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import '../../../backend/controllers/registerDriverController.dart';
import '../../../utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  final DriverRegistrationController controller =
  Get.put(DriverRegistrationController());

  @override
  void initState() {
    super.initState();
    controller.fetchDrivers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoleBasedBottomNavScreen(role: 'TruckOwner'),
                            ),
                            (route) => false,
                          );
                        },
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Manage Drivers",
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      // Manual refresh button
                      IconButton(
                        onPressed: () => controller.fetchDrivers(),
                        icon: Icon(
                          Icons.refresh_rounded,
                           color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          size: 28,
                        ),
                        tooltip: 'Refresh drivers list',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "View and manage your registered drivers",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),

            // Search and Add Driver Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE1E5E9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        controller.searchText.value = value;
                      },
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : const Color(0xFF666666),
                        ),
                        hintText: 'Search drivers by name...',
                        hintStyle: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : const Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Add Driver Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rectangleColor,
                          AppColors.rectangleColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => const AddNewDriverScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Add New Driver",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Drivers List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.fetchDrivers(),
                color: AppColors.rectangleColor,
                child: Obx(() {
                  if (controller.isLoading.value && controller.filteredDrivers.isEmpty) {
                    return _buildLoadingState(context);
                  }

                  if (controller.filteredDrivers.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: controller.filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = controller.filteredDrivers[index];
                      return _buildDriverCard(context, driver);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.rectangleColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading drivers...",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.drive_eta_rounded,
              size: 60,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Drivers Found",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You haven't registered any drivers yet.\nAdd your first driver to get started.",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : const Color(0xFF666666),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, Driver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                child: DriverInfoBottomSheet(driver: driver),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Driver Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rectangleColor,
                        AppColors.rectangleColor.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rectangleColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      driver.firstname.isNotEmpty ? driver.firstname[0].toUpperCase() : "D",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Driver Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${driver.firstname} ${driver.lastname}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.phoneNumber.isNotEmpty ? driver.phoneNumber : "No phone number",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              driver.email.isNotEmpty ? driver.email : "No email",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white60
                                    : const Color(0xFF666666),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                _buildStatusBadge(driver.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'available':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'busy':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.schedule_rounded;
        break;
      case 'offline':
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.offline_bolt_rounded;
        break;
      default:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}


class DriverTile extends StatelessWidget {
  final String name;
  final String status;
  final Driver driver;
  final VoidCallback onTap;

  const DriverTile({
    super.key,
    required this.name,
    required this.status,
    required this.driver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        radius: 20,
        child: Icon(Icons.person),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: _buildStatusChip(status), // Use Chip with custom styling
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            child: DriverInfoBottomSheet(driver: driver),
          ),
        );

      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'available':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        break;
      case 'busy':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
    }

    return Container(
      width: 90,
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}