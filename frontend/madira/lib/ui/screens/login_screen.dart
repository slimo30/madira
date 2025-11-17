import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/providers/login_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_button_widget.dart';
import '../../core/constants/colors.dart';

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
      body: Center(
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
                // Logo - Display as-is without modifications
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
                              print(
                                '❌ LoginScreen: Validation failed - empty inputs detected',
                              );
                              _showValidationError();
                              return;
                            }

                            print('✅ LoginScreen: Validation passed');
                            print(
                              '🔵 Username: ${usernameController.text.trim()}',
                            );
                            print(
                              '🔵 Current loading state: ${loginProvider.isLoading}',
                            );
                            print(
                              '🔵 Current user state: ${loginProvider.user}',
                            );

                            try {
                              print(
                                '🔵 LoginScreen: Calling loginProvider.login()...',
                              );
                              await loginProvider.login(
                                usernameController.text.trim(),
                                passwordController.text.trim(),
                              );
                              print(
                                '🔵 LoginScreen: Login call completed successfully',
                              );
                              print(
                                '🔵 LoginScreen: User after login: ${loginProvider.user}',
                              );

                              if (mounted) {
                                print(
                                  '🔵 LoginScreen: Showing success snackbar',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Login successful! Welcome to MADERA.",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              print(
                                '❌ LoginScreen: Login failed with error: $e',
                              );
                              if (mounted) {
                                print('🔵 LoginScreen: Showing error snackbar');

                                String errorMessage = _getCleanErrorMessage(e);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMessage,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primary,
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

                // Welcome message and logout button
                if (loginProvider.user != null) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Welcome, ${loginProvider.user!.username}",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedCustomButton(
                          text: "Logout",
                          onPressed: () async {
                            await loginProvider.logout();
                          },
                          isFullWidth: true,
                          size: ButtonSize.medium,
                          icon: Icon(Icons.logout, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
