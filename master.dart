import 'dart:io';
import 'dart:async';
import 'dart:convert';

void main() async {
  // Create master broadcaster
  final master = MasterSimulator();
  await master.startBroadcasting();

  // Create slave listener
  final slave = SlaveSimulator();
  await slave.startListening();

  // Slave attempts to connect to master after some delay
  Future.delayed(Duration(seconds: 10), () async {
    print('\n[Slave] Attempting to connect to master...');
    await slave.sendConnectMessage();
  });

  // Run for 20 seconds and then exit
  await Future.delayed(Duration(seconds: 20));
  await master.stopBroadcasting();
  await slave.stopListening();
  print('\nSimulation complete.');
}

class MasterSimulator {
  static const int broadcastPort = 8888;
  static const String broadcastAddress = '255.255.255.255';

  RawDatagramSocket? _socket;
  Timer? _timer;
  String _localIp = 'localhost'; // simulate local IP
  bool isBroadcasting = false;

  Future<void> startBroadcasting() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      isBroadcasting = true;

      _timer = Timer.periodic(Duration(seconds: 3), (_) {
        final message = jsonEncode({
          'type': 'MADIRA_MASTER',
          'ip': _localIp,
          'port': 8000,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        final data = utf8.encode(message);
        _socket!.send(data, InternetAddress(broadcastAddress), broadcastPort);
        print('[Master] Broadcasted master info: $_localIp');
      });

      print('[Master] Broadcasting started on port $broadcastPort');
    } catch (e) {
      print('[Master] Failed to start broadcasting: $e');
    }
  }

  Future<void> stopBroadcasting() async {
    _timer?.cancel();
    _socket?.close();
    isBroadcasting = false;
    print('[Master] Broadcasting stopped');
  }
}

class SlaveSimulator {
  static const int listenPort = 8888; // Listening on same broadcast port
  RawDatagramSocket? _socket;
  String? masterIp;

  Future<void> startListening() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, listenPort);
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            _handleMessage(message);
          }
        }
      });
      print('[Slave] Listening for master broadcasts on port $listenPort');
    } catch (e) {
      print('[Slave] Error starting listening: $e');
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'MADIRA_MASTER') {
        final ip = data['ip'];
        if (masterIp != ip) {
          masterIp = ip;
          print('[Slave] Received master broadcast from IP: $ip');
        }
      }
    } catch (e) {
      print('[Slave] Error handling message: $e');
    }
  }

  Future<void> sendConnectMessage() async {
    if (masterIp == null) {
      print('[Slave] No master IP received yet, cannot connect');
      return;
    }
    final localIp = '192.168.1.101'; // simulate slave IP

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final message = jsonEncode({
        'type': 'MADIRA_SLAVE_CONNECT',
        'ip': localIp,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final data = utf8.encode(message);
      socket.send(data, InternetAddress(masterIp!), 8889); // Port where master listens for slaves
      print('[Slave] Sent connect message to master at $masterIp');
      await Future.delayed(Duration(milliseconds: 500));
      socket.close();
    } catch (e) {
      print('[Slave] Error sending connect message: $e');
    }
  }

  Future<void> stopListening() async {
    _socket?.close();
    print('[Slave] Stopped listening');
  }
}
