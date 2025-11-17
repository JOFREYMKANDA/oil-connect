import 'package:flutter/material.dart';
import '../colors.dart';

ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.rectangleColor,
    scaffoldBackgroundColor: Color(0xFF1d1a21), // Dark background
    textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.shapeColor),
        bodyMedium: TextStyle(color: AppColors.shapeColor),
    ),
    iconTheme: const IconThemeData(color: AppColors.shapeColor),
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
