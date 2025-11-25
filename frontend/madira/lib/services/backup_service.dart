import 'dart:io';
import 'package:dio/dio.dart';
import 'backup_preferences.dart';
import '../core/network/dio_client.dart';

/// Result of a backup operation
class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;
  final DateTime timestamp;

  BackupResult({
    required this.success,
    this.filePath,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  BackupResult.success(this.filePath)
      : success = true,
        error = null,
        timestamp = DateTime.now();

  BackupResult.failure(this.error)
      : success = false,
        filePath = null,
        timestamp = DateTime.now();
}

/// Service for handling database backups
class BackupService {
  final BackupPreferences preferences;
  final DioClient _dioClient;

  BackupService({
    required this.preferences,
    DioClient? dioClient,
  }) : _dioClient = dioClient ?? DioClient();

  /// Initialize backup service
  static Future<BackupService> initialize() async {
    final prefs = await BackupPreferences.getInstance();
    return BackupService(
      preferences: prefs,
    );
  }

  /// Check if backup should run today
  /// Returns true if auto-backup is enabled, configured, and not done today
  bool shouldBackupToday() {
    if (!preferences.isAutoBackupEnabled()) {
      return false;
    }

    if (!preferences.isBackupConfigured()) {
      return false;
    }

    return preferences.isBackupNeededToday();
  }

  /// Download backup from API and save to configured path
  /// DioClient automatically handles authentication tokens
  Future<BackupResult> downloadBackup({
    String? customPath,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Get backup path
      final backupPath = customPath ?? preferences.getBackupPath();
      if (backupPath == null) {
        return BackupResult.failure('Backup path not configured');
      }

      // Verify directory exists
      final directory = Directory(backupPath);
      if (!await directory.exists()) {
        return BackupResult.failure('Backup directory does not exist: $backupPath');
      }

      // Generate filename with timestamp
      final now = DateTime.now();
      final filename = 'madira_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.sql';
      final filePath = '$backupPath/$filename';

      // Download backup file using DioClient
      // DioClient automatically adds auth token via interceptor
      // Don't specify Accept header - let Django use its default
      final response = await _dioClient.dio.get(
        '/backup/download/',
        options: Options(
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200) {
        // Save file
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        // Update last backup date
        final today = _getTodayString();
        await preferences.setLastBackupDate(today);

        return BackupResult.success(filePath);
      } else {
        return BackupResult.failure('Failed to download backup: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return BackupResult.failure('Network error: ${e.message}');
    } catch (e) {
      return BackupResult.failure('Unexpected error: $e');
    }
  }

  /// Run backup in background
  /// This prevents blocking the UI thread
  Future<BackupResult> downloadBackupInBackground({
    String? customPath,
  }) async {
    try {
      final result = await downloadBackup(
        customPath: customPath,
      );

      return result;
    } catch (e) {
      return BackupResult.failure('Background backup failed: $e');
    }
  }

  /// Trigger automatic backup if needed
  /// Returns null if backup not needed, otherwise returns BackupResult
  Future<BackupResult?> autoBackupIfNeeded() async {
    if (!shouldBackupToday()) {
      return null;
    }

    return await downloadBackupInBackground();
  }

  /// Get today's date in YYYY-MM-DD format
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get backup file size in MB
  static Future<double> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    }
    return 0.0;
  }

  /// Validate backup path
  static Future<bool> isValidBackupPath(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        return false;
      }

      // Try to create a test file to verify write permissions
      final testFile = File('$path/.backup_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
