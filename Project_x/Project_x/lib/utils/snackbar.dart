import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper function to show snackbars that work even during async calls and navigation
/// This ensures the snackbar always appears, even if called before the screen is fully built
void showTopSnackBar(
  String title,
  String message, {
  Color bg = Colors.red,
  Duration duration = const Duration(seconds: 4),
  bool isDismissible = true,
  SnackPosition position = SnackPosition.TOP,
}) {
  Future.delayed(Duration.zero, () {
    if (Get.isSnackbarOpen) {
      Get.back(); // Close existing snackbar
    }
    
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: bg,
      colorText: Colors.white,
      duration: duration,
      isDismissible: isDismissible,
      shouldIconPulse: true,
      margin: const EdgeInsets.all(10),
    );
  });
}

