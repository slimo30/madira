// import 'dart:io';
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// enum DeviceMode { notSelected, master, slave }

// class NetworkService extends ChangeNotifier {
//   DeviceMode _mode = DeviceMode.notSelected;
//   String? _localIp;
//   String? _masterIp;
//   bool _isListening = false;
//   bool _isBroadcasting = false;
//   List<String> _connectedSlaves = [];

//   RawDatagramSocket? _broadcastSocket;
//   RawDatagramSocket? _listenSocket;
//   Timer? _broadcastTimer;

//   static const int broadcastPort = 8888;
//   static const int slaveListenPort = 8889;
//   static const String broadcastAddress = '255.255.255.255';

//   DeviceMode get mode => _mode;
//   String? get localIp => _localIp;
//   String? get masterIp => _masterIp;
//   bool get isListening => _isListening;
//   bool get isBroadcasting => _isBroadcasting;
//   List<String> get connectedSlaves => _connectedSlaves;
//   bool get isMaster => _mode == DeviceMode.master;
//   bool get isSlave => _mode == DeviceMode.slave;

//   // Initialization - get local IP and load saved mode and master IP
//   Future<void> initialize() async {
//     _localIp = await _getLocalIp();
//     print(' Local IP: $_localIp');
//     await loadSavedMode();
//     await loadSavedMasterIp();
//   }

//   Future<String?> _getLocalIp() async {
//     try {
//       final interfaces = await NetworkInterface.list(
//         type: InternetAddressType.IPv4,
//         includeLinkLocal: false,
//       );
//       for (var interface in interfaces) {
//         for (var addr in interface.addresses) {
//           if (addr.address.startsWith('127.')) continue;
//           return addr.address;
//         }
//       }
//     } catch (e) {
//       print(' Error getting local IP: $e');
//     }
//     return null;
//   }

//   // Load saved device mode from SharedPreferences
//   Future<DeviceMode> loadSavedMode() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedMode = prefs.getString('device_mode');
//     if (savedMode == null) {
//       _mode = DeviceMode.notSelected;
//       return _mode;
//     }
//     _mode = DeviceMode.values.firstWhere(
//       (e) => e.toString() == savedMode,
//       orElse: () => DeviceMode.notSelected,
//     );
//     print(' Loaded saved mode: $_mode');
//     notifyListeners();
//     return _mode;
//   }

//   // Save device mode to SharedPreferences
//   Future<void> _saveMode(DeviceMode mode) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('device_mode', mode.toString());
//     print(' Saved mode: $mode');
//   }

//   // Save master IP address persistently
//   Future<void> saveMasterIp(String ip) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('master_ip', ip);
//     _masterIp = ip;
//     print(' Saved master IP: $ip');
//     notifyListeners();
//   }

//   // Load saved master IP address
//   Future<void> loadSavedMasterIp() async {
//     final prefs = await SharedPreferences.getInstance();
//     _masterIp = prefs.getString('master_ip');
//     if (_masterIp != null) {
//       print(' Loaded saved master IP: $_masterIp');
//       notifyListeners();
//     }
//   }

//   // Set Master mode, save mode and local IP as master IP
//   Future<void> setMasterMode() async {
//     print(' Setting Master mode...');
//     _mode = DeviceMode.master;
//     _masterIp = _localIp;
//     await _saveMode(DeviceMode.master);
//     await saveMasterIp(_localIp ?? '');
//     notifyListeners();
//     print(' Master mode set (backend will start next)');
//   }

//   Future<void> startBroadcastingAfterBackend() async {
//     if (_mode != DeviceMode.master) return;
//     print(' Starting broadcasting after backend is ready...');
//     await _startBroadcasting();
//     await _startSlaveListener();
//     notifyListeners();
//   }

//   Future<void> _startBroadcasting() async {
//     try {
//       _broadcastSocket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4,
//         0,
//       );
//       _broadcastSocket!.broadcastEnabled = true;
//       _isBroadcasting = true;
//       _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
//         _broadcastMasterInfo();
//       });
//       print(' Broadcasting started on port $broadcastPort');
//     } catch (e) {
//       print(' Error starting broadcast: $e');
//     }
//   }

//   void _broadcastMasterInfo() {
//     if (_broadcastSocket == null || _localIp == null) return;

//     final message = jsonEncode({
//       'type': 'MADIRA_MASTER',
//       'ip': _localIp,
//       'port': 8000,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     });

