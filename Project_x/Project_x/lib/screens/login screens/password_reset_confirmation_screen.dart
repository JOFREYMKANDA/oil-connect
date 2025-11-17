import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/screens/login screens/login.dart';

class PasswordResetConfirmationScreen extends StatelessWidget {
  final String email;
  
  const PasswordResetConfirmationScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Password Reset',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 30,
                color: Colors.green[600],
              ),
            ),

            const SizedBox(height: 32),
            
            // Title
            const Text(
              'Password Reset Email Sent!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'We\'ve sent password reset instructions to:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),

            // Email Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What to do next:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Check your email inbox\n2. Look for an email from Oil Connect\n3. Click the reset link in the email\n4. Follow the instructions to create a new password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.offAll(() => const LoginScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rectangleColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Resend Email',
                        'Resend functionality will be available soon',
                        backgroundColor: Colors.orange[100],
                        colorText: Colors.orange[800],
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Resend Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Help Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.amber[700],
                    size: 24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Didn\'t receive the email?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your spam folder or contact support if you don\'t see the email within a few minutes.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Get.snackbar(
                        'Contact Support',
                        'Please contact support at support@oilconnect.com',
                        backgroundColor: Colors.amber[100],
                        colorText: Colors.amber[800],
                      );
                    },
                    child: Text(
                      'Contact Support',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}