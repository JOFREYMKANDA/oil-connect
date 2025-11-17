
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  static final TextStyle logoheading = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.shapeColor,
  );
  static final TextStyle heading = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static final TextStyle subHeading = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );

  static final TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.rectangleColor,
  );
  static final TextStyle bodyText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
  static final TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );
  
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
}