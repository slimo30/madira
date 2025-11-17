# Automatic Backend Launch - How It Works

## 🚀 Overview

The Madira Kitchen application now **automatically launches the Django backend** when the app starts in Master mode. No manual intervention needed after the first-time setup!

## ✨ Key Features

- ✅ **First Launch**: User selects Master/Slave mode once
- ✅ **Subsequent Launches**: Backend starts automatically
- ✅ **Loading Screen**: Beautiful UI shows startup progress
- ✅ **Auto-Stop**: Backend closes when app closes
- ✅ **Error Recovery**: Clear error messages if startup fails

## 🔄 How It Works

### First Time Launch

```
App Starts
    ↓
No saved configuration found
    ↓
Show Mode Selection Screen
    ↓
User selects "Master Mode"
    ↓
User enters backend path: /path/to/backend/madira
    ↓
Django backend starts (5-10 seconds)
    ↓
Configuration saved to SharedPreferences
    ↓
Login screen appears
```

### Every Launch After That

```
App Starts
    ↓
🔧 Initialize AppModeProvider
    ↓
📱 Load saved mode: "Master"
    ↓
🔄 Found saved backend path
    ↓
🚀 AUTO-LAUNCHING BACKEND...
    ↓
⏳ Loading screen appears
    ↓
🚀 LAUNCHING DJANGO BACKEND - Please wait...
    ↓
✅ DJANGO BACKEND LAUNCHED SUCCESSFULLY!
    ↓
📡 Start network broadcasting
    ↓
✅ Master mode active
    ↓
Login screen appears (ready to use!)
```

### When App Closes

```
User closes app
    ↓
🚪 Application closing - cleaning up resources...
    ↓
🛑 Stopping Django backend server...
    ↓
✅ Django backend stopped
    ↓
🛑 Stopping network discovery...
    ↓
App exits cleanly
```

## 📺 What The User Sees

### Master Mode - First Launch
1. **Mode Selection Screen**
   - Beautiful card: "Master Mode" vs "Slave Mode"
   - Click Master → Enter backend path
   - Loading indicator appears

2. **Loading Screen** (5-10 seconds)
   ```
   🚀 Starting Madira Kitchen
   
   Starting Django backend server...
   
   [Spinner animation]
   
   🚀 Launching Django backend...
   This may take a few seconds
   ```

3. **Login Screen**
   - Backend is running
   - Ready to login!

### Master Mode - Subsequent Launches
1. **App icon clicked**
2. **Loading Screen** (5-10 seconds)
   - Same as above
   - Backend auto-starts in background
3. **Login Screen**
   - Ready to use immediately!

### Slave Mode
1. **Mode Selection Screen** (first time only)
2. **Loading Screen** (2-3 seconds)
   ```
   Starting Madira Kitchen
   
   Listening for master...
   
   [Spinner animation]
   ```
3. **Login Screen** when master is discovered

## 🎯 Technical Details

### Files Involved

1. **`lib/providers/app_mode_provider.dart`**
   - `initialize()`: Checks for saved mode and auto-starts
   - `_startMasterMode()`: Launches backend automatically
   - `setMasterMode()`: Saves configuration
   - `dispose()`: Stops backend on app close

2. **`lib/services/backend_manager_service.dart`**
   - `startBackend()`: Launches Django process
   - `stopBackend()`: Gracefully terminates Django

3. **`lib/main.dart`**
   - Shows loading screen during backend startup
   - Integrates with window lifecycle
   - Handles cleanup on app close

### Storage Keys

Configuration is saved in SharedPreferences:
- `app_mode`: "AppMode.master" or "AppMode.slave"
- `backend_path`: "/Users/macbookair/Desktop/Madira/backend/madira"

### Console Logs to Watch For

**Successful Auto-Launch:**
```
🔧 Initializing AppModeProvider...
📱 Loaded saved mode: AppMode.master
🚀 AUTO-STARTING MASTER MODE - Backend will launch automatically
🔄 Found saved backend path: /path/to/backend
🚀 AUTO-LAUNCHING BACKEND...
🚀 Starting Django backend server...
🚀 LAUNCHING DJANGO BACKEND - Please wait...
🔹 Django: Watching for file changes with StatReloader
🔹 Django: Performing system checks...
🔹 Django: System check identified no issues (0 silenced).
🔹 Django: Django version X.X, using settings 'madira.settings'
🔹 Django: Starting development server at http://0.0.0.0:8000/
✅ Django backend started successfully at http://0.0.0.0:8000
✅ DJANGO BACKEND LAUNCHED SUCCESSFULLY!
📡 Starting MASTER broadcast mode...
✅ Master broadcast started on port 8888
📤 Broadcast sent: 192.168.1.X
✅ Master mode configured successfully - Backend running at 192.168.1.X:8000
```

