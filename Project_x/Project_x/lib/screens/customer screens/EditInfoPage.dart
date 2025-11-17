import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/backend/models/user_model.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/widget/AppBar.dart';

class EditInfoPage extends StatefulWidget {
  const EditInfoPage({super.key});

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final RegisterController userController = Get.put(RegisterController());
  
  late TextEditingController _FnameController;
  late TextEditingController _LnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _regionController;
  late TextEditingController _districtController;

  final _formKey = GlobalKey<FormState>();
  
  // For custom message
  bool _showMessage = false;
  String _messageText = '';
  bool _isSuccessMessage = false;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    final user = userController.user.value;
    _FnameController = TextEditingController(text: user!.firstname);
    _LnameController = TextEditingController(text: user.lastname);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _regionController = TextEditingController(text: user.region ?? '');
    _districtController = TextEditingController(text: user.district ?? '');
  }

  @override
  void dispose() {
    _FnameController.dispose();
    _LnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _districtController.dispose();
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
    _messageTimer = Timer(const Duration(seconds: 2), _hideMessage);
  }

  void _hideMessage() {
    if (mounted) {
      setState(() {
        _showMessage = false;
      });
    }
  }

  void _saveChanges() async {
  if (!_formKey.currentState!.validate()) {
    // Only show the banner when validation fails, not both error texts
    _showCustomMessage('Please fix the errors in the form', false);
    return;
  }

  try {
    final updatedUser = User(
      firstname: _FnameController.text.trim(),
      lastname: _LnameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      profileImage: userController.user.value?.profileImage,
      licenseNumber: userController.user.value?.licenseNumber,
      licenseExpireDate: userController.user.value?.licenseExpireDate,
      latitude: userController.user.value?.latitude,
      longitude: userController.user.value?.longitude,
      userDepo: userController.user.value?.userDepo,
      password: userController.user.value?.password,
      workingPosition: userController.user.value?.workingPosition,
      role: userController.user.value!.role,
      status: userController.user.value?.status,
    );

    await userController.updateUserProfile(null, updatedUser);

    // Update GetX reactive user to reflect the new data
    userController.user.value = updatedUser;

    _showCustomMessage('Profile updated successfully!', true);

    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Get.back(); // Navigate back
      }
    });
  } catch (e) {
    _showCustomMessage('Failed to update profile. Please try again.', false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BackAppBar(
        title: 'Edit Info',
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Message Container - appears as normal widget in column
                if (_showMessage)
                  _buildMessageContainer(),

                const SizedBox(height: 10),

                // Edit Form Card
                Card(
                  elevation: 0,
                  color: const Color(0xffffffff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _FnameController,
                          label: 'Firstname'.tr,
                          icon: Icons.person_outline,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Firstname required'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _LnameController,
                          label: 'Lastname'.tr,
                          icon: Icons.person_outline,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lastname required'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email'.tr,
                          icon: Icons.email_outlined,
                          isRequired: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email required'.tr;
                            }
                            if (!GetUtils.isEmail(value)) {
                              return 'Invalid email'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone'.tr,
                          icon: Icons.phone_outlined,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone required'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _regionController,
                          label: 'Region'.tr,
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _districtController,
                          label: 'District'.tr,
                          icon: Icons.map_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
        labelStyle: const TextStyle(
          color: Colors.black38,
          fontWeight: FontWeight.w500
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.textColor,
          fontWeight: FontWeight.w500
        ),
        fillColor: const Color(0xfffafafa),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xfff5f5f5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xfff5f5f5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}