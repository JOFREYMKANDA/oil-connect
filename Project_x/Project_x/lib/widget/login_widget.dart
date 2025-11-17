import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oil_connect/utils/colors.dart';
import '../screens/login screens/decide_button.dart';

/// Login UI.
/// Use [onLogin] to perform auth, [onForgot] and [onSignup] for navigation.
class LoginForm extends StatefulWidget {
  final Future<void> Function(String identifier, String password)? onLogin;
  final VoidCallback? onForgot;
  final VoidCallback? onSignup;

  const LoginForm({
    super.key,
    this.onLogin,
    this.onForgot,
    this.onSignup,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  
  // Error states for each field
  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isNetworkErrorState = false;
  
  // Success state
  bool _showSuccessMessage = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Clear all error states
  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
      _showSuccessMessage = false;
      _isNetworkErrorState = false;
    });
  }

  /// Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    
    final email = value.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  /// Check if the error is a network connectivity issue
  bool _isNetworkError(String error) {
    final lowerError = error.toLowerCase();
    return lowerError.contains('socketexception') ||
           lowerError.contains('failed host lookup') ||
           lowerError.contains('nodename nor servname provided') ||
           lowerError.contains('getaddrinfo enotfound') ||
           lowerError.contains('clientexception') ||
           lowerError.contains('connection refused') ||
           lowerError.contains('connection reset') ||
           lowerError.contains('timeout') ||
           lowerError.contains('unreachable') ||
           lowerError.contains('no internet') ||
           lowerError.contains('network') ||
           lowerError.contains('connection');
  }

  /// Handle backend error messages and map them to user-friendly messages
  void _handleBackendError(String error) {
    String? emailError;
    String? passwordError;
    String? generalError;
    
    // Map backend error messages to specific field errors
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('email') && lowerError.contains('invalid')) {
      emailError = 'Invalid email format';
    } else if (lowerError.contains('email') && lowerError.contains('required')) {
      emailError = 'Email is required';
    } else if (lowerError.contains('password') && lowerError.contains('required')) {
      passwordError = 'Password is required';
    } else if (lowerError.contains('unauthorized') || lowerError.contains('invalid credentials')) {
      generalError = 'Invalid email or password. Please check your credentials and try again.';
    } else if (lowerError.contains('account') && lowerError.contains('blocked')) {
      generalError = 'Your account has been blocked. Please contact support.';
    } else if (lowerError.contains('account') && lowerError.contains('inactive')) {
      generalError = 'Your account is inactive. Please contact support.';
    } else if (lowerError.contains('verification') || lowerError.contains('verify')) {
      generalError = 'Please verify your email before logging in.';
    } else if (_isNetworkError(error)) {
      generalError = 'No internet connection. Please check your network and try again.';
      _isNetworkErrorState = true;
    } else if (lowerError.contains('server') || lowerError.contains('internal')) {
      generalError = 'Server error. Please try again later.';
    } else {
      // Default to general error for unknown errors
      generalError = error;
    }
    
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _generalError = generalError;
    });
  }

  Future<void> _submit() async {
    // Clear previous errors
    _clearErrors();
    
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;
    if (widget.onLogin == null) return;

    // Additional client-side validation
    final emailError = _validateEmail(_identifierController.text);
    final passwordError = _validatePassword(_passwordController.text);
    
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onLogin!(
        _identifierController.text.trim(),
        _passwordController.text,
      );
      // Login successful - show success message briefly
      setState(() => _showSuccessMessage = true);
      
      // Clear success message after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showSuccessMessage = false);
        }
      });
    } catch (e) {
      // Handle login errors
      _handleBackendError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String hint, String label, {String? errorText, bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      labelText: label,
      labelStyle: TextStyle(color: hasError ? Colors.red : Colors.grey[500]),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.red : Colors.green.shade200, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 80),

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

                const SizedBox(height: 12),
                const Text(
                  'Oil Connect',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 50),

                const SizedBox(height: 16),

                // General error display
                if (_generalError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isNetworkErrorState ? Icons.wifi_off : Icons.error_outline, 
                              color: Colors.red.shade600, 
                              size: 20
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        if (_isNetworkErrorState) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _loading ? null : _submit,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                backgroundColor: Colors.red.shade100,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Success message display
                if (_showSuccessMessage)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Login successful! Redirecting...',
                            style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      // Email field
                      TextFormField(
                        controller: _identifierController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          // Clear email error when user starts typing
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        decoration: _inputDecoration(
                          'Email', 
                          'Email',
                          errorText: _emailError,
                          hasError: _emailError != null,
                        ),
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: 12),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        onChanged: (value) {
                          // Clear password error when user starts typing
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        decoration: _inputDecoration(
                          'Password', 
                          'Password',
                          errorText: _passwordError,
                          hasError: _passwordError != null,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                            splashRadius: 20,
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: widget.onForgot,
                          child: Text('Forgot password?', style: TextStyle(color: Colors.grey[700])),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _loading ? AppColors.rectangleColor.withOpacity(0.7) : AppColors.rectangleColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _loading ? [] : [
                        BoxShadow(
                          color: AppColors.rectangleColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, 
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Signing in...',
                                  style: TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w600, 
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Log in', 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w600, 
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

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

                const SizedBox(height: 24),

                // Sign up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have account? ", style: TextStyle(color: Colors.grey[700])),
                    GestureDetector(
                      onTap: () => Get.to(const DecideButton()),
                      child: Text('Sign up', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

              ],
            ),
          ),
        ),
      ),
    ));
  }
}


