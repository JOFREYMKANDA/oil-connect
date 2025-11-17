import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 367,
      decoration: BoxDecoration(
        color: AppColors.rectangleColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(134.5),
          bottomRight: Radius.circular(134.5),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20), // Adds spacing below the logo
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.maxFinite,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.shapeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                width: 67,
                height: 95,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 10), // Spacing between circle and text
          // Text below the logo

        ],
      ),
    );
  }
}
