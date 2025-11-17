import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/shared_pref_utils.dart';
import 'package:oil_connect/widget/bottom_navigation.dart';
import 'package:oil_connect/screens/login%20screens/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      print("🚀 Splash screen started");
      await Future.delayed(const Duration(seconds: 2));

      // Show splash for at least 2 seconds
      print("⏳ Waiting 2 seconds...");
      await Future.delayed(const Duration(seconds: 2));
      print("✅ 2 seconds completed");

      // ✅ Fetch stored token and role
      print("🔍 Checking user credentials...");
      String? token = SharedPrefsUtil().getToken();
      String? role = SharedPrefsUtil().getRole();
      bool isInactive = SharedPrefsUtil().isUserInactive();
      
      print("📱 Token: ${token != null ? 'Present' : 'Missing'}");
      print("👤 Role: $role");
      print("⏰ Inactive: $isInactive");

      if (token != null && !isInactive && role != null && role.isNotEmpty) {
        // ✅ Navigate to role-based screen with validation
        print("🔄 Navigating to role-based screen: $role");

        // Validate role and ensure it's properly formatted
        final normalizedRole = role.trim();
        
        if (['Customer', 'Driver', 'TruckOwner', 'Admin', 'Staff'].contains(normalizedRole)) {
          Get.offAll(() => RoleBasedBottomNavScreen(role: normalizedRole));
        } else {
          print("⚠️ Invalid role detected: $normalizedRole, redirecting to login");
          Get.offAll(() => const LoginScreen());
        }
      } else {
        // ✅ Navigate to login screen
        print("🔐 Navigating to login screen");
        if (token == null) print("   Reason: No token found");
        if (isInactive) print("   Reason: User inactive");
        if (role == null || role.isEmpty) print("   Reason: No role found");
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      print("❌ Error in splash navigation: $e");
      // Fallback to login screen if there's an error
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEC9A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with error handling
            Image.asset(
              'assets/splash.jpg',
              width: 250,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                print("❌ Error loading splash image: $error");
                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    size: 100,
                    color: Colors.orange,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
