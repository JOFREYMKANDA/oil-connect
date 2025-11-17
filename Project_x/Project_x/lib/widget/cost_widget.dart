import 'package:flutter/material.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:intl/intl.dart'; // Import intl for number formatting

class CostCard extends StatelessWidget {
  final double price;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CostCard({
    Key? key,
    required this.price,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            offset: const Offset(0, 5),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Price",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Tsh. ${NumberFormat("#,###").format(price)}/=",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.rectangleColor,
                ),
                textAlign: TextAlign.center, // Ensure text is centered
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Keep buttons aligned as before
            children: [
              ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Cancel button color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rectangleColor, // Confirm button color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: AppColors.shapeColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
