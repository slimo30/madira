import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/user_roles.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/login_provider.dart';
import '../widgets/custom_button_widget.dart';
import '../widgets/custom_input_widget.dart';
import '../widgets/custom_dropdown_widget.dart';
import '../widgets/custom_dialog_widget.dart';
import '../widgets/responsive_table_widget.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    if (loginProvider.user?.role == 'admin') {
      userProvider.fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    if (loginProvider.user?.role != 'admin') {
      return Center(
        child: Text(
          'Access Denied: Admin privileges required',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SizedBox(
      height: screenHeight * 1.6,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error State - Display at TOP
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  if (userProvider.error != null) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error: ${userProvider.error}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedCustomButton(
                            text: 'Retry',
                            onPressed: () => userProvider.fetchUsers(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users Management',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage system users and permissions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Create User Button
                  PrimaryButton(
                    text: 'New User',
                    onPressed: () {
                      _showCreateUserDialog(context);
                    },
                    size: ButtonSize.medium,
                    icon: const Icon(
                      Icons.person_add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Users Tables - Active and Inactive
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  if (userProvider.isLoading) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }

                  final activeUsers =
                      userProvider.users.where((u) => u.isActive).toList();
                  final inactiveUsers =
                      userProvider.users.where((u) => !u.isActive).toList();

                  if (userProvider.users.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Users Found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first user to get started',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Users Section
                      if (activeUsers.isNotEmpty) ...[
                        Text(
                          'Active Users (${activeUsers.length})',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveTable(
                          columns: [
                            'User ID',
                            'Username',
                            'Full Name',
                            'Role',
                            'Created',
                            'Actions',
                          ],
                          minColumnWidth: 100,
                          rows:
                              activeUsers
                                  .map(
                                    (user) => _buildUserRow(
                                      context,
                                      user,
                                      userProvider,
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Inactive Users Section
                      if (inactiveUsers.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Inactive Users (${inactiveUsers.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResponsiveTable(
                          columns: [
                            'User ID',
                            'Username',
                            'Full Name',
                            'Role',
                            'Created',
                            'Actions',
                          ],
                          minColumnWidth: 100,
                          rows:
                              inactiveUsers
                                  .map(
                                    (user) => _buildUserRow(
                                      context,
                                      user,
                                      userProvider,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],

                      // No Inactive Users Message
                      if (inactiveUsers.isEmpty && activeUsers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            'No inactive users',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUserRow(
    BuildContext context,
    UserModel user,
    UserProvider userProvider,
  ) {
    return [
      // User ID
      Text(
        user.id.toString(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      // Username
      Text(user.username, style: GoogleFonts.inter(fontSize: 12)),
      // Full Name
      Text(
        user.fullName.isEmpty ? '-' : user.fullName,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Role Badge
      _RoleBadge(role: user.role),
      // Created Date
      Text(user.formattedCreatedAt, style: GoogleFonts.inter(fontSize: 12)),
      // Actions
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 16),
            color: AppColors.primary,
            tooltip: 'View',
            onPressed: () {
              _showUserDetailDialog(context, user);
            },
          ),
          if (user.id != 1)
            if (user.isActive)
              IconButton(
                icon: const Icon(Icons.block, size: 16),
                color: AppColors.warning,
                tooltip: 'Deactivate',
                onPressed: () {
                  _showDeactivateConfirm(context, user, userProvider);
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                color: AppColors.success,
                tooltip: 'Reactivate',
                onPressed: () {
                  _showReactivateConfirm(context, user, userProvider);
                },
              ),
        ],
      ),
    ];
  }

  void _showCreateUserDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    String selectedRole = UserRole.simpleUser;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => CustomDialogWidget(
                  title: 'Create New User',
                  isScrollable: true,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomInputWidget(
                        controller: usernameController,
                        labelText: 'Username',
                        hintText: 'Enter username',
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      PasswordInputWidget(
                        controller: passwordController,
                        labelText: 'Password',
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      CustomInputWidget(
                        controller: fullNameController,
                        labelText: 'Full Name',
                        hintText: 'Enter full name',
                      ),
                      const SizedBox(height: 16),
                      CustomDropdownWidget<String>(
                        labelText: 'Role',
                        value: selectedRole,
                        required: true,
                        hintText: 'Select a role',
                        prefixIcon: Icons.security,
                        items:
                            UserRole.allRoles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(UserRole.getDisplayName(role)),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    OutlinedCustomButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      text: 'Create',
                      onPressed: () async {
                        if (usernameController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill in all required fields',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          await userProvider.createUser(
                            username: usernameController.text,
                            password: passwordController.text,
                            role: selectedRole,
                            fullName: fullNameController.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'User created successfully',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error: $e',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  void _showUserDetailDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.big,
            title: 'User Details',
            isScrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'User ID',
                  user.id.toString(),
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow('Username', user.username),
                const Divider(),
                _buildDetailRow(
                  'Full Name',
                  user.fullName.isEmpty ? 'Not provided' : user.fullName,
                ),
                const Divider(),
                _buildDetailRow(
                  'Role',
                  UserRole.getDisplayName(user.role),
                  isHighlight: true,
                ),
                const Divider(),
                _buildDetailRow(
                  'Status',
                  user.isActive ? 'Active' : 'Inactive',
                  isHighlight: user.isActive,
                ),
                const Divider(),
                _buildDetailRow('Created At', user.formattedCreatedAt),
              ],
            ),
            actions: [
              PrimaryButton(
                text: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeactivateConfirm(
    BuildContext context,
    UserModel user,
    UserProvider userProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Deactivate User',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to deactivate ${user.username}?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              OutlinedCustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Deactivate',
                onPressed: () async {
                  try {
                    await userProvider.deactivateUser(user.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'User deactivated successfully',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showReactivateConfirm(
    BuildContext context,
    UserModel user,
    UserProvider userProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialogWidget(
            size: DialogSize.small,
            title: 'Reactivate User',
            isScrollable: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to reactivate ${user.username}?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              OutlinedCustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                text: 'Reactivate',
                onPressed: () async {
                  try {
                    await userProvider.reactivateUser(user.id);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'User reactivated successfully',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}

// Role Badge Widget
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String displayText;

    switch (role.toLowerCase()) {
      case 'admin':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        borderColor = AppColors.primary.withOpacity(0.3);
        textColor = AppColors.primary;
        displayText = 'Admin';
        break;
      case 'responsible':
        backgroundColor = Colors.orange.withOpacity(0.1);
        borderColor = Colors.orange.withOpacity(0.3);
        textColor = Colors.orange;
        displayText = 'Responsible';
        break;
      case 'simple_user':
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = 'Simple User';
        break;
      default:
        backgroundColor = AppColors.info.withOpacity(0.1);
        borderColor = AppColors.info.withOpacity(0.3);
        textColor = AppColors.info;
        displayText = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
