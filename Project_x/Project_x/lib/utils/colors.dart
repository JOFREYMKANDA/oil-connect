import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundColor = Color(0xffFFFFFF);
  //static const Color rectangleColor = Color(0xff079D3F);
  static Color rectangleColor = Colors.green.shade900;
  static const Color strokeColor = Color(0xff8a000000);
  static const Color shapeColor = Color(0xffFFFFFF);
  static const Color redColor = Color(0xffD32F2F);
  static const Color blueColor = Color(0xff2196F3);
  static const Color listColor = Color(0xffF1EEEE);
  static const Color viewColor = Color(0xffE7FAEE);
  static const Color textColor = Color(0xff000000);
  static const Color textFieldBorder = Color(0xffDADCE0);

  // ✅ Added missing colors
  static const Color borderColor = Color(0xffDADCE0);
  static const Color labelTextColor = Color.fromRGBO(158, 158, 158, 1);
  static const Color buttonBorderColor = Colors.black12;
  static const Color buttonOverlayColor =
      Color(0x1A079D3F); // Green with opacity 0.1
  static const Color buttonShadowColor =
      Color(0x4D079D3F); // Green with opacity 0.3
  static const Color logoutButtonColor = Colors.red;
  static const Color cardBackground =
      Color(0xffEEEEEE); // Equivalent to Colors.grey[200]
  static const Color shadowColor =
      Color(0x33000000); // Equivalent to Colors.grey.withOpacity(0.2)
  static const Color unselectedNavItemColor = Colors.grey;
  static const Color profileBackground = Colors.white;
  static const Color avatarPlaceholder =
      Color(0xffE0E0E0); // Equivalent to Colors.grey.shade300

  static const Color primaryColor =
      Color(0xff079D3F); // Green color for primary actions
  static const Color messageTextColor = Colors.white;
  static const Color textFieldBackground =
      Color(0xffE0E0E0); // Equivalent to Colors.grey[200]
  static const Color sendButtonColor = Colors.grey;
}
