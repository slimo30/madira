import 'package:flutter/material.dart';
import 'package:madira/ui/screens/backup_settings_screen.dart';
/// Helper class for backup-related navigation

/// Helper class for backup-related navigation
class BackupNavigator {
  /// Navigate to backup settings screen
  static Future<void> navigateToBackupSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BackupSettingsScreen(),
      ),
    );
  }

  /// Show backup settings as a dialog (for smaller screens)
  static Future<void> showBackupSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 700,
          height: 750,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const BackupSettingsScreen(),
        ),
      ),
    );
  }
}
