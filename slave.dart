import 'dart:io';
import 'dart:async';
import 'dart:convert';

class SlaveSimulator {
  static const int masterBroadcastPort = 8888;
  static const int slaveConnectPort = 8889;

  RawDatagramSocket? _listenSocket;
  String? masterIp;

  // Start listening for master broadcasts
  Future<void> startListening() async {
    try {
      _listenSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, masterBroadcastPort);
      _listenSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _listenSocket!.receive();
          if (datagram != null) {
            _handleMasterBroadcast(datagram);
          }
        }
      });
      print('[Slave] Listening for master broadcasts on port $masterBroadcastPort');
    } catch (e) {
      print('[Slave] Failed to start listening: $e');
    }
  }

  void _handleMasterBroadcast(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      final data = jsonDecode(message);
      if (data['type'] == 'MADIRA_MASTER') {
        final newMasterIp = data['ip'];
        if (masterIp != newMasterIp) {
          masterIp = newMasterIp;
          print('[Slave] Received master IP: $masterIp');
        }
      }
    } catch (e) {
      print('[Slave] Error decoding master broadcast: $e');
    }
  }

  // Send connect message to master to increment connected slaves count
  Future<void> sendConnectMessage() async {
    if (masterIp == null) {
      print('[Slave] No master IP found, cannot connect');
      return;
    }
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final localIp = await _getLocalIp() ?? '0.0.0.0';
      final message = jsonEncode({
        'type': 'MADIRA_SLAVE_CONNECT',
        'ip': localIp,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final data = utf8.encode(message);
      socket.send(data, InternetAddress(masterIp!), slaveConnectPort);
      print('[Slave] Sent connect message to master at $masterIp');
      await Future.delayed(const Duration(milliseconds: 500));
      socket.close();
    } catch (e) {
      print('[Slave] Error sending connect message: $e');
    }
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('[Slave] Error getting local IP: $e');
    }
    return null;
  }

  Future<void> stopListening() async {
    _listenSocket?.close();
    print('[Slave] Stopped listening');
  }
}

Future<void> main() async {
  final slave = SlaveSimulator();
  await slave.startListening();

  // Give some time to receive a few master broadcasts
  await Future.delayed(Duration(seconds: 5));

  // Attempt to connect to master after receiving IP
  await slave.sendConnectMessage();

  // Keep listening for some time before exiting
  await Future.delayed(Duration(seconds: 10));
  await slave.stopListening();

  print('Slave simulation ended.');
}
