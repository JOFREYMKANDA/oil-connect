import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/backend/controllers/authController.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:oil_connect/screens/login screens/login.dart';
import 'package:oil_connect/screens/login screens/registration.dart';
import 'package:oil_connect/screens/common/success_page.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';

class EmailOtpVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;
  final String otpType;
  final String? role; // Add role parameter for back navigation

  const EmailOtpVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
    required this.otpType,
    this.role, // Make role optional for backward compatibility
  });

  @override
  State<EmailOtpVerificationScreen> createState() => _EmailOtpVerificationScreenState();
}

class _EmailOtpVerificationScreenState extends State<EmailOtpVerificationScreen> {
  final RegisterController _controller = Get.put(RegisterController());
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();
  final RxString otpError = ''.obs;
  final RxBool isLoading = false.obs;
  final RxInt resendCountdown = 0.obs;
  Timer? _resendTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Start countdown timer when screen loads
    _startResendCountdown();
  }

  @override
  void dispose() {
    _isNavigating = true; // Prevent any pending navigation
    _resendTimer?.cancel();
    
    // Safely dispose controllers
    try {
      otpController.dispose();
    } catch (e) {
      print('⚠️ [DEBUG] Error disposing OTP controller: $e');
    }
    
    try {
      otpFocusNode.dispose();
    } catch (e) {
      print('⚠️ [DEBUG] Error disposing focus node: $e');
    }
    
    super.dispose();
  }

  void _startResendCountdown() {
    resendCountdown.value = 60; // 60 seconds countdown
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// Handle back navigation - go back to registration screen if role is available
  void _handleBackNavigation() {
    if (_isNavigating) {
      print('⚠️ [DEBUG] Navigation in progress, ignoring back button');
      return;
    }

    // Debug information
    print('🔍 [DEBUG] Back navigation - Role: ${widget.role}, OTP Type: ${widget.otpType}');
    print('🔍 [DEBUG] Role is null: ${widget.role == null}');
    print('🔍 [DEBUG] OTP Type is registration: ${widget.otpType == "registration"}');

    // Try to determine the role from the navigation stack or use a default
    String? roleToUse = widget.role;
    
    // If role is not provided, try to get it from various sources
    if (roleToUse == null) {
      print('⚠️ [DEBUG] Role not provided, trying to determine from context');
      
      // Check if we can get role from Get.arguments or other sources
      final arguments = Get.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        roleToUse = arguments['role']?.toString();
        print('🔍 [DEBUG] Found role in arguments: $roleToUse');
      }
      
      // Try to get role from the current route or navigation history
      if (roleToUse == null) {
        try {
          // Check if we can determine role from the current route
          final currentRoute = Get.currentRoute;
          print('🔍 [DEBUG] Current route: $currentRoute');
          
          // Look for role indicators in the route
          if (currentRoute.contains('TruckOwner') || currentRoute.contains('truck')) {
            roleToUse = 'TruckOwner';
          } else if (currentRoute.contains('Customer') || currentRoute.contains('customer')) {
            roleToUse = 'Customer';
          } else if (currentRoute.contains('Driver') || currentRoute.contains('driver')) {
            roleToUse = 'Driver';
          }
          
          print('🔍 [DEBUG] Determined role from route: $roleToUse');
        } catch (e) {
          print('⚠️ [DEBUG] Error getting current route: $e');
        }
      }
      
      // If still no role, show role selection dialog
      if (roleToUse == null) {
        print('🔍 [DEBUG] Cannot determine role, showing role selection dialog');
        _showRoleSelectionDialog();
        return;
      }
    }

    // If it's a registration OTP, go back to registration screen
    if (widget.otpType == "registration") {
      print('🔄 [DEBUG] Navigating back to registration screen with role: $roleToUse');
      Get.offAll(() => RegistrationScreen(role: roleToUse!));
    } else {
      // For other OTP types, try to go back to login or previous screen
      print('🔄 [DEBUG] OTP type is not registration, using default back navigation');
      Get.back();
    }
  }

  /// Show role selection dialog if role cannot be determined
  void _showRoleSelectionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Registration Type'),
        content: const Text('Please select the type of registration you were completing:'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offAll(() => const RegistrationScreen(role: 'Customer'));
            },
            child: const Text('Customer'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offAll(() => const RegistrationScreen(role: 'TruckOwner'));
            },
            child: const Text('Truck Owner'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _handleBackNavigation(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Header
              Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                "We've sent a verification code to",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (otpError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          otpError.value,
                          style: const TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: otpController,
                      focusNode: otpFocusNode,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: Colors.white,
                        activeColor: AppColors.rectangleColor,
                        selectedColor: AppColors.rectangleColor,
                        inactiveColor: Colors.grey[300],
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: false,
                      onCompleted: (v) {
                        _verifyOtp();
                      },
                      onChanged: (value) {
                        otpError.value = '';
                      },
                    ),
                  ],
                );
              }),
              
              const SizedBox(height: 32),
              
              // Verify Button
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading.value ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rectangleColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Verify Email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              // Resend OTP
              Center(
                child: Obx(() {
                  return TextButton(
                    onPressed: (isLoading.value || resendCountdown.value > 0) ? null : _resendOtp,
                    child: Text(
                      resendCountdown.value > 0 
                        ? "Resend code in ${resendCountdown.value}s"
                        : "Didn't receive the code? Resend",
                      style: TextStyle(
                        color: resendCountdown.value > 0 
                          ? Colors.grey 
                          : AppColors.rectangleColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Footer
              Center(
                child: Text(
                  "Check your email inbox and spam folder",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyOtp() async {
    if (_isNavigating || !mounted) {
      print('⚠️ [DEBUG] Navigation in progress or widget disposed, skipping OTP verification');
      return;
    }

    // Check if controller text is valid
    if (otpController.text.length != 6) {
      if (mounted) {
        otpError.value = "Please enter a 6-digit verification code";
      }
      return;
    }

    // Validate userId before making the request
    if (widget.userId.isEmpty) {
      print('⚠️ [DEBUG] No userId provided, will try using email as identifier');
      // Don't return early, let the service handle the fallback
    }

    // Store the OTP value before async operation to avoid accessing disposed controller
    final otpValue = otpController.text;
    
    print('🔐 [DEBUG] Starting OTP verification...');
    print('🔐 [DEBUG] UserId: ${widget.userId}');
    print('🔐 [DEBUG] OTP: $otpValue');
    print('🔐 [DEBUG] Email: ${widget.email}');

    isLoading.value = true;
    try {
      final result = await _controller.verifyEmailOtp(
        widget.userId,
        otpValue,
      );

      if (result != null) {
        print('✅ [DEBUG] OTP verification successful in UI');
        
        // Check if manual login is required
        if (result['requiresManualLogin'] == true) {
          print('📝 [DEBUG] Manual login required after OTP verification');
          
          // Show success page for email verification
          if (!_isNavigating) {
            _isNavigating = true;
            Get.offAll(() => SuccessPageConfigs.registrationSuccess(
              onContinue: () {
                Get.offAll(() => const LoginScreen());
              },
            ));
          }
        } else {
          // Automatic login successful - show success page with loading
          if (!_isNavigating) {
            _isNavigating = true;
            
            // Navigate based on user role with proper case handling
            final role = result['role'] ?? 'Customer';
            final normalizedRole = role.toString().trim().toLowerCase();

            String navigationRole;
            switch (normalizedRole) {
              case 'customer':
                navigationRole = 'Customer';
                break;
              case 'driver':
                navigationRole = 'Driver';
                break;
              case 'truckowner':
              case 'truck_owner':
              case 'truck owner':
                navigationRole = 'TruckOwner';
                break;
              case 'admin':
              case 'staff':
                navigationRole = 'Customer'; // Admin/Staff use Customer view
                break;
              default:
                navigationRole = 'Customer'; // Default fallback
            }
            
            // Get user name from result or use email
            final userName = result['user'] != null && result['user']['firstname'] != null && result['user']['lastname'] != null
                ? '${result['user']['firstname']} ${result['user']['lastname']}'
                : null;
            
            // Show success page with loading and auto-navigation
            Get.offAll(() => SuccessPageConfigs.emailVerifiedSuccess(
              userName: userName,
              userRole: navigationRole,
              displayDuration: const Duration(seconds: 20),
              loadingTask: _performPostVerificationTasks(navigationRole),
              onContinue: () {
                Get.offAll(() => RoleBasedBottomNavScreen(role: navigationRole));
              },
            ));
          }
        }
      } else {
        print('❌ [DEBUG] OTP verification returned null result');
        otpError.value = "Verification failed. Please try again.";
      }
    } catch (e) {
      print('❌ [DEBUG] OTP verification error in UI: $e');
      // Extract meaningful error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.split('Exception:').last.trim();
      }
      if (mounted && !_isNavigating) {
        otpError.value = errorMessage;
      }
    } finally {
      if (mounted && !_isNavigating) {
        isLoading.value = false;
      }
    }
  }

  void _resendOtp() async {
    if (_isNavigating || !mounted) {
      print('⚠️ [DEBUG] Navigation in progress or widget disposed, skipping OTP resend');
      return;
    }

    // Check if we have either userId or email
    if (widget.userId.isEmpty && widget.email.isEmpty) {
      if (mounted) {
        Get.snackbar(
          "Error",
          "No user identifier available. Please try registering again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return;
    }

    print('📧 [DEBUG] Starting OTP resend...');
    print('📧 [DEBUG] UserId: ${widget.userId}');
    print('📧 [DEBUG] Email: ${widget.email}');

    isLoading.value = true;
    try {
      await _controller.resendEmailOtp(widget.userId, widget.email);
      print('✅ [DEBUG] OTP resend successful in UI');
      Get.snackbar(
        "Success",
        "New verification code sent to your email",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Clear any existing OTP error
      otpError.value = '';
      
      // Clear the OTP input field only if widget is still mounted
      if (mounted) {
        otpController.clear();
      }
      
      // Restart the countdown timer
      _startResendCountdown();
    } catch (e) {
      print('❌ [DEBUG] OTP resend error in UI: $e');
      // Extract meaningful error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.split('Exception:').last.trim();
      }
      if (mounted && !_isNavigating) {
        Get.snackbar(
          "Error",
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted && !_isNavigating) {
        isLoading.value = false;
      }
    }
  }

  /// Perform post-verification tasks while showing success screen
  Future<void> _performPostVerificationTasks(String navigationRole) async {
    try {
      print("🔄 [EMAIL VERIFICATION] Starting post-verification tasks...");
      
      // Ensure SharedPrefsUtil is initialized
      await SharedPrefsUtil().init();
      
      // Get user from controller
      final user = _controller.user.value;
      
      // Save user status if available
      if (user?.status != null) {
        await SharedPrefsUtil().saveUserStatus(user!.status!);
        print("✅ [EMAIL VERIFICATION] User status saved: ${user.status}");
      }
      
      // Save user ID if available
      if (user?.id != null) {
        await SharedPrefsUtil().saveUserId(user!.id!);
        print("✅ [EMAIL VERIFICATION] User ID saved: ${user.id}");
      }
      
      // Additional role-specific setup can be added here
      print("✅ [EMAIL VERIFICATION] Role-specific setup for: $navigationRole");
      
      // Add any role-specific initialization here
      switch (navigationRole) {
        case 'Driver':
          // Driver-specific setup
          print("🚛 [EMAIL VERIFICATION] Setting up driver-specific data...");
          break;
        case 'TruckOwner':
          // Truck owner specific setup
          print("🚚 [EMAIL VERIFICATION] Setting up truck owner-specific data...");
          break;
        case 'Customer':
          // Customer specific setup
          print("👤 [EMAIL VERIFICATION] Setting up customer-specific data...");
          break;
      }
      
      print("✅ [EMAIL VERIFICATION] Post-verification tasks completed successfully");
    } catch (e) {
      print("❌ [EMAIL VERIFICATION] Error during post-verification tasks: $e");
      // Don't throw the error, just log it so the success screen still shows
    }
  }
}
