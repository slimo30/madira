import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/login_provider.dart';
import '../../providers/app_mode_provider.dart';

class TopBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TopBarWidget({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final appModeProvider = Provider.of<AppModeProvider>(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceVariant.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Logo and Company Name
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MADERA',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Centered Page Title
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),

              // Network Status Indicator
              _buildNetworkStatusBadge(appModeProvider),
              
              const SizedBox(width: 12),

              // Settings Menu Button
              _buildSettingsMenu(context, appModeProvider, loginProvider),
              
              const SizedBox(width: 12),

              // User Profile Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceVariant, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          loginProvider.user?.username
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loginProvider.user?.username ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            (loginProvider.user?.role ?? 'user').toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusBadge(AppModeProvider appModeProvider) {
    IconData icon;
    Color color;
    String tooltip;

    switch (appModeProvider.mode) {
      case AppMode.master:
        icon = Icons.computer;
        color = Colors.green;
        tooltip = 'Master Mode - IP: ${appModeProvider.masterIp ?? "N/A"}';
        break;
      case AppMode.slave:
        icon = Icons.devices;
        color = Colors.blue;
        tooltip = 'Slave Mode - Connected to: ${appModeProvider.masterIp ?? "Discovering..."}';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        tooltip = 'Not Configured';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              appModeProvider.mode.toString().split('.').last.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(
    BuildContext context,
    AppModeProvider appModeProvider,
    LoginProvider loginProvider,
  ) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Icon(
          Icons.settings,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        // Mode Information
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Network Configuration',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mode: ${appModeProvider.mode.toString().split('.').last.toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (appModeProvider.masterIp != null)
                Text(
                  'IP: ${appModeProvider.masterIp}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        
        // Reset Configuration
        PopupMenuItem<String>(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18, color: Colors.orange),
              const SizedBox(width: 12),
              Text(
                'Reset Configuration',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        // Logout
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        if (value == 'reset') {
          _showResetConfirmationDialog(context, appModeProvider);
        } else if (value == 'logout') {
          _showLogoutConfirmation(context, loginProvider);
        }
      },
    );
  }

  void _showResetConfirmationDialog(
    BuildContext context,
    AppModeProvider appModeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              'Reset Configuration',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will reset your network configuration:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem('• Current mode will be cleared'),
                  _buildWarningItem('• Backend will stop (if Master)'),
                  _buildWarningItem('• Network broadcasting will stop'),
                  _buildWarningItem('• You will need to reconfigure on next launch'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to continue?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performReset(context, appModeProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Reset', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Future<void> _performReset(
    BuildContext context,
    AppModeProvider appModeProvider,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Resetting configuration...',
              style: GoogleFonts.inter(),
            ),
          ],
        ),
      ),
    );

    try {
      // Reset the app mode configuration
      await appModeProvider.resetMode();
      
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Configuration reset successfully!',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Navigate to mode selection screen
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/mode-selection');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation(
    BuildContext context,
    LoginProvider loginProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await loginProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Logout', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }
}