**Backend Shutdown:**
```
🚪 Application closing - cleaning up resources...
🧹 Cleaning up AppModeProvider...
🛑 Stopping Django backend server...
✅ Django backend stopped
🛑 Stopping network discovery...
```

## 🆘 Troubleshooting

### Backend Doesn't Start Automatically

**Check console for error messages:**

1. **"Backend path not found"**
   - The saved path is invalid
   - Solution: Reset configuration and re-select Master mode
   ```bash
   rm ~/Library/Preferences/com.example.madira.plist
   ```

2. **"manage.py not found"**
   - Incorrect backend path
   - Solution: Verify path contains manage.py

3. **"Python not found"**
   - Python not installed or not in PATH
   - Solution: Install Python 3.9+ or create virtual environment

4. **"Port 8000 already in use"**
   - Another Django instance is running
   - Solution: Kill existing process
   ```bash
   pkill -f "manage.py runserver"
   ```

### Loading Screen Hangs

**If stuck on "Starting Django backend server...":**

1. Check console logs for Python errors
2. Verify database migrations are applied:
   ```bash
   cd /path/to/backend/madira
   python3 manage.py migrate
   ```
3. Test Django manually:
   ```bash
   python3 manage.py runserver
   ```

### Backend Path Reset

**To reset and reconfigure:**

```bash
# macOS
rm ~/Library/Preferences/com.example.madira.plist

# Restart app and select Master mode again
```

## 🎨 User Experience Flow

### Expected Timing

| Action | Duration | User Sees |
|--------|----------|-----------|
| App Launch | < 1 second | Window appears |
| Check Configuration | < 1 second | Loading screen |
| Start Django | 5-10 seconds | Loading screen with progress |
| Start Broadcasting | 1-2 seconds | Loading screen |
| Navigate to Login | < 1 second | Login screen |
| **Total** | **7-14 seconds** | **Smooth experience** |

### Design Goals

✅ **No Manual Steps**: Backend starts automatically  
✅ **Visual Feedback**: Loading screen shows what's happening  
✅ **Error Handling**: Clear messages if something fails  
✅ **Clean Shutdown**: Backend stops when app closes  
✅ **Fast Restart**: Subsequent launches use saved config  

## 💡 Advanced Usage

### Change Backend Path

If you move the backend folder:

1. Close the app completely
2. Delete the preference file (see above)
3. Restart and select Master mode
4. Enter the new backend path

### Disable Auto-Launch (Switch to Slave)

1. Close the app
2. Delete preferences
3. Restart and select "Slave Mode"
4. Backend will NOT launch (connects to another master)

### Manual Backend Control

While the app auto-manages the backend, you can still:

**Check if backend is running:**
```bash
lsof -i :8000
# or
curl http://localhost:8000/api/
```

**Manually stop backend:**
```bash
pkill -f "manage.py runserver"
```

**Manually start backend (testing):**
```bash
cd /path/to/backend/madira
python3 manage.py runserver 0.0.0.0:8000
```

## 🔍 Verification Checklist

After first-time Master setup, verify:

- [ ] Loading screen appears with "Launching Django backend..."
- [ ] Console shows: `🚀 AUTO-LAUNCHING BACKEND...`
- [ ] Console shows: `✅ DJANGO BACKEND LAUNCHED SUCCESSFULLY!`
- [ ] Console shows: `📤 Broadcast sent: [IP address]`
- [ ] Login screen appears after loading
- [ ] Can login successfully
- [ ] When closing app, console shows: `🛑 Stopping Django backend server...`

## 📊 System Requirements

**For Automatic Backend Launch:**
- ✅ Python 3.9 or higher
- ✅ Django and dependencies installed
- ✅ Database migrations applied
- ✅ Backend path accessible
- ✅ Ports 8000 and 8888 available

**Performance:**
- First launch: 7-14 seconds
- Subsequent launches: 5-10 seconds
- Backend memory: ~50-100 MB
- Network bandwidth: Minimal (broadcasts only)

## 🎉 Summary

The automatic backend launch feature provides a **seamless desktop application experience**:

1. **First Time**: User configures once
2. **Every Time After**: Just launch and login
3. **No Manual Work**: Backend starts and stops automatically
4. **Professional UX**: Loading screens, progress indicators
5. **Clean Shutdown**: Everything stops when app closes

It's like launching any normal desktop app - simple and automatic! 🚀

---

**Documentation Version**: 1.0.0  
**Last Updated**: November 17, 2025
