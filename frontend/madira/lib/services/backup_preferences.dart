import 'package:shared_preferences/shared_preferences.dart';

/// Manages backup preferences including path, last backup date, and user consent
class BackupPreferences {
  static const String _keyBackupPath = 'backup_path';
  static const String _keyLastBackupDate = 'last_backup_date';
  static const String _keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String _keyBackupConsent = 'backup_consent_given';
  static const String _keyLastBackupTime = 'last_backup_time';

  final SharedPreferences _prefs;

  BackupPreferences(this._prefs);

  /// Initialize and get instance
  static Future<BackupPreferences> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return BackupPreferences(prefs);
  }

  /// Get the saved backup directory path
  String? getBackupPath() {
    return _prefs.getString(_keyBackupPath);
  }

  /// Set the backup directory path
  Future<bool> setBackupPath(String path) async {
    return await _prefs.setString(_keyBackupPath, path);
  }

  /// Get the last backup date in YYYY-MM-DD format
  String? getLastBackupDate() {
    return _prefs.getString(_keyLastBackupDate);
  }
  String? getLastBackupTime() {
    return _prefs.getString(_keyLastBackupTime);
  }
  /// Set the last backup date (YYYY-MM-DD format)
  Future<void> setLastBackupDate(String date) async {
    await _prefs.setString(_keyLastBackupDate, date);
final now = DateTime.now();
final timeOnly = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

await _prefs.setString(
  _keyLastBackupTime,
  timeOnly,
);
  }

  /// Clear the last backup date (for testing)
  Future<void> clearBackupInfos() async {
    await _prefs.remove(_keyLastBackupDate);
    await _prefs.remove(_keyAutoBackupEnabled);
    await _prefs.remove(_keyBackupConsent);
    await _prefs.remove(_keyBackupPath);   
    await _prefs.remove(_keyLastBackupTime);    
  }

  /// Check if automatic backup is enabled
  bool isAutoBackupEnabled() {
    return _prefs.getBool(_keyAutoBackupEnabled) ?? true; // Default: enabled
  }

  /// Set automatic backup enabled/disabled
  Future<bool> setAutoBackupEnabled(bool enabled) async {
    return await _prefs.setBool(_keyAutoBackupEnabled, enabled);
  }

  /// Check if user has given consent for backups
  bool hasBackupConsent() {
    return _prefs.getBool(_keyBackupConsent) ?? false;
  }

  /// Set backup consent
  Future<bool> setBackupConsent(bool consent) async {
    return await _prefs.setBool(_keyBackupConsent, consent);
  }

  /// Check if backup is needed today
  /// Returns true if no backup has been made today
  bool isBackupNeededToday() {
    final lastBackupDate = getLastBackupDate();
    if (lastBackupDate == null) {
      return true; // Never backed up
    }

    final today = _getTodayString();
    return lastBackupDate != today;
  }

  /// Check if backup is configured (path is set and consent given)
  bool isBackupConfigured() {
    return getBackupPath() != null && hasBackupConsent();
  }

  /// Get today's date in YYYY-MM-DD format
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Clear all backup preferences
  Future<bool> clearAll() async {
    await _prefs.remove(_keyBackupPath);
    await _prefs.remove(_keyLastBackupDate);
    await _prefs.remove(_keyLastBackupTime);
    await _prefs.remove(_keyAutoBackupEnabled);
    await _prefs.remove(_keyBackupConsent);
    return true;
  }
}
