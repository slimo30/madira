# Madira Kitchen - Quick Start Guide

## 🚀 Getting Started in 3 Steps

### Prerequisites
- ✅ Python 3.9+ installed
- ✅ Flutter installed
- ✅ All backend dependencies installed (`pip install -r req.txt`)
- ✅ Database migrations applied (`python manage.py migrate`)

---

## 📱 First Time Setup

### Option A: Master Device (Main Server)

1. **Launch the app**
   ```bash
   cd /Users/macbookair/Desktop/Madira/frontend/madira
   flutter run -d macos
   ```

2. **When you see the configuration screen:**
   - Click **"Master Mode"**
   - Enter backend path: `/Users/macbookair/Desktop/Madira/backend/madira`
   - Click **Confirm**

3. **Wait 5-10 seconds** for the backend to start

4. **Login** with your credentials

✅ **Done!** Your master is now running and broadcasting to the network.

---

### Option B: Slave Device (Client)

1. **Ensure master is running first** on another device

2. **Launch the app** on the slave device
   ```bash
   cd /Users/macbookair/Desktop/Madira/frontend/madira
   flutter run -d macos
   ```

3. **When you see the configuration screen:**
   - Click **"Slave Mode"**
   - Wait for auto-discovery (5-10 seconds)

4. **Login** with your credentials

✅ **Done!** Your slave is now connected to the master.

---

## 🔍 How to Verify It's Working

### Master Device
Check the console logs for:
```
✅ Django backend started successfully at http://0.0.0.0:8000
✅ Master broadcast started on port 8888
📤 Broadcast sent: 192.168.1.X
```

### Slave Device
Check the console logs for:
```
✅ Slave discovery started, listening on port 8888
🎯 Master discovered at: 192.168.1.X:8000
```

---

## ⚡ Quick Commands

### Test if Backend is Running
```bash
curl http://localhost:8000/api/
```

### Check Network Discovery
```bash
# On any device on the network
nc -ul 8888
# Should see JSON messages every 3 seconds
```

### Reset Configuration
Delete app preferences and restart:
```bash
# macOS
rm ~/Library/Preferences/com.example.madira.plist

# Then restart the app
```

---

## 🆘 Common Issues

| Problem | Solution |
|---------|----------|
| "Backend path not found" | Verify the path is correct and contains `manage.py` |
| "Master not discovered" | Ensure both devices are on the same WiFi network |
| "Connection timeout" | Check the master device is running and Django is active |
| "Port already in use" | Stop any existing Django processes: `pkill -f "manage.py runserver"` |

---

## 📊 Network Architecture

```
┌─────────────────────────────────────────────┐
│           MASTER DEVICE                     │
│  ┌──────────────────────────────────┐      │
│  │   Flutter App (Master Mode)      │      │
│  └───────────┬──────────────────────┘      │
│              │ Manages                      │
│              ▼                              │
│  ┌──────────────────────────────────┐      │
│  │   Django Backend (Port 8000)     │      │
│  └──────────────────────────────────┘      │
│              │                              │
│              │ Broadcasts IP via UDP:8888   │
└──────────────┼──────────────────────────────┘
               │
               │ Local Network
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼          ▼          ▼
┌───────┐  ┌───────┐  ┌───────┐
│ SLAVE │  │ SLAVE │  │ SLAVE │
│   #1  │  │   #2  │  │   #3  │
└───────┘  └───────┘  └───────┘
  Auto      Auto        Auto
  Connect   Connect     Connect
```

---

## 🎯 What Happens Behind the Scenes

### Master Launch Sequence
1. App starts → Checks saved mode → Finds "Master"
2. Starts Django backend on `0.0.0.0:8000`
3. Gets local IP address (e.g., 192.168.1.100)
4. Starts UDP broadcast every 3 seconds
5. Shows login screen

### Slave Launch Sequence
1. App starts → Checks saved mode → Finds "Slave"
2. Binds to UDP port 8888
3. Listens for master broadcasts
4. Receives master IP → Updates API endpoint
5. Shows login screen

### Master Shutdown Sequence
1. User closes app
2. App cleanup triggered
3. Stops UDP broadcasting
4. Stops Django backend gracefully
5. App exits

---

## 💡 Pro Tips

1. **Use Static IP for Master**: Configure your router to assign a static IP to the master device for consistent connectivity.

2. **Check Firewall**: Ensure ports 8000 (TCP) and 8888 (UDP) are not blocked.

3. **Monitor Logs**: Console logs provide detailed information about connection status.

4. **Multiple Slaves**: You can have unlimited slave devices connecting to one master.

5. **Network Changes**: If master IP changes, slaves will automatically reconnect within 3 seconds.

---

## 📞 Next Steps

- **Production Deployment**: See [NETWORK_SETUP.md](NETWORK_SETUP.md) for detailed configuration
- **Security**: Implement HTTPS and authentication for production use
- **Troubleshooting**: Check console logs for detailed error messages

---

**Quick Reference:**
- Master Backend Port: **8000**
- Discovery Port: **8888**
- Broadcast Interval: **3 seconds**
- Auto-reconnect: **Yes**

**Last Updated**: November 17, 2025
