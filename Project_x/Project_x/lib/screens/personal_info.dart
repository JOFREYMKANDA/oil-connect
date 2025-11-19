import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/backend/models/user_model.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';

/// Helper to open the edit sheet directly from other screens
void showPersonalInfoEditSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const SafeArea(child: PersonalInfoScreen()),
  );
}

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final RegisterController userController = Get.put(RegisterController());
  final ImagePicker _picker = ImagePicker();
  final Rx<File?> _selectedImage = Rx<File?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  Timer? _authCheckTimer;


  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController workingPositionController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _initializeUserData();
    
    // Start automatic authentication flow
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startAutomaticAuthentication();
    });
    
    // Listen to user changes to update authentication status
    ever(userController.user, (User? user) {
      if (user != null) {
        isAuthenticated.value = true;
        print("✅ User data updated, authentication status set to true");
      } else {
        isAuthenticated.value = false;
        print("⚠️ User data cleared, authentication status set to false");
      }
    });
    
    // Start periodic authentication check (every 30 seconds)
    _startPeriodicAuthCheck();
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  void _initializeUserData() {
    if (userController.user.value != null) {
      nameController.text =
      "${userController.user.value?.firstname ?? ""} ${userController.user.value?.lastname ?? ""}";
      phoneController.text = userController.user.value?.phoneNumber ?? "";
      emailController.text = userController.user.value?.email ?? "";
      regionController.text = userController.user.value?.region ?? "";
      districtController.text = userController.user.value?.district ?? "";
      workingPositionController.text = userController.user.value?.workingPosition ?? "";
      isAuthenticated.value = true;
      print("✅ User data initialized from existing user object");
    } else {
      print("⚠️ No user data found, will attempt to fetch");
      // If user is null, try to fetch user details
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userController.fetchUserDetails();
      });
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      await SharedPrefsUtil().init();
      final token = SharedPrefsUtil().getToken();
      final role = SharedPrefsUtil().getRole();
      
      if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
        isAuthenticated.value = true;
        print("✅ Authentication check passed - Token and role found");
      } else {
        isAuthenticated.value = false;
        print("⚠️ Authentication check failed - Token: ${token != null}, Role: ${role != null}");
        // Don't show error immediately - let the user data loading handle it
      }
    } catch (e) {
      print("❌ Error checking authentication: $e");
      isAuthenticated.value = false;
    }
  }

  /// 🔄 Automatic Authentication Flow - No User Intervention Required
  Future<void> _startAutomaticAuthentication() async {
    print("🚀 Starting automatic authentication flow...");
    
    // Step 1: Check current authentication status
    await _checkAuthenticationStatus();
    
    // Step 2: If not authenticated, try to fetch user data
    if (!isAuthenticated.value || userController.user.value == null) {
      print("🔄 Authentication needed, attempting to fetch user data...");
      await _attemptUserDataFetch();
    }
    
    // Step 3: If still not authenticated, try to refresh token
    if (!isAuthenticated.value || userController.user.value == null) {
      print("🔄 Still not authenticated, attempting token refresh...");
      await _attemptTokenRefresh();
    }
    
    // Step 4: Final attempt to fetch user data
    if (!isAuthenticated.value || userController.user.value == null) {
      print("🔄 Final attempt to fetch user data...");
      await _attemptUserDataFetch();
    }
    
    // Step 5: Update UI based on final status
    if (isAuthenticated.value && userController.user.value != null) {
      print("✅ Automatic authentication successful!");
      _initializeUserData();
    } else {
      print("❌ Automatic authentication failed after all attempts");
      // Don't show error to user - just keep the UI in loading state
    }
  }

  /// 🔄 Attempt to fetch user data with retry logic
  Future<void> _attemptUserDataFetch() async {
    try {
      print("📡 Attempting to fetch user data...");
      await userController.fetchUserDetails();
      
      // Wait a bit for the data to process
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (userController.user.value != null) {
        print("✅ User data fetch successful");
        isAuthenticated.value = true;
      } else {
        print("⚠️ User data fetch returned null");
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  /// 🔄 Attempt to refresh authentication token
  Future<void> _attemptTokenRefresh() async {
    try {
      print("🔄 Attempting token refresh...");
      
      // Check if we have a valid token
      await SharedPrefsUtil().init();
      final token = SharedPrefsUtil().getToken();
      final role = SharedPrefsUtil().getRole();
      
      if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
        print("✅ Token and role found, attempting to validate...");
        
        // Try to make a simple API call to validate token
        await _validateTokenWithAPI(token);
      } else {
        print("⚠️ No valid token or role found");
      }
    } catch (e) {
      print("❌ Error during token refresh: $e");
    }
  }

  /// 🔄 Validate token by making a simple API call
  Future<void> _validateTokenWithAPI(String token) async {
    try {
      // This is a simple validation - you can replace with your actual validation endpoint
      print("🔍 Validating token with API...");
      
      // For now, we'll just try to fetch user data again
      // In a real app, you might have a dedicated token validation endpoint
      await userController.fetchUserDetails();
      
      if (userController.user.value != null) {
        print("✅ Token validation successful");
        isAuthenticated.value = true;
      }
    } catch (e) {
      print("❌ Token validation failed: $e");
    }
  }

  /// 🔄 Start periodic authentication check
  void _startPeriodicAuthCheck() {
    _authCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (mounted) {
        print("🔄 Periodic authentication check...");
        await _silentAuthCheck();
      }
    });
  }

  /// 🔄 Silent authentication check without user notification
  Future<void> _silentAuthCheck() async {
    try {
      // Only check if we're not currently loading
      if (!isLoading.value) {
        await _checkAuthenticationStatus();
        
        // If authentication failed, try to recover silently
        if (!isAuthenticated.value || userController.user.value == null) {
          print("🔄 Silent recovery attempt...");
          await _attemptUserDataFetch();
        }
      }
    } catch (e) {
      print("❌ Silent auth check failed: $e");
    }
  }

  /// 🔄 Attempt automatic recovery when authentication is needed
  Future<void> _attemptAutomaticRecovery() async {
    print("🔄 Starting automatic recovery...");
    
    try {
      // Step 1: Check authentication status
      await _checkAuthenticationStatus();
      
      // Step 2: If still not authenticated, try to fetch user data
      if (!isAuthenticated.value || userController.user.value == null) {
        await _attemptUserDataFetch();
      }
      
      // Step 3: If still not authenticated, try token refresh
      if (!isAuthenticated.value || userController.user.value == null) {
        await _attemptTokenRefresh();
      }
      
      // Step 4: Final attempt to fetch user data
      if (!isAuthenticated.value || userController.user.value == null) {
        await _attemptUserDataFetch();
      }
      
      if (isAuthenticated.value && userController.user.value != null) {
        print("✅ Automatic recovery successful!");
      } else {
        print("❌ Automatic recovery failed");
      }
    } catch (e) {
      print("❌ Error during automatic recovery: $e");
    }
  }

  // ✅ Pick Image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String mimeType = lookupMimeType(imageFile.path) ?? "";
        print("📌 Selected File Type: $mimeType");

        // ✅ Validate allowed extensions
        List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
        String fileExtension = pickedFile.path.split('.').last.toLowerCase();

        if (!allowedExtensions.contains(fileExtension)) {
          Get.snackbar("Error", "Invalid file type. Please select an image (JPG, PNG, GIF).");
          return;
        }
        // ✅ Update UI instantly
        _selectedImage.value = imageFile;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image: $e");
    }
  }

  // ✅ Show Image Picker Options (Camera/Gallery)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                _pickImage(ImageSource.camera);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ Update Profile Data (Handles both Image & Text Fields)
  Future<void> _updateProfile() async {
    if (isLoading.value) return;
    
    // Validate that user data is loaded
    if (userController.user.value == null) {
      Get.snackbar(
        "Error", 
        "User data not loaded. Please refresh and try again.", 
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    // Validate required fields
    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
      Get.snackbar(
        "Error", 
        "Name and email are required fields.", 
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Check authentication before proceeding
    if (!isAuthenticated.value) {
      print("🔄 Authentication needed before update, attempting automatic recovery...");
      await _attemptAutomaticRecovery();
      
      // If still not authenticated after recovery attempt, show error
      if (!isAuthenticated.value) {
        Get.snackbar(
          "Authentication Error", 
          "Unable to authenticate. Please try again later.", 
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }
    
    isLoading.value = true;

    final parts = nameController.text.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first: "";
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : "";

    final updatedUser = userController.user.value!.copyWith(
      firstname: first,
      lastname: last,
      email: emailController.text.trim(),
      phoneNumber: phoneController.text,
      region: regionController.text.trim(),
      district: districtController.text.trim(),
      workingPosition: workingPositionController.text.trim(),
    );

    // ✅ Call API with updated user details
    try {
      print("🔄 Updating user profile");
      await userController.updateUserProfile(_selectedImage.value, updatedUser);
      print("✅ User profile updated successfully");

      //Clear local preview so that the refreshed network image shows
      _selectedImage.value = null;

      // ✅ Fetch latest user data and update UI
      print("🔄 Fetching updated user details...");
      await userController.fetchUserDetails();
      print("✅ Fetch complete");

      // ✅ Show success message and close sheet
      Get.snackbar(
        "Success", 
        "Profile updated successfully!", 
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      Navigator.pop(context); // Close bottom sheet after updating

    } catch (e, stack) {
      print("❌ Error in update/fetch: $e");
      print(stack);
      
      // Check if it's an authentication error
      String errorMessage = "Failed to update profile. Please try again.";
      if (e.toString().contains("No token found") || e.toString().contains("Authentication failed")) {
        errorMessage = "Authentication failed. Please log in again.";
        isAuthenticated.value = false;
      }
      
      // Show user-friendly error message
      Get.snackbar(
        "Error", 
        errorMessage, 
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
    
    
  @override
  Widget build(BuildContext context) {

    // Render the edit UI directly (same as _openEditBottomSheet content)
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                                 IconButton(
                   onPressed: () async {
                     print("🔄 Manual refresh requested");
                     await _startAutomaticAuthentication();
                   },
                   icon: Icon(
                     Icons.refresh,
                     color: AppColors.rectangleColor,
                   ),
                   tooltip: "Refresh user data",
                 ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatar picker
            Obx(() {
              return Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.rectangleColor.withOpacity(0.2),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.avatarPlaceholder,
                      backgroundImage: _selectedImage.value != null
                          ? FileImage(_selectedImage.value!)
                          : (userController.user.value?.profileImage?.isNotEmpty == true
                              ? NetworkImage(userController.user.value!.profileImage!)
                              : null) as ImageProvider?,
                      child: _selectedImage.value == null &&
                              !(userController.user.value?.profileImage?.isNotEmpty == true)
                          ? const Icon(Icons.person, size: 50, color: AppColors.profileBackground)
                          : null,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.rectangleColor, width: 2),
                    ),
                    child: IconButton(
                      onPressed: _showImagePickerOptions,
                      icon: Icon(
                        Icons.add_a_photo,
                        color: AppColors.rectangleColor,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.backgroundColor,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            _buildTextField("Full Name", Icons.person_outline, nameController),
            _buildTextField("Phone Number", Icons.phone_outlined, phoneController),
            _buildTextField("Email", Icons.email_outlined, emailController),
            _buildTextField("Region", Icons.location_city, regionController),
            _buildTextField("District", Icons.map_outlined, districtController),
            _buildTextField("Working Position", Icons.work_outline, workingPositionController),

            const SizedBox(height: 24),

            Obx(() {
              final user = userController.user.value;
              final isUserLoaded = user != null;
              final canUpdate = isUserLoaded && isAuthenticated.value;
              final isCheckingAuth = !isUserLoaded && !isAuthenticated.value;
              
              return SizedBox(
                width: double.infinity,
                child: isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.rectangleColor,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: canUpdate ? _updateProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUpdate 
                              ? AppColors.rectangleColor 
                              : AppColors.rectangleColor.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          canUpdate ? "Save Changes" : 
                          isCheckingAuth ? "Checking Authentication..." : 
                          !isUserLoaded ? "Loading User Data..." : "Authentication in Progress...",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {}); // Refresh UI to change border color
        },
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.rectangleColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.textFieldBorder.withOpacity(0.1)), // Default Grey
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.rectangleColor.withOpacity(0.7), width: 0.5), // ✅ Green when focused
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.rectangleColor, width: 1), // ✅ Green when focused
            ),
          ),
        ),
      ),
    );
  }
}
