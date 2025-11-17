import 'dart:io';
import 'dart:async';

/// Service to manage Django backend server lifecycle
/// Master starts/stops the backend automatically
class BackendManagerService {
  Process? _djangoProcess;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final String _backendPath;
  final String _pythonExecutable;

  BackendManagerService({
    required String backendPath,
    String pythonExecutable = 'python3',
  }) : _backendPath = backendPath,
       _pythonExecutable = pythonExecutable;

  // ═══════════════════════════════════════════════════════════════
  // START DJANGO BACKEND SERVER
  // ═══════════════════════════════════════════════════════════════

  Future<void> startBackend({String host = '0.0.0.0', int port = 8000}) async {
    if (_isRunning) {
      print('⚠️ Backend is already running');
      return;
    }

    try {
      print('🚀 Starting Django backend server...');
      print('📂 Backend path: $_backendPath');
      print('🐍 Python executable: $_pythonExecutable');

      // Verify backend path exists
      final backendDir = Directory(_backendPath);
      if (!await backendDir.exists()) {
        throw Exception('Backend directory not found: $_backendPath');
      }

      // Check if manage.py exists
      final managePyPath = '$_backendPath/manage.py';
      if (!await File(managePyPath).exists()) {
        throw Exception('manage.py not found at: $managePyPath');
      }

      // Determine the correct Python command based on platform
      String pythonCmd = _pythonExecutable;

      // On macOS/Linux, try to use virtual environment if exists
      if (Platform.isMacOS || Platform.isLinux) {
        // First try in the parent directory (common setup: backend/env/ and backend/madira/)
        final parentVenvPython = '${Directory(_backendPath).parent.path}/env/bin/python';
        // Then try in the same directory (alternative setup: backend/madira/env/)
        final localVenvPython = '$_backendPath/env/bin/python';
        
        if (await File(parentVenvPython).exists()) {
          pythonCmd = parentVenvPython;
          print('✅ Using virtual environment Python: $parentVenvPython');
        } else if (await File(localVenvPython).exists()) {
          pythonCmd = localVenvPython;
          print('✅ Using virtual environment Python: $localVenvPython');
        } else {
          print('⚠️ No virtual environment found, using system Python: $pythonCmd');
        }
      } else if (Platform.isWindows) {
        final parentVenvPython = '${Directory(_backendPath).parent.path}\\env\\Scripts\\python.exe';
        final localVenvPython = '$_backendPath\\env\\Scripts\\python.exe';
        
        if (await File(parentVenvPython).exists()) {
          pythonCmd = parentVenvPython;
          print('✅ Using virtual environment Python: $parentVenvPython');
        } else if (await File(localVenvPython).exists()) {
          pythonCmd = localVenvPython;
          print('✅ Using virtual environment Python: $localVenvPython');
        } else {
          print('⚠️ No virtual environment found, using system Python: $pythonCmd');
        }
      }

      print('🎯 Python command: $pythonCmd');
      print('🎯 Working directory: $_backendPath');
      print('🎯 Starting server at: $host:$port');

      // Start Django server
      _djangoProcess = await Process.start(
        pythonCmd,
        [
          'manage.py',
          'runserver',
          '$host:$port',
          '--noreload', // Disable auto-reloader to avoid issues
        ],
        workingDirectory: _backendPath,
        runInShell: false,
      );

      _isRunning = true;
      print('🔄 Django process started with PID: ${_djangoProcess!.pid}');

      // Listen to output
      _djangoProcess!.stdout.transform(SystemEncoding().decoder).listen((data) {
        print('🔹 Django: $data');
      });

      _djangoProcess!.stderr.transform(SystemEncoding().decoder).listen((data) {
        print('🔸 Django Error: $data');
      });

      // Monitor process exit
      _djangoProcess!.exitCode.then((exitCode) {
        print('⚠️ Django server exited with code: $exitCode');
        _isRunning = false;
        _djangoProcess = null;
      });

      // Wait a bit to ensure server starts properly
      print('⏳ Waiting for Django to start (5 seconds)...');
      await Future.delayed(Duration(seconds: 5));

      // Verify server is responding
      if (await _isServerResponding(host, port)) {
        print('✅ Django backend started successfully at http://$host:$port');
      } else {
        print('⚠️ Django backend process started but not responding on port $port');
        print('⚠️ Check the Django logs above for errors');
      }
    } catch (e) {
      _isRunning = false;
      _djangoProcess = null;
      print('❌ Failed to start backend: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STOP DJANGO BACKEND SERVER
  // ═══════════════════════════════════════════════════════════════

  Future<void> stopBackend() async {
    if (!_isRunning || _djangoProcess == null) {
      print('⚠️ Backend is not running');
      return;
    }

    try {
      print('🛑 Stopping Django backend server...');

      // Try graceful shutdown first
      _djangoProcess!.kill(ProcessSignal.sigterm);

      // Wait up to 5 seconds for graceful shutdown
      final timeout = Future.delayed(Duration(seconds: 5));
      final exitCode = await Future.any([
        _djangoProcess!.exitCode,
        timeout.then((_) => -1),
      ]);

      if (exitCode == -1) {
        // Force kill if graceful shutdown failed
        print('⚠️ Graceful shutdown timeout, forcing kill...');
        _djangoProcess!.kill(ProcessSignal.sigkill);
      }

      _isRunning = false;
      _djangoProcess = null;

      print('✅ Django backend stopped');
    } catch (e) {
      print('❌ Error stopping backend: $e');
      _isRunning = false;
      _djangoProcess = null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _isServerResponding(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host == '0.0.0.0' ? '127.0.0.1' : host,
        port,
        timeout: Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> restartBackend({
    String host = '0.0.0.0',
    int port = 8000,
  }) async {
    print('🔄 Restarting Django backend...');
    await stopBackend();
    await Future.delayed(Duration(seconds: 2));
    await startBackend(host: host, port: port);
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  Future<void> dispose() async {
    await stopBackend();
  }
}
