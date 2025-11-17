import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/screens/login%20screens/registration.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:oil_connect/utils/text_style.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/logo_widget.dart';

class DecideButton extends StatefulWidget {
  const DecideButton({super.key});

  @override
  State<DecideButton> createState() => _DecideButtonState();
}

class _DecideButtonState extends State<DecideButton> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // ✅ Check dark mode

    return Scaffold(
      body: SizedBox(
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 80),

                  // Logo section
                  Container(
                    width: 122,
                    height: 122,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.35),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),
                  
                  // "REGISTER AS" Text
                  Text(
                    AppConstants.registerAs.tr,
                    style: AppTextStyles.heading.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color, // ✅ Dynamic text color
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Buttons Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Truck Owner Button
                        buildRoleButton(
                          context,
                          icon: Icons.local_shipping_outlined,
                          label: "Truck Owner",
                          onTap: () {
                            Get.to(() => const RegistrationScreen(role: "TruckOwner"));
                          },
                        ),
                        const SizedBox(height: 16),

                        // Customer Button
                        buildRoleButton(
                          context,
                          icon: Icons.person_outline,
                          label: "Customer",
                          onTap: () {
                            Get.to(() => const RegistrationScreen(role: "Customer"));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  // Custom Button Widget with Theming
  Widget buildRoleButton(
      BuildContext context, { // ✅ Pass context for theming
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // ✅ Dark mode check
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : AppColors.shapeColor, // ✅ Adaptive button color
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 8),

              // Center-aligned label
              Center(
                child: Text(
                  label,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color, // ✅ Adaptive text color
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
