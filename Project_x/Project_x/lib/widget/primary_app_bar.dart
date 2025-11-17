import 'package:flutter/material.dart';
import 'package:oil_connect/utils/colors.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const PrimaryAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? AppColors.rectangleColor;
    final Color fg = foregroundColor ?? AppColors.shapeColor;
    return AppBar(
      backgroundColor: bg,
      elevation: elevation,
      iconTheme: IconThemeData(color: fg),
      centerTitle: centerTitle,
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: actions,
    );
  }
}
