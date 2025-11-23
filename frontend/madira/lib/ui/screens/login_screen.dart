import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/providers/login_provider.dart';
import 'package:madira/ui/widgets/screen_wrapper.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_button_widget.dart';
import '../../core/constants/colors.dart';
import 'home_screen.dart'; // ← ADD THIS IMPORT

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? usernameError;
  String? passwordError;

  // Validation method
  bool _validateInputs() {
    setState(() {
      usernameError = null;
      passwordError = null;
    });

    bool isValid = true;

    // Validate username
    if (usernameController.text.trim().isEmpty) {
      setState(() {
        usernameError = 'Username is required';
      });
      isValid = false;
    }

    // Validate password
    if (passwordController.text.trim().isEmpty) {
      setState(() {
        passwordError = 'Password is required';
      });
      isValid = false;
    }

    return isValid;
  }

  // Show validation error snackbar
  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Please fill in all required fields",
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Extract clean error message for UI display
  String _getCleanErrorMessage(dynamic error) {
    String errorString = error.toString();

    if (errorString.startsWith('Exception: ')) {
      errorString = errorString.replaceFirst('Exception: ', '');
    }

    if (!errorString.toLowerCase().contains('dioexception') &&
        !errorString.toLowerCase().contains('status code')) {
      return errorString;
    }

    return 'Unable to sign in. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenWrapper(
        title: 'Login',
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textSecondary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 28),
        
                  // Title
                  Text(
                    'MADERA Kitchen',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
        
                  // Subtitle
                  Text(
                    'Sign in to your account',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
        
                  // Username Field
                  CustomInputWidget(
                    controller: usernameController,
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    required: true,
                    errorText: usernameError,
                  ),
                  const SizedBox(height: 16),
        
                  // Password Field
                  PasswordInputWidget(
                    controller: passwordController,
                    required: true,
                    errorText: passwordError,
                  ),
                  const SizedBox(height: 28),
        
                  // Login Button
                  PrimaryButton(
                    text: "Sign In",
                    onPressed:
                        loginProvider.isLoading
                            ? null
                            : () async {
                              print('🔵 LoginScreen: Sign In button pressed');
        
                              if (!_validateInputs()) {
                                print('❌ LoginScreen: Validation failed');
                                _showValidationError();
                                return;
                              }
        
                              print('✅ LoginScreen: Validation passed');
        
                              try {
                                print(
                                  '🔵 LoginScreen: Calling loginProvider.login()...',
                                );
        
                                await loginProvider.login(
                                  usernameController.text.trim(),
                                  passwordController.text.trim(),
                                );
        
                                print('✅ LoginScreen: Login successful');
                                print('👤 User: ${loginProvider.user?.username}');
        
                                if (mounted) {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "Welcome back, ${loginProvider.user?.username ?? 'User'}!",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
        
                                  // Navigate to HomeScreen after a short delay
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );
        
                                  if (mounted) {
                                    print('🏠 Navigating to HomeScreen...');
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const HomeScreen(),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('❌ LoginScreen: Login failed - $e');
        
                                if (mounted) {
                                  String errorMessage = _getCleanErrorMessage(e);
        
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              errorMessage,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red[700],
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                    isLoading: loginProvider.isLoading,
                    isFullWidth: true,
                    size: ButtonSize.large,
                    icon: Icon(Icons.login, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
