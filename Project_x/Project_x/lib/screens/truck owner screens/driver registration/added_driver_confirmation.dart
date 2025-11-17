import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/driver%20registration/added_driver_list.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:oil_connect/utils/text_style.dart';
import 'package:oil_connect/widget/logo_widget.dart';
import 'package:oil_connect/backend/controllers/registerDriverController.dart';

class AddedDriverConfirmation extends StatelessWidget {
  const AddedDriverConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    final DriverRegistrationController controller =
        Get.put(DriverRegistrationController()); //

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Logo and header text
              Stack(
                alignment: Alignment.center,
                children: [
                  LogoWidget(),
                  Positioned(
                    bottom: 20,
                    child: Column(
                      children: [
                        Text(
                          AppConstants.driverRegistration,
                          style: AppTextStyles.logoheading,
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Image with text below
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/check_green.png',
                      width: 125,
                      height: 125,
                      fit: BoxFit.contain,
                    ), // Image
                    const SizedBox(height: 15), // Spacing
                    Text(
                      "Driver has been successfully added!",
                      style: AppTextStyles.subHeading, 
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Elevated Button at the bottom
          Positioned(
            bottom: 50, 
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                controller.fetchDrivers(); 
                Get.to(() => DriversListScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.shapeColor,
                minimumSize: const Size(double.infinity, 55), // Button height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                  side: const BorderSide(
                    color: AppColors.strokeColor,
                    width: 1.0,
                  ),
                ),
                elevation: 0,
              ).copyWith(
                overlayColor: WidgetStateProperty.all(
                  Colors.green.withOpacity(0.1),
                ), // Green glow effect when clicked
                shadowColor: WidgetStateProperty.all(
                  Colors.green.withOpacity(0.3),
                ), // Subtle green shadow on click
              ),
              child: Text(
                AppConstants.next,
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
