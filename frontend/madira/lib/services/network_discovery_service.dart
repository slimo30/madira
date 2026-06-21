// import 'dart:io';
// import 'dart:async';
// import 'dart:convert';
// import 'package:network_info_plus/network_info_plus.dart';

// /// Service for auto-discovery of master server on the network
// /// Master broadcasts its IP, slaves listen and connect automatically
// class NetworkDiscoveryService {
//   static const int BROADCAST_PORT = 8888;
//   static const int BACKEND_PORT = 8000;
//   static const String DISCOVERY_MESSAGE = 'MADIRA_MASTER_SERVER';

//   RawDatagramSocket? _broadcastSocket;
//   RawDatagramSocket? _listenSocket;
//   Timer? _broadcastTimer;

//   final _masterIpController = StreamController<String>.broadcast();
//   Stream<String> get masterIpStream => _masterIpController.stream;

//   String? _currentMasterIp;
//   String? get currentMasterIp => _currentMasterIp;

//   // ═══════════════════════════════════════════════════════════════
//   // MASTER MODE: Broadcast IP address to network
//   // ═══════════════════════════════════════════════════════════════

//   Future<void> startMasterBroadcast() async {
//     try {
//       print(' Starting MASTER broadcast mode...');

//       // Get local IP address
//       final localIp = await _getLocalIpAddress();
//       if (localIp == null) {
//         throw Exception('Could not determine local IP address');
//       }

//       print(' Master IP: $localIp');
//       _currentMasterIp = localIp;

//       // Create UDP socket for broadcasting
//       _broadcastSocket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4,
//         0,
//       );
//       _broadcastSocket!.broadcastEnabled = true;

//       // Broadcast every 3 seconds
//       _broadcastTimer = Timer.periodic(Duration(seconds: 3), (timer) {
//         _sendBroadcast(localIp);
//       });

//       // Send initial broadcast immediately
//       _sendBroadcast(localIp);

//       print(' Master broadcast started on port $BROADCAST_PORT');
//     } catch (e) {
//       print(' Failed to start master broadcast: $e');
//       rethrow;
//     }
//   }

//   void _sendBroadcast(String ipAddress) {
//     try {
//       final message = jsonEncode({
//         'type': DISCOVERY_MESSAGE,
//         'ip': ipAddress,
//         'port': BACKEND_PORT,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });

//       final data = utf8.encode(message);
//       _broadcastSocket?.send(
//         data,
//         InternetAddress('255.255.255.255'),
//         BROADCAST_PORT,
//       );

//       print(' Broadcast sent: $ipAddress');
//     } catch (e) {
//       print(' Broadcast send error: $e');
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // SLAVE MODE: Listen for master broadcasts
//   // ═══════════════════════════════════════════════════════════════

//   Future<void> startSlaveDiscovery() async {
//     try {
//       print(' Starting SLAVE discovery mode...');

//       // Bind to broadcast port to receive messages
//       _listenSocket = await RawDatagramSocket.bind(
//         InternetAddress.anyIPv4,
//         BROADCAST_PORT,
//       );

//       _listenSocket!.listen((event) {
//         if (event == RawSocketEvent.read) {
//           final datagram = _listenSocket!.receive();
//           if (datagram != null) {
//             _handleBroadcastMessage(datagram);
//           }
//         }
//       });

//       print(' Slave discovery started, listening on port $BROADCAST_PORT');
//     } catch (e) {
//       print(' Failed to start slave discovery: $e');
//       rethrow;
//     }
//   }

//   void _handleBroadcastMessage(Datagram datagram) {
//     try {
//       final message = utf8.decode(datagram.data);
//       final data = jsonDecode(message);

//       if (data['type'] == DISCOVERY_MESSAGE) {
//         final masterIp = data['ip'] as String;
//         final masterPort = data['port'] as int;

//         // Update master IP if changed
//         if (_currentMasterIp != masterIp) {
//           _currentMasterIp = masterIp;
//           _masterIpController.add(masterIp);
//           print(' Master discovered at: $masterIp:$masterPort');
//         }
//       }
//     } catch (e) {
//       print(' Error processing broadcast message: $e');
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // UTILITY METHODS
//   // ═══════════════════════════════════════════════════════════════

//   Future<String?> _getLocalIpAddress() async {
//     try {
//       final info = NetworkInfo();

//       // Try WiFi first
//       String? ip = await info.getWifiIP();
//       if (ip != null && ip.isNotEmpty && ip != '127.0.0.1') {
//         return ip;
//       }

//       // Fallback: Get from network interfaces
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (addr.type == InternetAddressType.IPv4 &&
//               !addr.isLoopback &&
//               !addr.address.startsWith('169.254')) {
//             return addr.address;
//           }
//         }
//       }

//       return null;
//     } catch (e) {
//       print(' Error getting local IP: $e');
//       return null;
//     }
//   }

//   String getBackendUrl() {
//     if (_currentMasterIp != null) {
//       return 'http://$_currentMasterIp:$BACKEND_PORT';
//     }
//     return 'http://127.0.0.1:$BACKEND_PORT'; // Fallback
//   }

//   // ═══════════════════════════════════════════════════════════════
//   // CLEANUP
//   // ═══════════════════════════════════════════════════════════════

//   void stop() {
//     print(' Stopping network discovery...');
//     _broadcastTimer?.cancel();
//     _broadcastSocket?.close();
//     _listenSocket?.close();
//     _currentMasterIp = null;
//   }

//   void dispose() {
//     stop();
//     _masterIpController.close();
//   }
// }