//     final data = utf8.encode(message);
//     _broadcastSocket!.send(
//       data,
//       InternetAddress(broadcastAddress),
//       broadcastPort,
//     );

//     print(' Broadcasting: $_localIp');
//   }

//   Future<void> _startSlaveListener() async {
//     try {
//       _listenSocket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4,
//         slaveListenPort,
//       );
//       _listenSocket!.listen((event) {
//         if (event == RawSocketEvent.read) {
//           final packet = _listenSocket!.receive();
//           if (packet != null) {
//             _handleSlaveMessage(packet);
//           }
//         }
//       });
//       print(' Listening for slaves on port $slaveListenPort');
//     } catch (e) {
//       print(' Error starting slave listener: $e');
//     }
//   }

//   void _handleSlaveMessage(Datagram packet) {
//     try {
//       final message = utf8.decode(packet.data);
//       final data = jsonDecode(message);
//       if (data['type'] == 'MADIRA_SLAVE_CONNECT') {
//         final slaveIp = data['ip'];
//         if (!_connectedSlaves.contains(slaveIp)) {
//           _connectedSlaves.add(slaveIp);
//           print(' Slave connected: $slaveIp');
//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       print(' Error handling slave message: $e');
//     }
//   }

//   Future<void> setSlaveMode() async {
//     print(' Setting Slave mode...');
//     _mode = DeviceMode.slave;
//     await _saveMode(DeviceMode.slave);
//     await _startListeningForMaster();
//     notifyListeners();
//     print(' Slave mode activated - listening for master...');
//   }

//   Future<void> _startListeningForMaster() async {
//     try {
//       _listenSocket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4,
//         broadcastPort,
//       );
//       _isListening = true;
//       _listenSocket!.listen((event) {
//         if (event == RawSocketEvent.read) {
//           final packet = _listenSocket!.receive();
//           if (packet != null) {
//             _handleMasterBroadcast(packet);
//           }
//         }
//       });
//       print(' Listening for master on port $broadcastPort');
//       notifyListeners();
//     } catch (e) {
//       print(' Error listening for master: $e');
//     }
//   }

//   void _handleMasterBroadcast(Datagram packet) {
//     try {
//       final message = utf8.decode(packet.data);
//       final data = jsonDecode(message);
//       if (data['type'] == 'MADIRA_MASTER') {
//         final masterIp = data['ip'];
//         if (_masterIp != masterIp) {
//           _masterIp = masterIp;
//           saveMasterIp(masterIp); // save on change
//           print(' Master found: $masterIp');
//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       print(' Error handling master broadcast: $e');
//     }
//   }

//   Future<void> connectToMaster() async {
//     if (_masterIp == null || _localIp == null) {
//       print(' Cannot connect: No master IP');
//       return;
//     }
//     try {
//       final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       final message = jsonEncode({
//         'type': 'MADIRA_SLAVE_CONNECT',
//         'ip': _localIp,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       final data = utf8.encode(message);
//       socket.send(data, InternetAddress(_masterIp!), slaveListenPort);
//       await Future.delayed(const Duration(milliseconds: 500));
//       socket.close();
//       print(' Connected to master: $_masterIp');
//     } catch (e) {
//       print(' Error connecting to master: $e');
//     }
//   }

//   void confirmAndStart() {
//     print(' Master confirmed - ${_connectedSlaves.length} slaves connected');
//     if (_isBroadcasting) _stopBroadcasting();
//     notifyListeners();
//   }

//   void _stopBroadcasting() {
//     _broadcastTimer?.cancel();
//     _isBroadcasting = false;
//     print(' Broadcasting stopped');
//   }

//   Future<void> stop() async {
//     print(' Stopping NetworkService...');
//     _stopBroadcasting();
//     _broadcastSocket?.close();
//     _listenSocket?.close();
//     _isListening = false;
//     _connectedSlaves.clear();
//     notifyListeners();
//     print(' NetworkService stopped');
//   }

//   Future<void> resetMode() async {
//     print(' Resetting mode...');
//     await stop();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('device_mode');
//     await prefs.remove('master_ip'); // Remove master IP on reset
//     _mode = DeviceMode.notSelected;
//     _masterIp = null;
//     notifyListeners();
//     print(' Mode reset');
//   }

//   @override
//   void dispose() {
//     stop();
//     super.dispose();
//   }
// }
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceMode { notSelected, master, slave }

