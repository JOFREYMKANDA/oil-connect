import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/colors.dart'; // make sure AppColors is defined here

class BackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final List<Widget>? actions; // New parameter for action buttons

  const BackAppBar({
    super.key,
    required this.title,
    this.backgroundColor = AppColors.backgroundColor, // use your custom color
    this.foregroundColor = AppColors.textColor, // your text/icon color
    this.elevation = 0,
    this.actions, // Optional action buttons
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop(); // check if we can pop the route

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back,
                size: 40,
                color: Colors.black,
              ),
              onPressed: () {
                Get.back();
              },
            )
          : null, // hide back button if we are on root
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: foregroundColor, // ensure text color uses custom color
        ),
      ),
      centerTitle: false, // 👈 Align title to the start (left)
      actions: actions, // Pass the actions to the AppBar
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}