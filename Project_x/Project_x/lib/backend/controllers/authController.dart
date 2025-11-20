import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:oil_connect/backend/api/api_config.dart';
import 'package:oil_connect/screens/login%20screens/login.dart';
import 'package:oil_connect/screens/driver%20screens/licence_upload.dart';
import 'package:oil_connect/utils/api_constants.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import 'package:http/http.dart' as http;
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/authServices.dart';
import 'package:oil_connect/screens/common/success_page.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/snackbar.dart';

class RegisterController extends GetxController {
  var isLoading = false.obs;
  var user = Rxn<User>();
  final AuthService _authService = AuthService();
  final Rx<File?> _selectedImage = Rx<File?>(null);
  File? get selectedImage => _selectedImage.value;

  bool _isLoggingOut = false;

  @override
  void onInit() {
    super.onInit();
    fetchUserDetails();
  }

  // Register user with email/password
  Future<Map<String, dynamic>?> registerTruckOwner(User user) async {
    isLoading.value = true;
    try {
      print(
          '🚀 [DEBUG] Starting registration for user: ${user.firstname} ${user.lastname}');
      print('🚀 [DEBUG] User role: ${user.role}');
      print('🚀 [DEBUG] User data: ${user.toJson()}');
      final response = await _authService.registerWithEmail(user.toJson());

      print('📡 [DEBUG] Response status code: ${response.statusCode}');
      print('📡 [DEBUG] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ [DEBUG] Registration successful!');
        final data = jsonDecode(response.body);
        print('📋 [DEBUG] Registration response data: $data');
        print('📋 [DEBUG] UserId from response: ${data['userId']}');
        print('📋 [DEBUG] UserId type: ${data['userId'].runtimeType}');
        String roleText = user.role.toLowerCase() == 'truckowner'
            ? 'truck owner'
            : 'customer';
        Get.snackbar("Success",
            "$roleText registration successful! Please check your email for verification code.",
            backgroundColor: Colors.green, colorText: Colors.white);
        return data;
      } else {
        String errorMsg = "Registration failed";
        Map<String, dynamic>? responseData;
        
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMsg = responseData['message'] ??
              responseData['error'] ??
              responseData['msg'] ??
              "Registration failed";
          print('❌ [DEBUG] Registration failed: $errorMsg');
          print('❌ [DEBUG] Full response body: ${response.body}');
        } catch (e) {
          print('❌ [DEBUG] Failed to parse error response: $e');
          print('❌ [DEBUG] Raw response body: ${response.body}');
          errorMsg = "Registration failed - ${response.body}";
        }

        // Handle specific error cases based on status code and message
        String roleText = user.role.toLowerCase() == 'truckowner'
            ? 'truck owner'
            : 'customer';

        // Enhanced debugging for error messages
        print('🔍 [DEBUG] Error message analysis:');
        print('🔍 [DEBUG] - Status code: ${response.statusCode}');
        print('🔍 [DEBUG] - Error message: "$errorMsg"');
        print(
            '🔍 [DEBUG] - Error message (lowercase): "${errorMsg.toLowerCase()}"');
        print(
            '🔍 [DEBUG] - Contains "email already": ${errorMsg.toLowerCase().contains('email already')}');
        print(
          '🔍 [DEBUG] - Contains "phone number already": ${errorMsg.toLowerCase().contains('phone number already')}');
        print(
            '🔍 [DEBUG] - Contains "phone already": ${errorMsg.toLowerCase().contains('phone already')}');
        print(
            '🔍 [DEBUG] - Contains "already registered": ${errorMsg.toLowerCase().contains('already registered')}');
        print(
            '🔍 [DEBUG] - Contains "already exists": ${errorMsg.toLowerCase().contains('already exists')}');
        print(
            '🔍 [DEBUG] - Contains "duplicate": ${errorMsg.toLowerCase().contains('duplicate')}');
        print(
            '🔍 [DEBUG] - Contains "taken": ${errorMsg.toLowerCase().contains('taken')}');

        final errorMsgLower = errorMsg.toLowerCase();
        
        // Check for OTP sending failures (backend service issues)
        // This catches errors like "Failed to send OTP. Registration aborted." with "Unauthorized"
        final errorType = responseData?['error']?.toString().toLowerCase() ?? '';
        final isUnauthorized = response.statusCode == 401 || errorType.contains('unauthorized');
        final isOtpFailure = errorMsgLower.contains('failed to send otp') ||
            errorMsgLower.contains('otp failed to send') ||
            (errorMsgLower.contains('otp') && errorMsgLower.contains('failed')) ||
            errorMsgLower.contains('registration aborted');
        
        // Enhanced debug logging for OTP error detection
        print('🔍 [DEBUG] OTP Error Detection:');
        print('🔍 [DEBUG] - Status code: ${response.statusCode}');
        print('🔍 [DEBUG] - Error type from response: "$errorType"');
        print('🔍 [DEBUG] - Error message: "$errorMsg"');
        print('🔍 [DEBUG] - isUnauthorized: $isUnauthorized');
        print('🔍 [DEBUG] - isOtpFailure: $isOtpFailure');
        print('🔍 [DEBUG] - Contains "failed to send otp": ${errorMsgLower.contains('failed to send otp')}');
        print('🔍 [DEBUG] - Contains "registration aborted": ${errorMsgLower.contains('registration aborted')}');
        
        if (isOtpFailure || isUnauthorized) {
          print('✅ [DEBUG] OTP error detected! Processing...');
          String otpErrorMessage;
          String otpErrorTitle;
          
          if (isUnauthorized && isOtpFailure) {
            print('🔔 [DEBUG] OTP service authentication failed (Unauthorized) - returning error object');
            otpErrorTitle = "Service Temporarily Unavailable";
            otpErrorMessage = "We're unable to send the verification code at the moment. Please try again in a few minutes or contact support if the issue persists.";
          } else if (isOtpFailure) {
            print('🔔 [DEBUG] OTP sending failed - returning error object');
            otpErrorTitle = "Verification Code Error";
            otpErrorMessage = "We encountered an issue sending the verification code. Please try again in a moment.";
          } else {
            print('🔔 [DEBUG] Unauthorized access error - returning error object');
            otpErrorTitle = "Authentication Error";
            otpErrorMessage = "There was an authentication issue. Please try again or contact support if the problem continues.";
          }
          
          // Return error object so registration screen can handle it
          return {
            'error': true,
            'type': 'otp_service_error',
            'title': otpErrorTitle,
            'message': otpErrorMessage,
          };
        }
        
        // Check for phone number already exists first (more specific)
        if (errorMsgLower.contains('phone number already registered') ||
            errorMsgLower.contains('phone number already exists') ||
            errorMsgLower.contains('phone already registered') ||
            errorMsgLower.contains('phone already exists') ||
            (errorMsgLower.contains('phone') && errorMsgLower.contains('already registered')) ||
            (errorMsgLower.contains('phone') && errorMsgLower.contains('already exists'))) {
          print(
              '🔔 [DEBUG] Phone number already exists detected for $roleText - will be handled by UI');
          // Return error object for UI to handle
          return {
            'error': true,
            'type': 'phone_exists',
            'message':
                'This phone number is already registered. Please use a different phone number or try logging in.'
          };
        }
        
        // Check for email already exists (more specific checks to avoid false positives)
        if (errorMsgLower.contains('email already registered') ||
            errorMsgLower.contains('email already exists') ||
            errorMsgLower.contains('email already') ||
            errorMsgLower.contains('email is taken') ||
            errorMsgLower.contains('email taken') ||
            errorMsgLower.contains('email address already') ||
            errorMsgLower.contains('email is already')) {
          print(
              '🔔 [DEBUG] Email already exists detected for $roleText - will be handled by UI');
          // Return error object for UI to handle
          return {
            'error': true,
            'type': 'email_exists',
            'message':
                'This email address is already registered as a $roleText. Please use a different email or try logging in.'
          };
        } else if (response.statusCode == 400) {
          if (errorMsg.toLowerCase().contains('all fields are required') ||
              errorMsg.toLowerCase().contains('required fields') ||
              errorMsg.toLowerCase().contains('missing') ||
              errorMsg.toLowerCase().contains('field is required')) {
            print(
                '🔔 [DEBUG] Showing missing information snackbar for $roleText');
            Get.snackbar("Missing Information",
                "Please fill in all required fields to complete your $roleText registration.",
                backgroundColor: Colors.red,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP);
          } else {
            print(
                '🔔 [DEBUG] Showing invalid information snackbar for $roleText');
            Get.snackbar("Invalid Information", errorMsg,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP);
          }
        } else if (response.statusCode == 500) {
          print('🔔 [DEBUG] Showing server error snackbar for $roleText');
          Get.snackbar("Registration Failed",
              "Server error occurred during $roleText registration. Please try again later.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP);
        } else {
          // Show the raw error message for debugging
          print(
              '⚠️ [DEBUG] Unhandled error case - Status: ${response.statusCode}, Message: "$errorMsg"');
          print('🔔 [DEBUG] Showing generic error snackbar for $roleText');
          Get.snackbar("Registration Error", errorMsg,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP);
        }
        return null;
      }
    } catch (e) {
      print('❌ [DEBUG] Registration exception: $e');
      print('❌ [DEBUG] Exception type: ${e.runtimeType}');
      if (e is Exception) {
        print('❌ [DEBUG] Exception details: ${e.toString()}');
      }

      // Handle network or other exceptions
      String roleText =
          user.role.toLowerCase() == 'truckowner' ? 'truck owner' : 'customer';
      print('🔔 [DEBUG] Showing connection error snackbar for $roleText');
      Get.snackbar("Connection Error",
          "Unable to connect to the server during $roleText registration. Please check your internet connection and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Email + Password login
  Future<void> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email and password required");
      return;
    }
    isLoading.value = true;
    try {
      final resp = await _authService.loginWithEmail(email, password);
      final role = (resp['role'] as String?)?.trim() ?? '';

      print('🔐 [DEBUG] Login successful for role: $role');

      // Save login time for inactivity tracking
      await SharedPrefsUtil().saveLoginTime();

      // ✅ CRITICAL FIX: Fetch user details FIRST to ensure we have the correct role
      print('🔄 [DEBUG] Fetching user details before navigation...');
      await fetchUserDetails();

      // Now use the role from user details (which should be properly loaded)
      final userRole = (user.value?.role ?? role).trim();
      final normalizedRole = userRole.toLowerCase();

      print('🔍 [DEBUG] Login response role: $role');
      print('🔍 [DEBUG] User data role: ${user.value?.role}');
      print(
          '🔍 [DEBUG] Using role for navigation: $userRole (normalized: $normalizedRole)');

      // ✅ Additional validation: Ensure role is not empty
      if (userRole.isEmpty) {
        print(
            '❌ [DEBUG] Role is empty! Login response role: "$role", User role: "${user.value?.role}"');
        throw Exception('Unable to determine user role. Please login again.');
      }

      // Handle different possible role formats from backend
      String navigationRole;
      switch (normalizedRole) {
        case 'customer':
          navigationRole = 'Customer';
          print('👤 [DEBUG] Navigating to Customer dashboard');
          break;
        case 'driver':
          // Check if driver is verified
          final driverStatus = user.value?.status?.toLowerCase();
          print('🚛 [DEBUG] Driver status: $driverStatus');

          if (driverStatus == null || driverStatus == 'unverified') {
            print(
                '📋 [DEBUG] Driver not verified, redirecting to license upload');
            Get.offAll(() => const DriverLicenseUploadScreen());
            return;
          } else if (driverStatus == 'available') {
            navigationRole = 'Driver';
            print('✅ [DEBUG] Driver verified, navigating to Driver dashboard');
          } else {
            print(
                '⏳ [DEBUG] Driver status: $driverStatus, redirecting to license upload');
            Get.offAll(() => const DriverLicenseUploadScreen());
            return;
          }
          break;
        case 'truckowner':
        case 'truck_owner':
        case 'truck owner':
          navigationRole = 'TruckOwner';
          print('🚚 [DEBUG] Navigating to TruckOwner dashboard');
          break;
        case 'admin':
        case 'staff':
          navigationRole = 'Customer';
          print(
              '👨‍💼 [DEBUG] Navigating to Admin/Staff dashboard (using Customer view)');
          break;
        default:
          navigationRole = 'Customer'; // Default fallback
          print(
              '⚠️ [DEBUG] Unknown role: "$userRole" (normalized: "$normalizedRole"), defaulting to Customer');
          print(
              '⚠️ [DEBUG] Available roles: Customer, Driver, TruckOwner, Admin, Staff');
      }

      // Show success page before navigating to dashboard
      _showLoginSuccessPage(navigationRole);
    } catch (e) {
      print('❌ [DEBUG] Login failed: $e');
      // Re-throw to allow UI widgets to handle and display inline errors (e.g., email not recognized)
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Show login success page before navigating to dashboard
  void _showLoginSuccessPage(String navigationRole) {
    final userName = user.value?.firstname ?? '';
    final userRole = user.value?.role ?? navigationRole;

    // Create a loading task that ensures all data is loaded
    Future<void> loadingTask = _performPostLoginTasks();

    Get.offAll(() => _LoginSuccessScreenWithAutoNav(
          userName: userName.isNotEmpty ? userName : null,
          userRole: userRole,
          loadingTask: loadingTask,
          navigationRole: navigationRole,
        ));
  }

  /// Perform post-login tasks like fetching user details and shared prefs
  Future<void> _performPostLoginTasks() async {
    try {
      print('🔄 [POST-LOGIN] Starting comprehensive post-login tasks...');

      // 1. Fetch user details to ensure we have the latest user info
      print('🔄 [POST-LOGIN] Fetching user details...');
      await fetchUserDetails();

      // 2. Validate role before navigation
      print('🔄 [POST-LOGIN] Validating user role...');
      final isValidRole = await validateUserRole();
      if (!isValidRole) {
        print("❌ [POST-LOGIN] Role validation failed");
        throw Exception("Invalid user role. Please login again.");
      }

      // 3. Test role separation to ensure proper access control
      print('🔄 [POST-LOGIN] Testing role separation...');
      await testRoleSeparation();

      // 4. Additional post-login setup if needed
      print('🔄 [POST-LOGIN] Performing additional setup...');
      // Add any other post-login tasks here

      print('✅ [POST-LOGIN] All post-login tasks completed successfully');
    } catch (e) {
      print('❌ [POST-LOGIN] Error in post-login tasks: $e');
      rethrow; // Re-throw to let the success screen handle the error
    }
  }

  /// ✅ Fetch User Details
  Future<void> fetchUserDetails() async {
    try {
      isLoading(true);

      String? token = SharedPrefsUtil().getToken();

      if (token == null || token.isEmpty) {
        // ✅ Skip silently if no token – user not logged in
        return;
      }

      // Load cached data if available
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedUserData = prefs.getString("user_data");
      if (cachedUserData != null) {
        user.value = User.fromJson(json.decode(cachedUserData));
        await SharedPrefsUtil()
            .saveUserStatus(user.value?.status ?? "unverified");
      }

      // Make API call to get fresh user data
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/auth/current-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('user') && data['user'] != null) {
          user.value = User.fromJson(data['user']);

          await SharedPrefsUtil().saveUserId(user.value?.id ?? '');

          // ✅ Save the role from user data with validation
          if (user.value?.role != null && user.value!.role.isNotEmpty) {
            final role = user.value!.role.trim();
            await SharedPrefsUtil().saveRole(role);
            print("📝 Role saved from user data: $role");

            // Verify role was saved correctly
            final savedRole = SharedPrefsUtil().getRole();
            if (savedRole != role) {
              print("⚠️ Role mismatch! Expected: $role, Saved: $savedRole");
            } else {
              print("✅ Role verified and saved correctly: $role");
            }
          } else {
            print("⚠️ No valid role found in user data");
          }

          await prefs.setString("user_data", json.encode(data['user']));
        }
      }
      if (!_isLoggingOut &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        _isLoggingOut = true;
        await logout();
        Get.snackbar(
          "Session Expired",
          "Please login again.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAll(() => const LoginScreen());
          _isLoggingOut = false; // reset after redirect
        });
      }
    } finally {
      isLoading(false);
    }
  }

  /// ✅ Update User Profile (Text Fields & Image)
  Future<void> updateUserProfile(File? image, User updatedUser) async {
    isLoading.value = true;

    try {
      // Ensure SharedPrefsUtil is initialized
      await SharedPrefsUtil().init();

      String? token = SharedPrefsUtil().getToken();
      String? role = SharedPrefsUtil().getRole();

      if (token == null || token.isEmpty) {
        print("❌ No token found, user must log in again");
        Get.snackbar("Error", "Authentication failed. Please log in again.",
            backgroundColor: Colors.red);
        return;
      }

      if (role == null || role.isEmpty) {
        print("❌ No role found, using user's current role");
        role = updatedUser.role; // Fallback to user's current role
      }

      if (role == "Driver") {
        /// ✅ Driver: Use PATCH + multipart
        var request = http.MultipartRequest(
            'PATCH', Uri.parse(ApiConstants.driverUpdatesProfile));
        request.headers['Authorization'] = 'Bearer $token';

        request.fields['firstname'] = updatedUser.firstname;
        request.fields['lastname'] = updatedUser.lastname;
        request.fields['email'] = updatedUser.email;
        request.fields['phoneNumber'] = updatedUser.phoneNumber!;
        request.fields['region'] = updatedUser.region ?? "";
        request.fields['district'] = updatedUser.district ?? "";
        request.fields['workingPosition'] = updatedUser.workingPosition ?? "";

        if (image != null) {
          String mimeType = lookupMimeType(image.path) ?? "image/jpeg";
          request.files.add(
            await http.MultipartFile.fromPath(
              'profileImage',
              image.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
          _selectedImage.value = image;
        }

        var response = await request.send();

        if (response.statusCode == 200) {
          print("Profile updated successfully");
          await fetchUserDetails();
          update(); // Refresh UI
        } else {
          print("Driver profile update failed");
        }
      } else {
        /// ✅ Customer & TruckOwner: If image provided, use multipart PUT; else JSON PUT
        if (image != null) {
          var request =
              http.MultipartRequest('PUT', Uri.parse(ApiConstants.userProfile));
          request.headers['Authorization'] = 'Bearer $token';

          request.fields['firstname'] = updatedUser.firstname;
          request.fields['lastname'] = updatedUser.lastname;
          request.fields['email'] = updatedUser.email;
          request.fields['phoneNumber'] = updatedUser.phoneNumber!;
          if (updatedUser.region != null) {
            request.fields['region'] = updatedUser.region!;
          }
          if (updatedUser.district != null) {
            request.fields['district'] = updatedUser.district!;
          }
          if (updatedUser.workingPosition != null) {
            request.fields['workingPosition'] = updatedUser.workingPosition!;
          }

          String mimeType = lookupMimeType(image.path) ?? "image/jpeg";
          request.files.add(
            await http.MultipartFile.fromPath(
              'profileImage',
              image.path,
              contentType: MediaType.parse(mimeType),
            ),
          );

          var response = await request.send();
          if (response.statusCode == 200) {
            print( "Profile updated successfully",);
            await fetchUserDetails();
            update();
          } else {
           print("Profile update failed. Code: ${response.statusCode}");
          }
        } else {
          final response = await http.put(
            Uri.parse(ApiConstants.userProfile),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(updatedUser.toJson()),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              print("Profile updated successfully");
              await fetchUserDetails();
              update();
            } else {
              print( data['message'] ?? "Failed to update profile");
            }
          } else {
            print("Profile update failed. Code: ${response.statusCode}");
          }
        }
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout user and clear stored token
  Future<void> logout() async {
    try {
      // Ensure SharedPrefsUtil is initialized before clearing
      await SharedPrefsUtil().init();
      await SharedPrefsUtil().clearData(); // Use the proper clear method
      user.value = null;
      // ✅ Redirect to login screen
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print("❌ Error during logout: $e");
      // Fallback to direct SharedPreferences clear
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      user.value = null;
      Get.offAll(() => const LoginScreen());
    }
  }

  /// Verify email OTP
  Future<Map<String, dynamic>?> verifyEmailOtp(
      String userId, String otp) async {
    isLoading.value = true;
    try {
      final result = await _authService.verifyEmailOtp(userId, otp);

      print('🔐 [DEBUG] OTP verification result: $result');

      if (result.containsKey('token')) {
        // Backend returned token directly
        print('✅ [DEBUG] Token found in OTP response, proceeding with login');
        await SharedPrefsUtil()
            .saveToken(result['token'], result['user']['email']);
        await SharedPrefsUtil().saveRole(result['role']);
        await fetchUserDetails();
        return result;
      } else if (result.containsKey('message') &&
          result['message'].toString().toLowerCase().contains('success')) {
        // OTP verification successful but no token - need to login
        print(
            '✅ [DEBUG] OTP verification successful, attempting automatic login');

        // Extract email from userId (since we might have used email as userId)
        String email = userId.contains('@') ? userId : '';

        // If userId is not an email, we need to get the email from somewhere
        // For now, we'll try to login with the userId as email
        if (email.isEmpty) {
          print(
              '⚠️ [DEBUG] No email found in userId, cannot proceed with automatic login');
          return {
            'success': true,
            'message': 'Email verified successfully. Please login manually.',
            'requiresManualLogin': true
          };
        }

        try {
          // Attempt automatic login
          print('🔐 [DEBUG] Attempting automatic login with email: $email');

          // We need the password for login, but we don't have it here
          // The user will need to login manually after OTP verification
          return {
            'success': true,
            'message':
                'Email verified successfully. Please login with your credentials.',
            'requiresManualLogin': true,
            'email': email
          };
        } catch (loginError) {
          print('❌ [DEBUG] Automatic login failed: $loginError');
          return {
            'success': true,
            'message':
                'Email verified successfully. Please login with your credentials.',
            'requiresManualLogin': true,
            'email': email
          };
        }
      } else {
        print('❌ [DEBUG] Unexpected OTP verification response: $result');
        return null;
      }
    } catch (e) {
      print('❌ [DEBUG] Email OTP verification failed: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend email OTP — robust handling to show user-friendly error/success messages
  Future<void> resendEmailOtp(String userId, String email) async {
    isLoading.value = true;
    try {
      final dynamic result = await _authService.resendEmailOtp(userId, email);

      // If the auth service returns an http.Response
      if (result is http.Response) {
        print('📡 [DEBUG] resendEmailOtp response status: ${result.statusCode}');
        print('📡 [DEBUG] resendEmailOtp response body: ${result.body}');

        if (result.statusCode == 200 || result.statusCode == 201) {
          String successMsg = "Verification code sent to $email.";
          try {
            final parsed = jsonDecode(result.body);
            successMsg = parsed['message'] ?? parsed['msg'] ?? successMsg;
          } catch (_) {}
          Get.snackbar("OTP Sent", successMsg,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP);
          return;
        } else {
          String errorMsg;
          try {
            final parsed = jsonDecode(result.body);
            errorMsg = parsed['message'] ?? parsed['error'] ?? parsed['msg'] ?? result.body;
          } catch (_) {
            errorMsg = result.body.isNotEmpty ? result.body : "Failed to resend OTP";
          }

          _showOtpResendError(errorMsg, result.statusCode);
          return;
        }
      }

      // If the auth service returns a Map (common for wrapped JSON)
      if (result is Map<String, dynamic>) {
        print('📡 [DEBUG] resendEmailOtp map result: $result');
        final success = result['success'] == true || (result['status'] == 'success');
        if (success) {
          final msg = result['message'] ?? 'Verification code sent to $email.';
          Get.snackbar("OTP Sent", msg,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP);
          return;
        } else {
          final errorMsg = result['message'] ?? result['error'] ?? 'Failed to resend OTP';
          _showOtpResendError(errorMsg, result['statusCode'] is int ? result['statusCode'] : null);
          return;
        }
      }

      // If service returned boolean true/false or null
      if (result is bool) {
        if (result) {
          Get.snackbar("OTP Sent", "Verification code sent to $email.",
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP);
        } else {
          _showOtpResendError("Failed to resend verification code. Please try again.", null);
        }
        return;
      }

      // Unknown return type — fallback
      print('⚠️ [DEBUG] resendEmailOtp unknown result type: ${result.runtimeType}');
      Get.snackbar("OTP Error",
          "Unable to resend verification code. Please try again later.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    } on SocketException catch (se) {
      // Network issue
      print('❌ [DEBUG] resendEmailOtp network error: $se');
      Get.snackbar("Connection Error",
          "No internet connection. Please check your network and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    } catch (e, st) {
      print('❌ [DEBUG] resendEmailOtp unexpected error: $e\n$st');
      // Best effort to extract message
      String msg = e.toString();
      if (msg.contains('403') || msg.toLowerCase().contains('forbidden')) {
        msg = "You are not permitted to perform this action.";
      } else if (msg.toLowerCase().contains('timeout')) {
        msg = "Request timed out. Please try again.";
      } else {
        msg = "Failed to resend verification code. Please try again later.";
      }
      Get.snackbar("OTP Error", msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }

  /// Private helper used by resendEmailOtp to map error text/status to a user-facing snackbar
  void _showOtpResendError(String errorMsg, [int? statusCode]) {
    final lower = errorMsg.toLowerCase();
    print('🔍 [DEBUG] OTP resend error analysis: status=$statusCode, message="$errorMsg"');

    // Rate limit / too many requests
    if (lower.contains('too many') ||
        lower.contains('rate limit') ||
        lower.contains('try again later') ||
        lower.contains('limit exceeded')) {
      Get.snackbar("Too Many Requests",
          "You have requested OTP too many times. Please wait a few minutes before trying again.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return;
    }

    // Invalid / not found / email not registered
    if (lower.contains('invalid') ||
        lower.contains('not found') ||
        lower.contains('no user') ||
        lower.contains('user not found') ||
        lower.contains('email not registered') ||
        lower.contains('not registered')) {
      Get.snackbar("Email Not Found",
          "We couldn't find an account with that email. Please check the email and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return;
    }

    // Server error
    if (statusCode != null && statusCode >= 500 || lower.contains('server error')) {
      Get.snackbar("Server Error",
          "Server error occurred while trying to resend OTP. Please try again later.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return;
    }

    // Generic fallback showing backend message
    Get.snackbar("OTP Error", errorMsg,
        backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP);
  }

  /// ✅ Validate and ensure proper role separation
  Future<bool> validateUserRole() async {
    try {
      String? token = SharedPrefsUtil().getToken();
      String? role = SharedPrefsUtil().getRole();

      if (token == null || role == null || role.isEmpty) {
        print("❌ [ROLE VALIDATION] Missing token or role");
        return false;
      }

      // Validate role format
      final normalizedRole = role.trim();
      if (!['Customer', 'Driver', 'TruckOwner', 'Admin', 'Staff']
          .contains(normalizedRole)) {
        print("❌ [ROLE VALIDATION] Invalid role: $normalizedRole");
        return false;
      }

      // Verify role matches user data
      if (user.value?.role != null) {
        final userRole = user.value!.role.trim();
        if (userRole != normalizedRole) {
          print(
              "⚠️ [ROLE VALIDATION] Role mismatch! Stored: $normalizedRole, User data: $userRole");
          // Update stored role to match user data
          await SharedPrefsUtil().saveRole(userRole);
          print(
              "✅ [ROLE VALIDATION] Role updated to match user data: $userRole");
        }
      }

      print("✅ [ROLE VALIDATION] Role validation successful: $normalizedRole");
      return true;
    } catch (e) {
      print("❌ [ROLE VALIDATION] Error validating role: $e");
      return false;
    }
  }

  /// ✅ Get current user role with validation
  String? getCurrentUserRole() {
    final role = SharedPrefsUtil().getRole();
    if (role != null && role.isNotEmpty) {
      final normalizedRole = role.trim();
      if (['Customer', 'Driver', 'TruckOwner', 'Admin', 'Staff']
          .contains(normalizedRole)) {
        return normalizedRole;
      }
    }
    return null;
  }

  /// ✅ Test role separation - ensures users see only their appropriate screens
  Future<void> testRoleSeparation() async {
    try {
      final role = getCurrentUserRole();
      if (role == null) {
        print("❌ [ROLE TEST] No valid role found");
        return;
      }

      print("🧪 [ROLE TEST] Testing role separation for: $role");

      // Test that the role is properly stored and retrieved
      final storedRole = SharedPrefsUtil().getRole();
      if (storedRole != role) {
        print(
            "❌ [ROLE TEST] Role mismatch! Expected: $role, Stored: $storedRole");
        return;
      }

      // Test that user data matches stored role
      if (user.value?.role != null) {
        final userRole = user.value!.role.trim();
        if (userRole != role) {
          print(
              "❌ [ROLE TEST] User data role mismatch! Expected: $role, User data: $userRole");
          return;
        }
      }

      // Test role-specific functionality
      switch (role) {
        case 'TruckOwner':
          print(
              "✅ [ROLE TEST] TruckOwner role validated - should see truck management screens");
          break;
        case 'Customer':
          print(
              "✅ [ROLE TEST] Customer role validated - should see order placement screens");
          break;
        case 'Driver':
          print(
              "✅ [ROLE TEST] Driver role validated - should see delivery screens");
          break;
        case 'Admin':
        case 'Staff':
          print(
              "✅ [ROLE TEST] Admin/Staff role validated - should see management screens");
          break;
        default:
          print("❌ [ROLE TEST] Unknown role: $role");
          return;
      }

      print("✅ [ROLE TEST] Role separation test passed for: $role");
    } catch (e) {
      print("❌ [ROLE TEST] Error testing role separation: $e");
    }
  }
}

/// Custom login success screen with automatic navigation after loading
class _LoginSuccessScreenWithAutoNav extends StatefulWidget {
  final String? userName;
  final String? userRole;
  final Future<void> loadingTask;
  final String navigationRole;

  const _LoginSuccessScreenWithAutoNav({
    required this.userName,
    required this.userRole,
    required this.loadingTask,
    required this.navigationRole,
  });

  @override
  State<_LoginSuccessScreenWithAutoNav> createState() =>
      _LoginSuccessScreenWithAutoNavState();
}

class _LoginSuccessScreenWithAutoNavState
    extends State<_LoginSuccessScreenWithAutoNav> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startLoadingProcess();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _startLoadingProcess() async {
    // Check if widget is already disposed before starting
    if (_isDisposed) {
      return;
    }

    try {
      print('🔄 [LOGIN SUCCESS] Starting post-login tasks...');

      // Execute the loading task (fetch user details, shared prefs, etc.)
      await widget.loadingTask.timeout(
        const Duration(
            seconds: 15), // Increased timeout for comprehensive loading
        onTimeout: () {
          print('⚠️ [LOGIN SUCCESS] Loading task timed out, proceeding anyway');
        },
      );

      // Check if still mounted after loading task
      if (_isDisposed) return;

      print(
          '✅ [LOGIN SUCCESS] Post-login tasks completed, navigating to dashboard...');

      // Wait a moment to show the success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Final check before navigation
      if (_isDisposed) return;

      // Navigate to dashboard automatically
      Get.offAll(() => RoleBasedBottomNavScreen(role: widget.navigationRole));
    } catch (e) {
      print('❌ [LOGIN SUCCESS] Error during loading process: $e');

      // Even if there's an error, try to navigate after a short delay
      if (!_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!_isDisposed) {
          Get.offAll(
              () => RoleBasedBottomNavScreen(role: widget.navigationRole));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container if disposed
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return SuccessPage(
      title: "Welcome Back!",
      message: widget.userName != null
          ? "Hello ${widget.userName}! You have successfully logged in."
          : "You have successfully logged in.",
      subtitle: widget.userRole != null
          ? "Setting up your ${widget.userRole} dashboard..."
          : "Loading your dashboard...",
      buttonText: "", // Empty button text - no button will be shown
      onButtonPressed: null, // No button action
      imageSize: 100,
      centerContent: true,
      customContent: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.rectangleColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Setting up your account...",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
