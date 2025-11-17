# Madira Kitchen - Master/Slave Network Setup

## 🌐 Overview

The Madira Kitchen application now supports a **Master-Slave architecture** for network deployment. This allows multiple devices to connect to a single backend server automatically without manual IP configuration.

## 🎯 Architecture

### Master Mode
- **Runs the Django backend server** locally
- **Broadcasts its IP address** on the network via UDP (port 8888)
- **Automatically starts/stops** the backend when the app launches/closes
- **Serves all slave devices** on the network

### Slave Mode
- **Listens for master broadcasts** on the network
- **Automatically connects** to the discovered master
- **Updates connection** if master IP changes
- **No manual configuration required** after first setup

## 📋 Features

✅ **Automatic Backend Management** - Master starts Django on launch, stops on close  
✅ **Auto-Discovery** - Slaves find master automatically via UDP broadcast  
✅ **Dynamic IP Handling** - Automatically adapts if master IP changes  
✅ **One-Time Setup** - Mode selection is saved and remembered  
✅ **Network Resilient** - Handles network changes gracefully  
✅ **Multi-Platform** - Works on macOS, Windows, and Linux

## 🚀 Setup Instructions

### Step 1: Configure the Master Device

1. **Launch the application** on the master device
2. **Select "Master Mode"** from the configuration screen
3. **Enter the backend path** (e.g., `/Users/macbookair/Desktop/Madira/backend/madira`)
   - You can use the folder picker button or paste the path manually
4. **Wait for initialization** - The backend will start automatically
5. **Verify success** - You should see a green success message

**What happens behind the scenes:**
- Django backend starts on `0.0.0.0:8000`
- Master broadcasts its IP every 3 seconds on UDP port 8888
- Backend URL is automatically configured in the app

### Step 2: Configure Slave Devices

1. **Launch the application** on each slave device
2. **Select "Slave Mode"** from the configuration screen
3. **Wait for discovery** - The app will automatically find the master
4. **Verify connection** - You should see a green success message

**What happens behind the scenes:**
- Slave listens for UDP broadcasts on port 8888
- Automatically connects to the discovered master IP
- Updates connection if master IP changes

### Step 3: Login and Use

After configuration, all devices (master and slaves) will show the **login screen**. Use your credentials to access the system.

## 🔧 Technical Details

### Network Ports Used

- **8000**: Django REST API (HTTP)
- **8888**: UDP broadcast for auto-discovery

### Files Created

```
lib/services/
  ├── network_discovery_service.dart    # UDP broadcast/discovery
  └── backend_manager_service.dart      # Django lifecycle management

lib/providers/
  └── app_mode_provider.dart            # Mode coordination

lib/ui/screens/
  └── mode_selection_screen.dart        # UI for mode selection
```

### Configuration Storage

Mode settings are saved in `SharedPreferences`:
- `app_mode`: Current mode (master/slave)
- `backend_path`: Path to Django backend (master only)

### Backend Requirements

The Django backend must:
- ✅ Have `manage.py` in the specified directory
- ✅ Have Python 3 installed (or virtual environment)
- ✅ Have all dependencies installed (`pip install -r req.txt`)
- ✅ Have database migrations applied (`python manage.py migrate`)

## 🛠️ Troubleshooting

### Master Won't Start

**Problem**: "Failed to start master mode"  
**Solutions**:
1. Verify backend path is correct
2. Check Python is installed: `python3 --version`
3. Check dependencies: `cd backend/madira && pip install -r req.txt`
4. Check migrations: `python3 manage.py migrate`
5. Look at console logs for specific errors

### Slave Can't Find Master

**Problem**: Slave stuck on "Listening for master..."  
**Solutions**:
1. Ensure master and slave are on the **same network**
2. Check firewall allows UDP port 8888
3. Verify master is running (check master device)
4. Try restarting both devices
5. Check network doesn't block broadcast packets

### Connection Lost During Use

**Problem**: "Connection timeout" or API errors  
**Solutions**:
1. Check master device is still running
2. Verify network connection is stable
3. Restart the slave device
4. Check Django logs on master device

### IP Address Changed

**Problem**: Master IP changed (DHCP reassignment)  
**Solution**: The system handles this automatically! Slaves will reconnect within ~3 seconds.

## 🔄 Reset Configuration

If you need to change from master to slave (or vice versa):

1. Close the application
2. Delete the app's storage data (platform-specific):
   - **macOS**: `~/Library/Preferences/com.example.madira.plist`
   - **Linux**: `~/.local/share/madira/`
   - **Windows**: `%APPDATA%\madira\`
3. Restart the application
4. Select the new mode

## 📡 Network Configuration

### For IT Administrators

If deploying in an enterprise environment:

1. **Firewall Rules**:
   - Allow inbound TCP 8000 on master
   - Allow UDP 8888 broadcast on all devices

2. **Static IP (Recommended for Master)**:
   - Assign static IP to master device
   - Prevents IP changes from disrupting service

3. **Network Segmentation**:
   - All devices must be on the same subnet
   - Broadcast packets must be allowed

## 🧪 Testing the Setup

### Test Master

```bash
# On the master device, check if Django is running:
curl http://localhost:8000/api/

# Check if broadcasting (requires packet capture tool):
tcpdump -i any -n port 8888
```

### Test Slave Discovery

```bash
# On any device on the network, listen for broadcasts:
nc -ul 8888
# You should see JSON broadcast messages every 3 seconds
```

## 🎨 UI Flow

```
App Launch
    ↓
Check Saved Mode
    ↓
┌─────────────────┬─────────────────┐
│ Not Configured  │   Configured    │
├─────────────────┼─────────────────┤
│ Show Mode       │ Start Master    │
│ Selection       │ or Slave Mode   │
└─────────────────┴─────────────────┘
         ↓                  ↓
    Select Mode       Login Screen
         ↓                  ↓
   Master/Slave      Home Screen
```

## 📝 Code Examples

### Manually Access Backend URL

```dart
// In any service or provider
import 'package:provider/provider.dart';
import '../providers/app_mode_provider.dart';

// Get current backend URL
final appModeProvider = Provider.of<AppModeProvider>(context, listen: false);
String backendUrl = appModeProvider.getBackendUrl();
print('Backend: $backendUrl'); // http://192.168.1.100:8000
```

### Check Current Mode

```dart
final appModeProvider = Provider.of<AppModeProvider>(context);

if (appModeProvider.mode == AppMode.master) {
  print('Running as master');
} else if (appModeProvider.mode == AppMode.slave) {
  print('Running as slave');
}
```

## 🔒 Security Considerations

⚠️ **Important**: This setup is designed for **local network use only**.

For production deployment:
- Use HTTPS/TLS for API communication
- Implement authentication for UDP broadcasts
- Use VPN for remote access
- Configure proper firewall rules
- Use static IPs or DNS names

## 📞 Support

For issues or questions:
1. Check the console logs (important debugging info)
2. Review this documentation
3. Check network connectivity
4. Verify backend is running properly

## 🎉 Success Indicators

**Master Running Successfully:**
- ✅ Green notification: "Master mode configured successfully"
- ✅ Console: "Django backend started successfully"
- ✅ Console: "Master broadcast started on port 8888"

**Slave Connected Successfully:**
- ✅ Green notification: "Slave mode configured"
- ✅ Console: "Slave discovery started"
- ✅ Console: "Master discovered at: [IP address]"
- ✅ Login screen appears

---

**Last Updated**: November 17, 2025  
**Version**: 1.0.0
