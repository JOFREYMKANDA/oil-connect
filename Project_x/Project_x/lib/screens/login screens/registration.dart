import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oil_connect/screens/login%20screens/login.dart';
import 'package:oil_connect/screens/login%20screens/email_otp_verification.dart';
import 'package:oil_connect/utils/colors.dart';
import 'package:oil_connect/utils/constants.dart';
import 'package:oil_connect/utils/text_style.dart';
import '../../backend/controllers/authController.dart';
import '../../backend/models/user_model.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;

  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final RegisterController _controller = Get.put(RegisterController());

  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final countryCodePicker = const FlCountryCodePicker();
  final Rx<CountryCode?> selectedCountryCode = CountryCode.fromDialCode("+255").obs;

  final RxString firstNameError = ''.obs;
  final RxString lastNameError = ''.obs;
  final RxString emailError = ''.obs;
  final RxString phoneError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;

  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Logo section
              Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.35),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Oil Connect',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Obx(() {
                      return _controller.isLoading.value
                          ? Center(child: CircularProgressIndicator(color: Colors.green.shade900))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Register as ${widget.role}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField("First Name", "First Name", firstnameController, firstNameError, context, firstNameFocus, TextInputAction.next, (_) => lastNameFocus.requestFocus()),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: _buildTextField("Last Name", "Last Name", lastnameController, lastNameError, context, lastNameFocus, TextInputAction.next, (_) => emailFocus.requestFocus()),
                                    ),
                                    
                                    
                                  ],
                                 ),
                                _buildTextField("Email", "Email", emailController, emailError, context, emailFocus, TextInputAction.next, (_) => passwordFocus.requestFocus(), onChanged: (value) {
                                  // Clear email error when user starts typing
                                  if (emailError.isNotEmpty) {
                                    emailError.value = '';
                                  }
                                }),
                                _buildPasswordField("Password", passwordController, passwordError, context, passwordFocus, TextInputAction.next, (_) => confirmPasswordFocus.requestFocus()),
                                _buildPasswordField("Confirm Password", confirmPasswordController, confirmPasswordError, context, confirmPasswordFocus, TextInputAction.next, (_) => phoneFocus.requestFocus()),
                                _buildPhoneNumberField(context, isDarkMode),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 55,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Clear previous inline errors before submit
                                      emailError.value = '';
                                      phoneError.value = '';
                                      firstNameError.value = '';
                                      lastNameError.value = '';
                                      passwordError.value = '';
                                      confirmPasswordError.value = '';

                                      if (_validateFields()) {
                                        final user = User(
                                          firstname: firstnameController.text,
                                          lastname: lastnameController.text,
                                          email: emailController.text,
                                          phoneNumber: "${selectedCountryCode.value?.dialCode}${phoneNumberController.text}",
                                          password: passwordController.text,
                                          role: widget.role,
                                        );
                                        print('🚀 [DEBUG] Attempting to register user with role: ${widget.role}');
                                        _controller.registerTruckOwner(user).then((result) {
                                          if (result != null && !result.containsKey('error')) {
                                            print('✅ [DEBUG] Registration successful, navigating to OTP verification');
                                            print('📋 [DEBUG] Full registration result: $result');
                                            print('📋 [DEBUG] Available keys in result: ${result.keys.toList()}');
                                            
                                            // Try different possible userId field names
                                            String? userId;
                                            if (result.containsKey('userId')) {
                                              userId = result['userId']?.toString();
                                            } else if (result.containsKey('user_id')) {
                                              userId = result['user_id']?.toString();
                                            } else if (result.containsKey('id')) {
                                              userId = result['id']?.toString();
                                            } else if (result.containsKey('user')) {
                                              final userData = result['user'];
                                              if (userData is Map && userData.containsKey('id')) {
                                                userId = userData['id']?.toString();
                                              } else if (userData is Map && userData.containsKey('userId')) {
                                                userId = userData['userId']?.toString();
                                              }
                                            }
                                            
                                            print('📋 [DEBUG] Extracted userId: $userId');
                                            
                                            if (userId == null || userId.isEmpty) {
                                              print('⚠️ [DEBUG] No valid userId found in registration response, using email as fallback');
                                              userId = emailController.text; // Use email as userId fallback
                                              print('🔄 [DEBUG] Using email as userId: $userId');
                                            }
                                            
                                            // For email-based registration, go to OTP verification first
                                            print('🔄 [DEBUG] Navigating to OTP verification with role: ${widget.role}');
                                            Get.offAll(() => EmailOtpVerificationScreen(
                                              email: emailController.text,
                                              userId: userId!,
                                              otpType: "registration",
                                              role: widget.role, // Pass the role for back navigation
                                            ));
                                          } else if (result != null && result.containsKey('error')) {
                                            // Handle specific error types
                                            if (result['type'] == 'email_exists') {
                                              print('❌ [DEBUG] Email already exists - setting email error');
                                              emailError.value = result['message'] ?? 'This email is already registered';
                                              // Focus email field so user sees the error immediately
                                              emailFocus.requestFocus();
                                            } else if (result['type'] == 'phone_exists') {
                                              print('❌ [DEBUG] Phone number already exists - setting phone error');
                                              phoneError.value = result['message'] ?? 'This phone number is already registered';
                                              // Focus phone field so user sees the error immediately
                                              phoneFocus.requestFocus();
                                            } else {
                                              print('❌ [DEBUG] Other registration error: ${result['message']}');
                                              // Show generic error for other types
                                              String roleText = widget.role.toLowerCase() == 'truckowner' ? 'truck owner' : 'customer';
                                              Get.snackbar(
                                                "Registration Error", 
                                                result['message'] ?? "Unable to complete your $roleText registration. Please try again.", 
                                                backgroundColor: Colors.red, 
                                                colorText: Colors.white,
                                                snackPosition: SnackPosition.TOP,
                                              );
                                            }
                                          } else {
                                            print('❌ [DEBUG] Registration failed - showing generic error');
                                            // Show a fallback error message if the controller didn't show one
                                            String roleText = widget.role.toLowerCase() == 'truckowner' ? 'truck owner' : 'customer';
                                            Get.snackbar(
                                              "Registration Failed", 
                                              "Unable to complete your $roleText registration. Please check your information and try again.", 
                                              backgroundColor: Colors.red, 
                                              colorText: Colors.white,
                                              snackPosition: SnackPosition.TOP,
                                            );
                                          }
                                        }).catchError((error) {
                                          print('❌ [DEBUG] Registration error caught: $error');
                                          // Show error message for exceptions
                                          String roleText = widget.role.toLowerCase() == 'truckowner' ? 'truck owner' : 'customer';
                                          Get.snackbar(
                                            "Registration Error", 
                                            "An error occurred during $roleText registration. Please try again.", 
                                            backgroundColor: Colors.red, 
                                            colorText: Colors.white,
                                            snackPosition: SnackPosition.TOP,
                                          );
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.rectangleColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(AppConstants.register.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                    const SizedBox(width: 12),
                                    Text("OR", style: TextStyle(color: Colors.grey[700])),
                                    const SizedBox(width: 12),
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(AppConstants.alreadyHaveAccount.tr),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Get.to(() => const LoginScreen()),
                                      child: Text(AppConstants.loginLabel.tr, style: AppTextStyles.link.copyWith(color: AppColors.rectangleColor)),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                
                              ],
                            );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, String hintText, TextEditingController controller, RxString errorText, BuildContext context, FocusNode focusNode, TextInputAction inputAction, void Function(String)? onSubmit, {void Function(String)? onChanged}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(errorText.value, style: const TextStyle(color: AppColors.redColor)),
              ),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: inputAction,
              onFieldSubmitted: onSubmit,
              onChanged: onChanged,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.black),
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300, width: 1),),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade300: AppColors.textFieldBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: errorText.isNotEmpty ? AppColors.redColor : Colors.green.shade200, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.redColor, width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.redColor, width: 1.5)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPasswordField(String labelText, TextEditingController controller, RxString errorText, BuildContext context, FocusNode focusNode, TextInputAction inputAction, void Function(String)? onSubmit) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final obscure = false.obs;
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(errorText.value, style: const TextStyle(color: AppColors.redColor)),
              ),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: inputAction,
              onFieldSubmitted: onSubmit,
              keyboardType: TextInputType.text,
              obscureText: !obscure.value ? true : false,
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.black),
                hintText: labelText,
                hintStyle: TextStyle(color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300, width: 1),),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade300: AppColors.textFieldBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: errorText.isNotEmpty ? AppColors.redColor : Colors.green.shade200, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.redColor, width: 1.5)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.redColor, width: 1.5)),
                suffixIcon: IconButton(
                  icon: Icon(obscure.value ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => obscure.value = !obscure.value,
                  splashRadius: 20,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPhoneNumberField(BuildContext context, bool isDarkMode) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phoneError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(phoneError.value, style: const TextStyle(color: AppColors.redColor)),
              ),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final code = await countryCodePicker.showPicker(context: context);
                    if (code != null) selectedCountryCode.value = code;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDarkMode ? const Color(0x1FFFFFFF) : AppColors.textFieldBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (selectedCountryCode.value != null) selectedCountryCode.value!.flagImage(),
                        const SizedBox(width: 8),
                        Text(selectedCountryCode.value?.dialCode ?? "+255", style: AppTextStyles.subHeading.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: phoneNumberController,
                    focusNode: phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDarkMode ? const Color(0x1FFFFFFF) : AppColors.textFieldBorder, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: phoneError.isNotEmpty ? AppColors.redColor : Colors.green, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.redColor, width: 1.5)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.redColor, width: 1.5)),
                    ),
                    onChanged: (value) {
                      // Clear phone error when user starts typing
                      if (phoneError.isNotEmpty) {
                        phoneError.value = '';
                      }
                      String sanitizedValue = value.trim();
                      if (sanitizedValue.startsWith("0")) {
                        sanitizedValue = sanitizedValue.substring(1);
                      }
                      phoneNumberController.text = sanitizedValue;
                      phoneNumberController.selection = TextSelection.fromPosition(TextPosition(offset: sanitizedValue.length));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  bool _validateFields() {
    bool isValid = true;

    // First Name Validation
    final firstName = firstnameController.text.trim();
    if (firstName.isEmpty) {
      firstNameError.value = "First Name cannot be empty.";
      isValid = false;
    } else if (firstName.length < 3) {
      firstNameError.value = "First Name must be at least 3 characters.";
      isValid = false;
    } else {
      firstNameError.value = '';
    }

    // Last Name Validation
    final lastName = lastnameController.text.trim();
    if (lastName.isEmpty) {
      lastNameError.value = "Last Name cannot be empty.";
      isValid = false;
    } else if (lastName.length < 3) {
      lastNameError.value = "Last Name must be at least 3 characters.";
      isValid = false;
    } else {
      lastNameError.value = '';
    }

    // Email Validation
    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError.value = "Email is required.";
      isValid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      emailError.value = "Enter a valid email.";
      isValid = false;
    } else {
      emailError.value = '';
    }

    // Password validation
    final pwd = passwordController.text.trim();
    final cpwd = confirmPasswordController.text.trim();
    if (pwd.isEmpty || pwd.length < 6) {
      passwordError.value = "Password must be at least 6 characters.";
      isValid = false;
    } else {
      passwordError.value = '';
    }
    if (cpwd != pwd) {
      confirmPasswordError.value = "Passwords do not match.";
      isValid = false;
    } else {
      confirmPasswordError.value = '';
    }

    // Phone Number Validation
    final phone = phoneNumberController.text.trim();
    if (phone.isEmpty) {
      phoneError.value = "Phone Number cannot be empty.";
      isValid = false;
    } else if (phone.length != 9) {
      phoneError.value = "Phone Number must be 9 digits.";
      isValid = false;
    } else {
      phoneError.value = '';
    }

    return isValid;
  }

}
