# Automatic Backup System

## Overview

The Madira application now includes an automatic backup system that creates daily database backups. The backup system is designed to be non-intrusive and runs in the background.

## Features

- ✅ **Automatic Daily Backups**: One backup per day, triggered after app launch
- ✅ **User-Selected Path**: Choose where to save backup files
- ✅ **Background Operation**: Backups run without blocking the UI
- ✅ **Configurable**: Enable/disable automatic backups anytime
- ✅ **Manual Backup**: Create backups on demand
- ✅ **Change Path**: Update backup location whenever needed

## How It Works

### First Launch

On the first launch after this update, you'll see a setup dialog asking if you want to enable automatic backups:

1. Click **"Set Up Now"** to configure backups
2. Select a directory where backups will be saved
3. The first backup will be created immediately

Or click **"Skip"** to configure later.

### Daily Backups

- Backups are triggered **after each app launch**
- Only **one backup per calendar day** is created (e.g., 25/11/2025)
- If you launch the app multiple times in one day, only the first launch creates a backup
- Backups run in the background - you can continue using the app

### Backup Settings

Access backup settings through your app's settings menu:

```dart
// Navigate to backup settings
BackupNavigator.navigateToBackupSettings(context);
```

In the settings screen, you can:
- **Change backup location**
- **Enable/disable automatic backups**
- **View last backup date**
- **Trigger manual backup**

## File Structure

Backup files are named with timestamps:
```
madira_backup_YYYYMMDD_HHMMSS.sql
```

Example:
```
madira_backup_20251125_154530.sql
```

## API Integration

The backup system calls the Django backend API:
```
GET http://localhost:8000/api/backup/download/
```

The API returns a SQL dump file that can be used to restore the database.

## Implementation Files

- **`lib/services/backup_preferences.dart`**: Manages backup settings (path, date, consent)
- **`lib/services/backup_service.dart`**: Core backup logic and API integration
- **`lib/widgets/backup_dialog.dart`**: UI dialogs for setup and notifications
- **`lib/screens/backup_settings_screen.dart`**: Settings screen for backup management
- **`lib/utils/backup_navigator.dart`**: Navigation helper
- **`lib/main.dart`**: Integration with app lifecycle

## Usage Examples

### Navigate to Backup Settings

```dart
import 'package:madira/utils/backup_navigator.dart';

// In your settings menu or wherever appropriate
ElevatedButton(
  onPressed: () => BackupNavigator.navigateToBackupSettings(context),
  child: const Text('Backup Settings'),
)
```

### Manual Backup Trigger

The backup settings screen includes a "Backup Now" button that creates an immediate backup regardless of the daily schedule.

### Check Backup Status

```dart
final prefs = await BackupPreferences.getInstance();

// Check if backup is configured
bool isConfigured = prefs.isBackupConfigured();

// Check if backup is needed today
bool needsBackup = prefs.isBackupNeededToday();

// Get last backup date
String? lastBackup = prefs.getLastBackupDate();
```

## Troubleshooting

### Backup Not Working

1. **Check backup path**: Ensure the selected directory exists and has write permissions
2. **Check API**: Ensure the Django backend is running at `http://localhost:8000`
3. **Check authentication**: Ensure you're logged in (auth token is required)

### Change Backup Location

1. Open backup settings
2. Click "Change Location"
3. Select a new directory
4. Future backups will use the new location

### Disable Automatic Backups

1. Open backup settings
2. Toggle "Automatic Backup" off
3. You can still create manual backups

## Technical Details

### Daily Logic

The system uses the date in `YYYY-MM-DD` format to determine if a backup is needed:

```dart
bool isBackupNeededToday() {
  final lastBackupDate = getLastBackupDate();
  if (lastBackupDate == null) return true;
  
  final today = getTodayString(); // e.g., "2025-11-25"
  return lastBackupDate != today;
}
```

### Background Operation

Backups use Dart's async/await to avoid blocking the UI thread. The file download and write operations happen asynchronously.

### Error Handling

If a backup fails:
- An error notification is shown
- The last backup date is NOT updated
- The backup will be retried on the next app launch
