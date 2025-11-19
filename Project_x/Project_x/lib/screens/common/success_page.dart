import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/colors.dart';

class SuccessPage extends StatelessWidget {
  final String title;
  final String message;
  final String? subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final bool showBackButton;
  final String? backButtonText;
  final VoidCallback? onBackPressed;
  final Widget? customContent;
  final double? imageSize;
  final Color? buttonColor;
  final Color? textColor;
  final bool centerContent;

  const SuccessPage({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.buttonText = "Continue",
    this.onButtonPressed,
    this.showBackButton = false,
    this.backButtonText,
    this.onBackPressed,
    this.customContent,
    this.imageSize,
    this.buttonColor,
    this.textColor,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final effectiveTextColor = textColor ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final effectiveButtonColor = buttonColor ?? AppColors.rectangleColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: effectiveTextColor,
                ),
                onPressed: onBackPressed ?? () => Get.back(),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: centerContent
              ? Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSuccessContent(context, isDarkMode, effectiveTextColor, effectiveButtonColor),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildSuccessContent(context, isDarkMode, effectiveTextColor, effectiveButtonColor),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent(
    BuildContext context,
    bool isDarkMode,
    Color effectiveTextColor,
    Color effectiveButtonColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success Icon/Image
        Container(
          width: imageSize ?? 120,
          height: imageSize ?? 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withOpacity(0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/check_green.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.check_circle,
                  size: (imageSize ?? 120) * 0.6,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: effectiveTextColor,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Message
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        // Subtitle (optional)
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 40),

        // Custom Content (optional)
        if (customContent != null) ...[
          customContent!,
          const SizedBox(height: 32),
        ],

        // Action Button (only shown when an action is provided)
        if (onButtonPressed != null) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveButtonColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],

        // Back Button (optional)
        if (showBackButton && backButtonText != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: onBackPressed ?? () => Get.back(),
            child: Text(
              backButtonText!,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Predefined success page configurations for common scenarios
class SuccessPageConfigs {
  static Widget registrationSuccess({
    required VoidCallback onContinue,
    String? userEmail,
  }) {
    return SuccessPage(
      title: "Registration Successful!",
      message: "Welcome to Oil Connect! Your account has been created successfully.",
      subtitle: userEmail != null ? "We've sent a verification email to $userEmail" : null,
      buttonText: "Continue to Login",
      onButtonPressed: onContinue,
      imageSize: 120,
    );
  }

  static Widget emailVerifiedSuccess({
    required VoidCallback onContinue,
    String? userName,
    String? userRole,
    Future<void>? loadingTask,
    Duration displayDuration = const Duration(seconds: 2),
  }) {
    return LoginSuccessScreen(
      userName: userName,
      userRole: userRole,
      onContinue: onContinue,
      displayDuration: displayDuration,
      loadingTask: loadingTask,
      customTitle: "Email Verified!",
      customMessage: userName != null 
          ? "Hello $userName! Your email has been successfully verified."
          : "Your email has been successfully verified.",
      customSubtitle: userRole != null 
          ? "Setting up your $userRole dashboard..."
          : "Setting up your dashboard...",
    );
  }

  static Widget loginSuccess({
    required VoidCallback onContinue,
    String? userName,
    String? userRole,
    Duration? displayDuration,
  }) {
    return SuccessPage(
      title: "Welcome Back!",
      message: userName != null 
          ? "Hello $userName! You have successfully logged in."
          : "You have successfully logged in.",
      subtitle: userRole != null 
          ? "Accessing your $userRole dashboard..."
          : "Loading your dashboard...",
      buttonText: "Continue",
      onButtonPressed: onContinue,
      imageSize: 100,
      centerContent: true,
    );
  }

  /// Helper method to create a login success screen with automatic timing
  static Widget loginSuccessWithTiming({
    required VoidCallback onContinue,
    String? userName,
    String? userRole,
    Duration displayDuration = const Duration(seconds: 2),
    Future<void>? loadingTask,
  }) {
    return LoginSuccessScreen(
      userName: userName,
      userRole: userRole,
      onContinue: onContinue,
      displayDuration: displayDuration,
      loadingTask: loadingTask,
    );
  }

  static Widget customSuccess({
    required String title,
    required String message,
    String? subtitle,
    required String buttonText,
    required VoidCallback onButtonPressed,
    String? backButtonText,
    VoidCallback? onBackPressed,
    Widget? customContent,
    double? imageSize,
    Color? buttonColor,
    Color? textColor,
    bool centerContent = true,
  }) {
    return SuccessPage(
      title: title,
      message: message,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      backButtonText: backButtonText,
      onBackPressed: onBackPressed,
      customContent: customContent,
      imageSize: imageSize,
      buttonColor: buttonColor,
      textColor: textColor,
      centerContent: centerContent,
    );
  }
}

// Specialized login success screen with automatic timing
class LoginSuccessScreen extends StatefulWidget {
  final String? userName;
  final String? userRole;
  final VoidCallback onContinue;
  final Duration displayDuration;
  final Future<void>? loadingTask;
  final String? customTitle;
  final String? customMessage;
  final String? customSubtitle;

  const LoginSuccessScreen({
    super.key,
    this.userName,
    this.userRole,
    required this.onContinue,
    this.displayDuration = const Duration(seconds: 2),
    this.loadingTask,
    this.customTitle,
    this.customMessage,
    this.customSubtitle,
  });

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  Timer? _timer;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startLoadingProcess();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  /// Safely update state only if widget is still mounted and not disposed
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      try {
        setState(fn);
      } catch (e) {
        print('Error calling setState: $e');
      }
    }
  }

  void _startLoadingProcess() async {
    // Check if widget is already disposed before starting
    if (_isDisposed) {
      return;
    }

    try {
      // Start the loading task if provided
      if (widget.loadingTask != null) {
        try {
          // Add timeout to prevent hanging
          await widget.loadingTask!.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Loading task timed out');
            },
          );
        } catch (e) {
          print('Error during loading task: $e');
        }
      }

      // Check if still mounted after loading task
      if (_isDisposed) return;

      // Wait for the minimum display duration
      await Future.delayed(widget.displayDuration);

      // Final check before updating state
      if (_isDisposed) return;

      // Safely update state
      _safeSetState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _startLoadingProcess: $e');
      // Even if there's an error, try to enable navigation
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container if disposed
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    // Use custom title/message if provided, otherwise use defaults
    final title = widget.customTitle ?? "Welcome Back!";
    final message = widget.customMessage ?? (widget.userName != null 
        ? "Hello ${widget.userName}! You have successfully logged in."
        : "You have successfully logged in.");
    final subtitle = widget.customSubtitle ?? (widget.userRole != null 
        ? "Accessing your ${widget.userRole} dashboard..."
        : "Loading your dashboard...");

    return SuccessPage(
      title: title,
      message: message,
      subtitle: subtitle,
      imageSize: 100,
      centerContent: true,
      customContent: _isLoading
          ? Padding(
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
            )
          : null,
    );
  }
}
