import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/widget/login_widget.dart';
import 'package:oil_connect/screens/login%20screens/decide_button.dart';
import 'package:oil_connect/screens/login%20screens/forgot_password_screen.dart';
import 'package:oil_connect/backend/controllers/authController.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final countryPicker = const FlCountryCodePicker();
  CountryCode countryCode =
  const CountryCode(name: 'Tanzania', code: "TZ", dialCode: "+255");

  onSubmit(String? input) {}

  @override
  Widget build(BuildContext context) {
    print("🔄 [LOGIN] LoginScreen build() called");
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Card Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: SizedBox(
                  child: LoginForm(
                    onLogin: (identifier, password) async {
                      print("🔄 [LOGIN] Login button pressed");
                      final controller = Get.find<RegisterController>();
                      print("✅ [LOGIN] RegisterController found");
                      await controller.loginWithEmail(identifier, password);
                    },
                    onForgot: () => Get.to(() => const ForgotPasswordScreen()),
                    onSignup: () => Get.to(() => const DecideButton()),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      );
  }
}