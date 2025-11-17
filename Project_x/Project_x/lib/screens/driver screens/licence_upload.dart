
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oil_connect/backend/api/api_config.dart';
import 'package:oil_connect/screens/driver%20screens/successLicenceUploads.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import 'package:oil_connect/utils/text_style.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class DriverLicenseUploadScreen extends StatefulWidget {
  const DriverLicenseUploadScreen({super.key});

  @override
  State<DriverLicenseUploadScreen> createState() => _DriverLicenseUploadScreenState();
}

class _DriverLicenseUploadScreenState extends State<DriverLicenseUploadScreen> {
  File? licenseImage;
  final picker = ImagePicker();
  bool isSubmitting = false;

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        licenseImage = File(picked.path);
      });
    }
  }

  Future<void> submitLicense() async {
    if (licenseImage == null) {
      Get.snackbar("Error", "Please upload your license image", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        Get.snackbar("Error", "Token missing. Please login again.");
        return;
      }

      final uri = Uri.parse('${Config.baseUrl}/drivers/upload-license');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(licenseImage!.path) ?? "image/jpeg";
      request.files.add(
        await http.MultipartFile.fromPath(
          'licenseImage',
          licenseImage!.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📥 Response Body: $responseBody");

      // Try to decode the JSON response
      final responseData = responseBody.isNotEmpty ? jsonDecode(responseBody) : null;

      if (response.statusCode == 200) {
        //Get.snackbar("Success", "License uploaded. Waiting for approval.", backgroundColor: Colors.green);
        await SharedPrefsUtil().saveLicenseSubmitted(true);
        Get.to(() => const SuccessUploads());
      } else {
        final message = responseData?['message'] ?? 'Upload failed';
        Get.snackbar("Error", message, backgroundColor: Colors.red);
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE1E5E9),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Upload License",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Upload your driver's license for verification",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // License Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rectangleColor,
                          AppColors.rectangleColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rectangleColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Instructions Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE1E5E9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.rectangleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.rectangleColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "License Requirements",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Please ensure your license image is:",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : const Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRequirementItem("Clear and readable", Icons.visibility_rounded),
                          _buildRequirementItem("Well-lit with good contrast", Icons.light_mode_rounded),
                          _buildRequirementItem("All text visible and not blurry", Icons.text_fields_rounded),
                          _buildRequirementItem("Valid and not expired", Icons.verified_rounded),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Upload Area
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: licenseImage != null
                                ? AppColors.rectangleColor
                                : Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFE1E5E9),
                            width: licenseImage != null ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: licenseImage != null
                                  ? AppColors.rectangleColor.withOpacity(0.2)
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: licenseImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      licenseImage!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Overlay with change option
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.edit_rounded,
                                                color: AppColors.rectangleColor,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Tap to change image",
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.rectangleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.cloud_upload_rounded,
                                      size: 48,
                                      color: AppColors.rectangleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Tap to upload license image",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "JPG, PNG or PDF files supported",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white60
                                          : const Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.rectangleColor,
                            AppColors.rectangleColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rectangleColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submitLicense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Uploading...",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.upload_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Upload License",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.rectangleColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
