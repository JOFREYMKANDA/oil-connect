import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/screens/customer%20screens/EditInfoPage.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final RegisterController userController = Get.put(RegisterController());
  final ImagePicker _imagePicker = ImagePicker();
  
  // For custom message
  bool _showMessage = false;
  String _messageText = '';
  bool _isSuccessMessage = false;
  Timer? _messageTimer;

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _showCustomMessage(String message, bool isSuccess) {
    // Cancel any existing timer
    _messageTimer?.cancel();
    
    setState(() {
      _showMessage = true;
      _messageText = message;
      _isSuccessMessage = isSuccess;
    });

    // Auto hide after 3 seconds
    _messageTimer = Timer(const Duration(seconds: 3), _hideMessage);
  }

  void _hideMessage() {
    if (mounted) {
      setState(() {
        _showMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BackAppBar(title: 'Personal Info'),
      body: Obx(() {
        final user = userController.user.value;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Message Container - appears as normal widget in column
                if (_showMessage)
                  _buildMessageContainer(),

                const SizedBox(height: 10),

                // Profile Header
                _buildProfileHeader(user),
                
                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Get.to(() => EditInfoPage()),
                    label: Text(
                      'Edit Personal Info'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        decorationThickness: 2.0,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Personal Information Card
                _buildInfoCard(user),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMessageContainer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isSuccessMessage ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     blurRadius: 4,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
        border: Border.all(
          color: _isSuccessMessage ? Colors.green.shade700 : Colors.red.shade700,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isSuccessMessage ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _messageText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _hideMessage,
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Profile Avatar with Upload Icon
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfffafafa),
                  border: Border.all(color: const Color(0xfff5f5f5), width: 3),
                ),
                child: user.profileImage != null && user.profileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.green[700],
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFE0E0E0),
                      ),
              ),
              // Upload Icon positioned on bottom-right border
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    _showImageSourceBottomSheet(user);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstname} ${user.lastname}',
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showImageSourceBottomSheet(user) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Take Photo'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Choose from Gallery'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery(user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickImageFromCamera(user) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _updateProfilePicture(user, File(image.path));
      }
    } catch (e) {
      _showCustomMessage('Failed to take photo: $e', false);
    }
  }

  void _pickImageFromGallery(user) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _updateProfilePicture(user, File(image.path));
      }
    } catch (e) {
      _showCustomMessage('Failed to pick image: $e', false);
    }
  }

  Future<void> _updateProfilePicture(user, File imageFile) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
        barrierDismissible: false,
      );

      // Create updated user object with current user data
      final updatedUser = user;

      // Call the updateUserProfile method with both image and user object
      await userController.updateUserProfile(imageFile, updatedUser);
      
      // Hide loading indicator
      Get.back();
      
      // Show success message using custom container
      _showCustomMessage('Profile picture updated successfully!', true);
      
    } catch (e) {
      // Hide loading indicator
      Get.back();
      
      // Show error message using custom container
      _showCustomMessage('Failed to update profile picture: $e', false);
    }
  }

  Widget _buildInfoCard(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xffffffff),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information Items
            _buildInfoItem(
              icon: Icons.email_outlined,
              label: 'Email'.tr,
              value: user.email,
            ),
            _buildInfoItem(
              icon: Icons.phone_outlined,
              label: 'Phone'.tr,
              value: user.phoneNumber,
            ),
            if (user.region != null)
              _buildInfoItem(
                icon: Icons.location_on_outlined,
                label: 'Region'.tr,
                value: user.region!,
              ),
            if (user.district != null)
              _buildInfoItem(
                icon: Icons.map_outlined,
                label: 'District'.tr,
                value: user.district!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.green[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'not_available'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}