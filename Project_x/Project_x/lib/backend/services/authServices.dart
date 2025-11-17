
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_constants.dart';
import '../../utils/shared_pref_utils.dart';
import '../models/user_model.dart';

class AuthService {
  Future<http.Response> registerTruckOwner(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerWithEmailUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      return response;
    } catch (e) {
      rethrow; // Allow controller to handle the exception
    }
  }

  Future<http.Response> registerWithEmail(Map<String, dynamic> userData) async {
    try {
      print('🌐 [DEBUG] Making HTTP request to: ${ApiConstants.registerWithEmailUrl}');
      print('🌐 [DEBUG] Request headers: ${{'Content-Type': 'application/json'}}');
      print('🌐 [DEBUG] Request body: ${jsonEncode(userData)}');
      final response = await http.post(
        Uri.parse(ApiConstants.registerWithEmailUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      print('🌐 [DEBUG] Response received with status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ [DEBUG] HTTP request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    print('🌐 [DEBUG] Making login request to: ${ApiConstants.loginWithEmailUrl}');
    print('🌐 [DEBUG] Login credentials: email=$email, hasPassword=${password.isNotEmpty}');
    final response = await http.post(
      Uri.parse(ApiConstants.loginWithEmailUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "password": password}),
    );

    print('🌐 [DEBUG] Login response status: ${response.statusCode}');
    print('🌐 [DEBUG] Login response body: ${response.body}');

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['token'] != null) {
      print('✅ [DEBUG] Login successful, saving token...');
      await SharedPrefsUtil().saveToken(decoded['token'], email);

      // ✅ Save role if available in response with validation
      if (decoded['role'] != null && decoded['role'].toString().isNotEmpty) {
        final role = decoded['role'].toString().trim();
        await SharedPrefsUtil().saveRole(role);
        print('✅ [DEBUG] Role saved: $role');
        
        // Verify role was saved correctly
        final savedRole = SharedPrefsUtil().getRole();
        if (savedRole == role) {
          print('✅ [DEBUG] Role verification successful: $role');
        } else {
          print('⚠️ [DEBUG] Role verification failed. Expected: $role, Got: $savedRole');
        }
      } else {
        print('⚠️ [DEBUG] No role found in login response');
      }
      
      print('✅ [DEBUG] Token saved successfully');
      return decoded;
    }
    print('❌ [DEBUG] Login failed: ${decoded['message'] ?? 'Unknown error'}');
    throw Exception(decoded['message'] ?? 'Login failed');
  }

  /// profile updates
  Future<void> updateUserProfile(User updatedUser) async {
    String? token = SharedPrefsUtil().getToken();
    if (token == null) {
      Get.snackbar("Error", "User not authenticated.");
      return;
    }

    try {
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
          Get.snackbar("Success", "Profile updated successfully");
        } else {
          Get.snackbar("Error", data['message'] ?? "Failed to update profile");
        }
      } else {
        Get.snackbar("Error", "Failed to update profile. Code: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e");
    }
  }
  
  /// Email OTP verification
  Future<Map<String, dynamic>> verifyEmailOtp(String userId, String otp) async {
    try {
      print('🔐 [DEBUG] Verifying email OTP for userId: $userId');
      print('🔐 [DEBUG] OTP: $otp');
      print('🔐 [DEBUG] API URL: ${ApiConstants.verifyEmailOtpUrl}');
      
      // Try with userId first
      Map<String, dynamic> requestBody = {"userId": userId, "emailOTP": otp};
      print('🔐 [DEBUG] Request body: ${jsonEncode(requestBody)}');
      
      var response = await http.post(
        Uri.parse(ApiConstants.verifyEmailOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🔐 [DEBUG] Response status: ${response.statusCode}');
      print('🔐 [DEBUG] Response body: ${response.body}');

      // If userId approach fails, try with email as fallback
      if (response.statusCode != 200) {
        print('🔄 [DEBUG] userId approach failed, trying email approach...');
        
        // Extract email from userId if it looks like an email
        String? email;
        if (userId.contains('@')) {
          email = userId;
        } else {
          // If userId is not an email, we need to get the email from somewhere
          // For now, we'll try the userId as is
          email = userId;
        }
        
        requestBody = {"email": email, "otp": otp};
        print('🔄 [DEBUG] Fallback request body: ${jsonEncode(requestBody)}');
        
        response = await http.post(
          Uri.parse(ApiConstants.verifyEmailOtpUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );
        
        print('🔄 [DEBUG] Fallback response status: ${response.statusCode}');
        print('🔄 [DEBUG] Fallback response body: ${response.body}');
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        print('✅ [DEBUG] OTP verification successful');
        return data;
      } else {
        print('❌ [DEBUG] OTP verification failed: ${data['message'] ?? 'Unknown error'}');
        throw Exception(data['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      print('❌ [DEBUG] OTP verification exception: $e');
      rethrow;
    }
  }

  /// Resend email OTP
  Future<void> resendEmailOtp(String userId, String email) async {
    try {
      print('📧 [DEBUG] Resending email OTP for userId: $userId');
      print('📧 [DEBUG] Email: $email');
      print('📧 [DEBUG] API URL: ${ApiConstants.resendEmailOtpUrl}');
      
      // Try with userId first
      Map<String, dynamic> requestBody = {"userId": userId, "email": email};
      print('📧 [DEBUG] Request body: ${jsonEncode(requestBody)}');
      
      var response = await http.post(
        Uri.parse(ApiConstants.resendEmailOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📧 [DEBUG] Resend OTP response status: ${response.statusCode}');
      print('📧 [DEBUG] Resend OTP response body: ${response.body}');

      // If userId approach fails, try with email only as fallback
      if (response.statusCode != 200) {
        print('🔄 [DEBUG] userId approach failed for resend, trying email approach...');
        
        requestBody = {"email": email};
        print('🔄 [DEBUG] Fallback resend request body: ${jsonEncode(requestBody)}');
        
        response = await http.post(
          Uri.parse(ApiConstants.resendEmailOtpUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );
        
        print('🔄 [DEBUG] Fallback resend response status: ${response.statusCode}');
        print('🔄 [DEBUG] Fallback resend response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        print('✅ [DEBUG] OTP resend successful');
      } else {
        final data = jsonDecode(response.body);
        print('❌ [DEBUG] OTP resend failed: ${data['message'] ?? 'Unknown error'}');
        throw Exception(data['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      print('❌ [DEBUG] OTP resend exception: $e');
      rethrow;
    }
  }

  /// Forgot Password - Send reset link to email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔐 [DEBUG] Sending forgot password request for email: $email');
      print('🔐 [DEBUG] API URL: ${ApiConstants.forgotPasswordUrl}');
      
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      print('🔐 [DEBUG] Forgot password response status: ${response.statusCode}');
      print('🔐 [DEBUG] Forgot password response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ [DEBUG] Forgot password request successful');
        return data;
      } else {
        print('❌ [DEBUG] Forgot password failed: ${data['message'] ?? 'Unknown error'}');
        throw Exception(data['message'] ?? 'Failed to send reset link');
      }
    } catch (e) {
      print('❌ [DEBUG] Forgot password exception: $e');
      rethrow;
    }
  }

  /// Reset Password - Reset password with token
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      print('🔐 [DEBUG] Resetting password with token: ${token.substring(0, 10)}...');
      print('🔐 [DEBUG] API URL: ${ApiConstants.resetPasswordUrl}/$token');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.resetPasswordUrl}/$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"password": newPassword}),
      );

      print('🔐 [DEBUG] Reset password response status: ${response.statusCode}');
      print('🔐 [DEBUG] Reset password response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ [DEBUG] Password reset successful');
        return data;
      } else {
        print('❌ [DEBUG] Password reset failed: ${data['message'] ?? 'Unknown error'}');
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('❌ [DEBUG] Password reset exception: $e');
      rethrow;
    }
  }

  /// Update Password - Update password for logged-in user
  Future<Map<String, dynamic>> updatePassword(String currentPassword, String newPassword) async {
    try {
      String? token = SharedPrefsUtil().getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      print('🔐 [DEBUG] Updating password for authenticated user');
      print('🔐 [DEBUG] API URL: ${ApiConstants.updatePasswordUrl}');
      
      final response = await http.post(
        Uri.parse(ApiConstants.updatePasswordUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      print('🔐 [DEBUG] Update password response status: ${response.statusCode}');
      print('🔐 [DEBUG] Update password response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ [DEBUG] Password update successful');
        return data;
      } else {
        print('❌ [DEBUG] Password update failed: ${data['message'] ?? 'Unknown error'}');
        throw Exception(data['message'] ?? 'Failed to update password');
      }
    } catch (e) {
      print('❌ [DEBUG] Password update exception: $e');
      rethrow;
    }
  }
}