class NetworkService extends ChangeNotifier {
  DeviceMode _mode = DeviceMode.notSelected;
  String? _localIp;
  String? _masterIp;
  bool _isListening = false;
  bool _isBroadcasting = false;
  final List<String> _connectedSlaves = [];

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenSocket;
  Timer? _broadcastTimer;

  static const int broadcastPort = 8888;
  static const int slaveListenPort = 8889;
  static const String broadcastAddress = '255.255.255.255';

  DeviceMode get mode => _mode;
  String? get localIp => _localIp;
  String? get masterIp => _masterIp;
  bool get isListening => _isListening;
  bool get isBroadcasting => _isBroadcasting;
  List<String> get connectedSlaves => _connectedSlaves;
  bool get isMaster => _mode == DeviceMode.master;
  bool get isSlave => _mode == DeviceMode.slave;

  // Initialization - get local IP and load saved mode and master IP
  Future<void> initialize() async {
    _localIp = await _getLocalIp();
    print(' Local IP selected: $_localIp');
    await loadSavedMode();
    await loadSavedMasterIp();
  }

  // --- FIXED IP SELECTION LOGIC ---
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // 1. Try to find a standard local network IP (192.168.x.x)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.')) {
            return addr.address; // Priority 1: Home/Office WiFi
          }
        }
      }

      // 2. If not found, try other private ranges (10.x.x.x or 172.16.x.x)
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('10.') ||
              (addr.address.startsWith('172.') && _isClassB(addr.address))) {
            return addr.address; // Priority 2: Corporate/Other private networks
          }
        }
      }

      // 3. Fallback: Pick any non-loopback, non-autoconfig IP
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Ignore localhost (127.x.x.x) and Autoconfig (169.254.x.x)
          if (!addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print(' Error getting local IP: $e');
    }
    return null;
  }

  // Helper to check for 172.16.x.x - 172.31.x.x
  bool _isClassB(String ip) {
    List<String> parts = ip.split('.');
    if (parts.length < 2) return false;
    int? secondOctet = int.tryParse(parts[1]);
    return secondOctet != null && secondOctet >= 16 && secondOctet <= 31;
  }
  // --------------------------------

  // Load saved device mode from SharedPreferences
  Future<DeviceMode> loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('device_mode');
    if (savedMode == null) {
      _mode = DeviceMode.notSelected;
      return _mode;
    }
    _mode = DeviceMode.values.firstWhere(
      (e) => e.toString() == savedMode,
      orElse: () => DeviceMode.notSelected,
    );
    print(' Loaded saved mode: $_mode');
    notifyListeners();
    return _mode;
  }

  // Save device mode to SharedPreferences
  Future<void> _saveMode(DeviceMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_mode', mode.toString());
    print(' Saved mode: $mode');
  }

  // Save master IP address persistently
  Future<void> saveMasterIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('master_ip', ip);
    _masterIp = ip;
    print(' Saved master IP: $ip');
    notifyListeners();
  }

  // Load saved master IP address
  Future<void> loadSavedMasterIp() async {
    final prefs = await SharedPreferences.getInstance();
    _masterIp = prefs.getString('master_ip');
    if (_masterIp != null) {
      print(' Loaded saved master IP: $_masterIp');
      notifyListeners();
    }
  }

  // Set Master mode, save mode and local IP as master IP
  Future<void> setMasterMode() async {
    print(' Setting Master mode...');
    _mode = DeviceMode.master;
    _masterIp = _localIp;
    await _saveMode(DeviceMode.master);
    // Ensure local IP is valid before saving
    if (_localIp != null) {
      await saveMasterIp(_localIp!);
    } else {
      // Refresh IP if null
      _localIp = await _getLocalIp();
      if (_localIp != null) await saveMasterIp(_localIp!);
    }
    notifyListeners();
    print(' Master mode set (backend will start next)');
  }

  Future<void> startBroadcastingAfterBackend() async {
    if (_mode != DeviceMode.master) return;
    print(' Starting broadcasting after backend is ready...');
    await _startBroadcasting();
    await _startSlaveListener();
    notifyListeners();
  }

  Future<void> _startBroadcasting() async {
    try {
      // Ensure we have the correct IP before starting
      if (_localIp == null || _localIp!.startsWith('169.254')) {
        _localIp = await _getLocalIp();
      }

      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      _broadcastSocket!.broadcastEnabled = true;
      _isBroadcasting = true;
      _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _broadcastMasterInfo();
      });
      print(' Broadcasting started on port $broadcastPort');
    } catch (e) {
      print(' Error starting broadcast: $e');
    }
  }

  void _broadcastMasterInfo() {
    if (_broadcastSocket == null || _localIp == null) return;

    final message = jsonEncode({
      'type': 'MADIRA_MASTER',
      'ip': _localIp,
      'port': 8000,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final data = utf8.encode(message);
    try {
      _broadcastSocket!.send(
        data,
        InternetAddress(broadcastAddress),
        broadcastPort,
      );
      print(' Broadcasting my IP: $_localIp');
    } catch (e) {
      print(' Error sending broadcast: $e');
    }
  }

  Future<void> _startSlaveListener() async {
    try {
      _listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        slaveListenPort,
      );
      _listenSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final packet = _listenSocket!.receive();
          if (packet != null) {
            _handleSlaveMessage(packet);
          }
        }
      });
      print(' Listening for slaves on port $slaveListenPort');
    } catch (e) {
      print(' Error starting slave listener: $e');
    }
  }

  void _handleSlaveMessage(Datagram packet) {
    try {
      final message = utf8.decode(packet.data);
      final data = jsonDecode(message);
      if (data['type'] == 'MADIRA_SLAVE_CONNECT') {
        final slaveIp = data['ip'];
        if (!_connectedSlaves.contains(slaveIp)) {
          _connectedSlaves.add(slaveIp);
          print(' Slave connected: $slaveIp');
          notifyListeners();
        }
      }
    } catch (e) {
      print(' Error handling slave message: $e');
    }
  }

  Future<void> setSlaveMode() async {
    print(' Setting Slave mode...');
    _mode = DeviceMode.slave;
    await _saveMode(DeviceMode.slave);
    await _startListeningForMaster();
    notifyListeners();
    print(' Slave mode activated - listening for master...');
  }

  Future<void> _startListeningForMaster() async {
    try {
      _listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
      );
      _isListening = true;
      _listenSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final packet = _listenSocket!.receive();
          if (packet != null) {
            _handleMasterBroadcast(packet);
          }
        }
      });
      print(' Listening for master on port $broadcastPort');
      notifyListeners();
    } catch (e) {
      print(' Error listening for master: $e');
    }
  }

  void _handleMasterBroadcast(Datagram packet) {
    try {
      final message = utf8.decode(packet.data);
      final data = jsonDecode(message);
      if (data['type'] == 'MADIRA_MASTER') {
        final masterIp = data['ip'];

        // Only update if it's a valid IP and different from current
        if (masterIp != null &&
            masterIp != _masterIp &&
            !masterIp.startsWith('169.254')) {
          _masterIp = masterIp;
          saveMasterIp(masterIp); // save on change
          print(' Master found: $masterIp');
          notifyListeners();

          // Auto connect back to confirm presence
          connectToMaster();
        }
      }
    } catch (e) {
      print(' Error handling master broadcast: $e');
    }
  }

  Future<void> connectToMaster() async {
    if (_masterIp == null || _localIp == null) {
      print(' Cannot connect: No master IP or Local IP');
      // Try to refresh local IP if missing
      _localIp ??= await _getLocalIp();
      return;
    }
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final message = jsonEncode({
        'type': 'MADIRA_SLAVE_CONNECT',
        'ip': _localIp,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final data = utf8.encode(message);
      socket.send(data, InternetAddress(_masterIp!), slaveListenPort);
      await Future.delayed(const Duration(milliseconds: 500));
      socket.close();
      print(' Connected/Ack sent to master: $_masterIp');
    } catch (e) {
      print(' Error connecting to master: $e');
    }
  }

  void confirmAndStart() {
    print(' Master confirmed - ${_connectedSlaves.length} slaves connected');
    if (_isBroadcasting) _stopBroadcasting();
    notifyListeners();
  }

  void _stopBroadcasting() {
    _broadcastTimer?.cancel();
    _isBroadcasting = false;
    print(' Broadcasting stopped');
  }

  Future<void> stop() async {
    print(' Stopping NetworkService...');
    _stopBroadcasting();
    _broadcastSocket?.close();
    _listenSocket?.close();
    _isListening = false;
    _connectedSlaves.clear();
    notifyListeners();
    print(' NetworkService stopped');
  }

  Future<void> resetMode() async {
    print(' Resetting mode...');
    await stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_mode');
    await prefs.remove('master_ip');
    _mode = DeviceMode.notSelected;
    _masterIp = null;
    notifyListeners();
    print(' Mode reset');
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
