import 'package:flutter/material.dart';
import '../colors.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.rectangleColor,
  scaffoldBackgroundColor: AppColors.backgroundColor,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textColor),
    bodyMedium: TextStyle(color: AppColors.textColor),
  ),
  iconTheme: const IconThemeData(color: AppColors.textColor),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.rectangleColor,
    iconTheme: const IconThemeData(color: AppColors.shapeColor),
    titleTextStyle: const TextStyle(
      color: AppColors.shapeColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: AppColors.rectangleColor,
    textTheme: ButtonTextTheme.primary,
  ),
);
