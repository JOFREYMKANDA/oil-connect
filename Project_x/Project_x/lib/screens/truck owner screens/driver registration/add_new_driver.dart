import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oil_connect/backend/models/user_model.dart';
import 'package:oil_connect/screens/truck%20owner%20screens/driver%20registration/added_driver_list.dart';
import 'package:oil_connect/utils/colors.dart';
import '../../../backend/controllers/registerDriverController.dart';
import '../../../backend/models/driver_model.dart';

class AddNewDriverScreen extends StatefulWidget {
  final bool isEditing;
  final Driver? driver;

  const AddNewDriverScreen({super.key, this.isEditing = false, this.driver});

  @override
  State<AddNewDriverScreen> createState() => _AddNewDriverScreenState();
}

class _AddNewDriverScreenState extends State<AddNewDriverScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController licenseExpireDateController = TextEditingController();

  final FlCountryCodePicker countryCodePicker = const FlCountryCodePicker();
  final Rx<CountryCode?> selectedCountryCode = CountryCode.fromDialCode("+255").obs;
  final DriverRegistrationController controller = Get.put(DriverRegistrationController());

  bool _isPasswordVisible = false;

  // ✅ Focus Nodes
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _licenseFocus = FocusNode();

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    _licenseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && widget.driver != null) {
      final d = widget.driver!;
      firstNameController.text = d.firstname;
      lastNameController.text = d.lastname;
      emailController.text = d.email;
      passwordController.text = ''; // Don't pre-fill password for security
      phoneController.text = d.phoneNumber;
      licenseNumberController.text = d.licenseNumber ?? '';
      licenseExpireDateController.text = d.licenseExpireDate != null
          ? "${d.licenseExpireDate!.year}-${d.licenseExpireDate!.month.toString().padLeft(2, '0')}-${d.licenseExpireDate!.day.toString().padLeft(2, '0')}"
          : '';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE1E5E9),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing ? "Edit Driver" : "Add New Driver",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isEditing 
                              ? "Update driver information"
                              : "Register a new driver for your fleet",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Driver Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.rectangleColor,
                          AppColors.rectangleColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rectangleColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      _buildSectionHeader(
                        context,
                        "Personal Information",
                        "Basic driver details",
                        Icons.person_rounded,
                      ),

                      const SizedBox(height: 20),

                      // Name Fields Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              context,
                              'First Name',
                              Icons.person_outline_rounded,
                              firstNameController,
                              focusNode: _firstNameFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_lastNameFocus),
                              validator: (v) => v!.isEmpty ? 'First name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernTextField(
                              context,
                              'Last Name',
                              Icons.person_outline_rounded,
                              lastNameController,
                              focusNode: _lastNameFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                              validator: (v) => v!.isEmpty ? 'Last name is required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Email Field
                      _buildModernTextField(
                        context,
                        'Email Address',
                        Icons.email_outlined,
                        emailController,
                        keyboardType: TextInputType.emailAddress,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                        validator: (v) => v!.isEmpty
                            ? 'Email is required'
                            : (!GetUtils.isEmail(v.trim()) ? 'Enter a valid email' : null),
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernPasswordField(
                            context,
                            widget.isEditing ? 'New Password (Optional)' : 'Password',
                            Icons.lock_outline_rounded,
                            passwordController,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
                            validator: (v) {
                              if (widget.isEditing) {
                                // For editing, password is optional
                                if (v != null && v.isNotEmpty && v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              } else {
                                // For new driver, password is required
                                if (v == null || v.isEmpty) return 'Password is required';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isEditing 
                                ? "Leave blank to keep current password"
                                : "Driver will use this password to log in",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Phone Number Field
                      _buildModernPhoneNumberField(context),

                      const SizedBox(height: 32),

                      // License Information Section
                      _buildSectionHeader(
                        context,
                        "License Information",
                        "Driver license details",
                        Icons.badge_rounded,
                      ),

                      const SizedBox(height: 20),

                      // License Number Field
                      _buildModernTextField(
                        context,
                        'License Number',
                        Icons.credit_card_rounded,
                        licenseNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [LengthLimitingTextInputFormatter(10)],
                        focusNode: _licenseFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_licenseFocus),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'License number is required';
                          if (v.length != 10) return 'License number must be exactly 10 digits';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // License Expiry Date Field
                      _buildModernDatePickerField(
                        context,
                        'License Expiry Date',
                        Icons.calendar_today_rounded,
                        licenseExpireDateController,
                      ),

                      const SizedBox(height: 40),

                      // Submit Button
                      Obx(() {
                        return controller.isLoading.value
                            ? Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.rectangleColor.withOpacity(0.3),
                                      AppColors.rectangleColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.rectangleColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Processing...",
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.rectangleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.rectangleColor,
                                      AppColors.rectangleColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.rectangleColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (!_formKey.currentState!.validate()) return;

                                    final user = User(
                                      firstname: firstNameController.text.trim(),
                                      lastname: lastNameController.text.trim(),
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim().isNotEmpty 
                                          ? passwordController.text.trim() 
                                          : null,
                                      phoneNumber: "${selectedCountryCode.value?.dialCode}${phoneController.text.trim()}",
                                      licenseNumber: licenseNumberController.text.trim(),
                                      licenseExpireDate: DateTime.tryParse(licenseExpireDateController.text.trim()),
                                      role: 'Driver',
                                    );

                                    bool success;
                                    if (widget.isEditing && widget.driver != null) {
                                      success = await controller.updateDriver(widget.driver!.id, user.toJson());
                                    } else {
                                      success = await controller.registerDriver(user);
                                    }

                                    Get.snackbar(
                                      '',
                                      success
                                          ? widget.isEditing
                                              ? 'Driver updated successfully'
                                              : 'Driver registered successfully'
                                          : 'Operation failed',
                                      backgroundColor: success ? AppColors.rectangleColor : AppColors.redColor,
                                      colorText: AppColors.shapeColor,
                                    );

                                    if (success) Get.to(() => const DriversListScreen());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.isEditing ? Icons.update_rounded : Icons.person_add_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isEditing ? "Update Driver" : "Add Driver",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                      }),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.rectangleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.rectangleColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : const Color(0xFF666666),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rectangleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.rectangleColor,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModernPasswordField(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController controller, {
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        obscureText: !_isPasswordVisible,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : const Color(0xFF666666),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rectangleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.rectangleColor,
              size: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: AppColors.rectangleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              splashRadius: 20,
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.rectangleColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }


  Widget _buildModernPhoneNumberField(BuildContext context) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFE1E5E9),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Country Code Picker
            GestureDetector(
              onTap: () async {
                final code = await countryCodePicker.showPicker(context: context);
                if (code != null) selectedCountryCode.value = code;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.rectangleColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    selectedCountryCode.value!.flagImage(),
                    const SizedBox(width: 8),
                    Text(
                      selectedCountryCode.value?.dialCode ?? "+255",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.rectangleColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.rectangleColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            
            // Phone Number Input
            Expanded(
              child: TextFormField(
                controller: phoneController,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_licenseFocus),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return newValue.text.startsWith('0') ? oldValue : newValue;
                  })
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Phone number is required';
                  if (value.length != 9) return 'Phone must be 9 digits';
                  return null;
                },
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  hintText: "XXXXXXXXX",
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white30
                        : const Color(0xFF999999),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }


  Widget _buildModernDatePickerField(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFE1E5E9),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: (value) {
          if (value == null || value.isEmpty) return 'License expiry date is required';
          final selected = DateTime.tryParse(value);
          if (selected == null) return 'Invalid date';
          if (selected.difference(DateTime.now()).inDays < 30) return 'Must be at least 30 days from today';
          return null;
        },
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white60
                : const Color(0xFF666666),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rectangleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.rectangleColor,
              size: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.rectangleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.rectangleColor,
                size: 20,
              ),
              onPressed: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  controller.text = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                }
              },
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

}

