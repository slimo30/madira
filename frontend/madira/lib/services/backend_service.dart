// ===================================================================
// lib/services/backend_service.dart - WITH PROPER CLEANUP
// ===================================================================
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class BackendService extends ChangeNotifier {
  Process? _process;
  int? _mainProcessPid;
  String? _backendPath;
  bool _isStarting = false;
  bool _isRunning = false;
  bool _needsConfiguration = false;
  String _statusMessage = '';
  String _errorMessage = '';

  // Getters
  String? get backendPath => _backendPath;
  bool get isStarting => _isStarting;
  bool get isRunning => _isRunning;
  bool get needsConfiguration => _needsConfiguration;
  String get statusMessage => _statusMessage;
  String get errorMessage => _errorMessage;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    print('🔧 Initializing BackendService...');

    final prefs = await SharedPreferences.getInstance();
    _backendPath = prefs.getString('backend_path');

    if (_backendPath == null || !await Directory(_backendPath!).exists()) {
      _needsConfiguration = true;
      notifyListeners();
      return;
    }

    // Auto-start backend
    await startBackend();
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECT BACKEND PATH
  // ═══════════════════════════════════════════════════════════════
  Future<void> selectBackendPath(BuildContext context) async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Validate path
        final validation = await _validatePath(selectedDirectory);

        if (!validation['valid']) {
          _errorMessage = validation['message'];
          notifyListeners();
          return;
        }

        _backendPath = selectedDirectory;
        _errorMessage = '';

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('backend_path', selectedDirectory);

        print('✅ Backend path saved: $selectedDirectory');
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error selecting folder: $e';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _validatePath(String path) async {
    final madiraFolder = Directory('$path${Platform.pathSeparator}madira');
    final managePy = File('$path${Platform.pathSeparator}manage.py');

    if (!await madiraFolder.exists()) {
      return {'valid': false, 'message': 'Invalid: "madira" folder not found'};
    }

    if (!await managePy.exists()) {
      return {'valid': false, 'message': 'Invalid: manage.py not found'};
    }

    return {'valid': true, 'message': ''};
  }

  // ═══════════════════════════════════════════════════════════════
  // START BACKEND
  // ═══════════════════════════════════════════════════════════════
  // In BackendService class, update startBackend method:

  Future<bool> startBackend() async {
    if (_backendPath == null) {
      _errorMessage = 'No backend path configured';
      notifyListeners();
      return false;
    }

    // FIX: Check if already running OR starting
    if (_isRunning) {
      print('⚠️ Backend already running');
      return true; // Return true since it's already running
    }

    if (_isStarting) {
      print('⚠️ Backend already starting');
      return false; // Prevent duplicate starts
    }

    try {
      _isStarting = true;
      _statusMessage = 'Starting Django backend...';
      _errorMessage = '';
      _needsConfiguration = false; // ← FIX: Set to false when starting
      notifyListeners();

      print('🚀 Starting Django backend...');
      print('📂 Path: $_backendPath');

      _process = await _startProcess();

      if (_process == null) {
        throw Exception('Failed to create process');
      }

      _mainProcessPid = _process!.pid;
      print('✅ Process started with PID: $_mainProcessPid');
      _monitorOutput();

      await Future.delayed(const Duration(seconds: 8));

      final responding = await _checkServerHealth();

      _isStarting = false;

      if (responding) {
        _isRunning = true;
        _needsConfiguration = false;
        _statusMessage = 'Backend running successfully';
        print('✅ Django backend running at http://127.0.0.1:8000');
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Backend not responding after startup';
        _needsConfiguration = true; // ← FIX: Set back to true if failed
        await _killAllPythonProcesses();
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isStarting = false;
      _errorMessage = 'Failed to start backend: $e';
      _needsConfiguration = true; // ← FIX: Set back to true if error
      await _killAllPythonProcesses();
      notifyListeners();
      return false;
    }
  }

  // Future<bool> startBackend() async {
  //   if (_backendPath == null) {
  //     _errorMessage = 'No backend path configured';
  //     notifyListeners();
  //     return false;
  //   }

  //   if (_isRunning) {
  //     print('⚠️ Backend already running');
  //     return true;
  //   }

  //   try {
  //     _isStarting = true;
  //     _statusMessage = 'Starting Django backend...';
  //     _errorMessage = '';
  //     notifyListeners();

  //     print('🚀 Starting Django backend...');
  //     print('📂 Path: $_backendPath');

  //     _process = await _startProcess();

  //     if (_process == null) {
  //       throw Exception('Failed to create process');
  //     }

  //     _mainProcessPid = _process!.pid;
  //     print('✅ Process started with PID: $_mainProcessPid');
  //     _monitorOutput();

  //     await Future.delayed(const Duration(seconds: 8));

  //     final responding = await _checkServerHealth();

  //     _isStarting = false;

  //     if (responding) {
  //       _isRunning = true;
  //       _needsConfiguration = false;
  //       _statusMessage = 'Backend running successfully';
  //       print('✅ Django backend running at http://127.0.0.1:8000');
  //       notifyListeners();
  //       return true;
  //     } else {
  //       _errorMessage = 'Backend not responding after startup';
  //       await _killAllPythonProcesses(); // Clean up if failed
  //       notifyListeners();
  //       return false;
  //     }
  //   } catch (e) {
  //     _isStarting = false;
  //     _errorMessage = 'Failed to start backend: $e';
  //     await _killAllPythonProcesses(); // Clean up on error
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<Process?> _startProcess() async {
    try {
      final arguments = [
        '/c',
        'cd',
        '/d',
        _backendPath!,
        '&&',
        'python',
        '-m',
        'uvicorn',
        'madira.asgi:application',
        '--host',
        '0.0.0.0',
        '--port',
        '8000',
        '--workers',
        '4',
      ];

      return await Process.start(
        'cmd',
        arguments,
        workingDirectory: _backendPath,
        runInShell: false,
      );
    } catch (e) {
      print('❌ Process start error: $e');
      return null;
    }
  }
  // In BackendService._monitorOutput()

  void _monitorOutput() {
    _process?.stdout
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isNotEmpty) print('🟢 Django: $line');
        });

    _process?.stderr
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) return;

          // FIX: Recognize INFO logs as non-errors
          if (line.contains('INFO:') ||
              line.contains('Uvicorn running') ||
              line.contains('Started server process') ||
              line.contains('Application startup complete') ||
              line.contains('Waiting for application startup')) {
            print('🔵 Django: $line'); // Blue for info
          } else {
            print('🔴 Django Error: $line'); // Red for actual errors
          }
        });

    _process?.exitCode.then((code) {
      if (code != 0) {
        print('⚠️ Django process exited with code: $code');
        _isRunning = false;
        _killAllPythonProcesses();
        notifyListeners();
      }
    });
  }

  Future<bool> _checkServerHealth() async {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 2));

      try {
        final socket = await Socket.connect(
          '127.0.0.1',
          8000,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
        print('✅ Server responding (${i + 1}/20)');
        return true;
      } catch (e) {
        print('⏳ Waiting for server... (${i + 1}/20)');
      }
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════
  // STOP BACKEND - IMPROVED WITH CHILD PROCESS KILLING
  // ═══════════════════════════════════════════════════════════════
  Future<void> stopBackend() async {
    if (!_isRunning && _process == null) {
      print('⚠️ Backend not running');
      return;
    }

    try {
      print('🛑 Stopping Django backend...');

      // First try graceful shutdown
      if (_process != null) {
        _process!.kill(ProcessSignal.sigterm);

        try {
          await _process!.exitCode.timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('⚠️ Graceful shutdown timeout, force killing...');
              _process!.kill(ProcessSignal.sigkill);
              return -1;
            },
          );
        } catch (e) {
          print('⚠️ Error waiting for process exit: $e');
        }
      }

      // Kill all Python processes (including uvicorn workers)
      await _killAllPythonProcesses();

      _process = null;
      _mainProcessPid = null;
      _isRunning = false;

      print('✅ Backend stopped completely');
      notifyListeners();
    } catch (e) {
      print('❌ Error stopping backend: $e');
      // Force kill as fallback
      await _killAllPythonProcesses();
      _process = null;
      _mainProcessPid = null;
      _isRunning = false;
      notifyListeners();
    }
  }

  /// Kill all Python processes using Windows taskkill
  Future<void> _killAllPythonProcesses() async {
    if (!Platform.isWindows) return;

    try {
      print('🔪 Killing all Python processes...');

      // Use taskkill to forcefully terminate all python.exe processes
      final result = await Process.run('taskkill', [
        '/F',
        '/IM',
        'python.exe',
      ], runInShell: true);

      if (result.exitCode == 0) {
        print('✅ All Python processes killed');
        print(result.stdout);
      } else if (result.exitCode == 128) {
        // Exit code 128 means no process found - this is fine
        print('ℹ️ No Python processes found');
      } else {
        print('⚠️ taskkill exit code: ${result.exitCode}');
        print(result.stderr);
      }

      // Wait a moment for processes to actually terminate
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify port is free
      await _verifyPortFree();
    } catch (e) {
      print('❌ Error killing Python processes: $e');
    }
  }

  /// Verify that port 8000 is free
  Future<void> _verifyPortFree() async {
    try {
      // Try to bind to port 8000
      final serverSocket = await ServerSocket.bind('127.0.0.1', 8000);
      await serverSocket.close();
      print('✅ Port 8000 is free');
    } catch (e) {
      print('⚠️ Port 8000 still in use, waiting...');
      await Future.delayed(const Duration(seconds: 2));

      // Try one more time to kill processes
      try {
        await Process.run('taskkill', ['/F', '/IM', 'python.exe']);
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RESET CONFIGURATION
  // ═══════════════════════════════════════════════════════════════
  Future<void> resetConfiguration() async {
    print('🔄 Resetting backend configuration...');

    await stopBackend();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_path');

    _backendPath = null;
    _needsConfiguration = true;
    _errorMessage = '';
    _statusMessage = '';

    notifyListeners();
    print('✅ Configuration reset');
  }

  @override
  void dispose() {
    // Synchronous dispose - schedule async cleanup
    stopBackend();
    super.dispose();
  }
}
