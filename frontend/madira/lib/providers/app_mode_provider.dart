import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/network_discovery_service.dart';
import '../services/backend_manager_service.dart';
import '../core/network/dio_client.dart';

enum AppMode { notConfigured, master, slave }

/// Provider to manage app mode (Master/Slave) and coordinate
/// network discovery and backend management
class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.notConfigured;
  AppMode get mode => _mode;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isStartingBackend = false;
  bool get isStartingBackend => _isStartingBackend;

  String? _masterIp;
  String? get masterIp => _masterIp;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  final NetworkDiscoveryService _networkService = NetworkDiscoveryService();
  BackendManagerService? _backendManager;

  static const String _modeKey = 'app_mode';
  static const String _backendPathKey = 'backend_path';

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 Initializing AppModeProvider...');
      _statusMessage = 'Initializing application...';
      notifyListeners();

      // Load saved mode from storage
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_modeKey);

      if (savedMode != null) {
        _mode = AppMode.values.firstWhere(
          (e) => e.toString() == savedMode,
          orElse: () => AppMode.notConfigured,
        );
        print('📱 Loaded saved mode: $_mode');

        // Auto-start based on saved mode
        if (_mode == AppMode.master) {
          print('🚀 AUTO-STARTING MASTER MODE - Backend will launch automatically');
          _statusMessage = 'Starting master mode...';
          notifyListeners();
          await _startMasterMode();
        } else if (_mode == AppMode.slave) {
          print('🚀 AUTO-STARTING SLAVE MODE - Discovering master...');
          _statusMessage = 'Starting slave mode...';
          notifyListeners();
          await _startSlaveMode();
        }
      }

      _isInitialized = true;
      _statusMessage = 'Ready';
      notifyListeners();
    } catch (e) {
      print('❌ Initialization error: $e');
      _errorMessage = 'Failed to initialize: $e';
      _statusMessage = 'Initialization failed';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MODE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> setMasterMode(String backendPath) async {
    try {
      print('🎯 Setting up MASTER mode...');
      _isStartingBackend = true;
      _errorMessage = null;
      _statusMessage = 'Initializing backend manager...';
      notifyListeners();

      // Initialize backend manager
      _backendManager = BackendManagerService(backendPath: backendPath);

      // Start backend server
      _statusMessage = 'Starting Django backend server...';
      notifyListeners();
      print('🚀 LAUNCHING DJANGO BACKEND - Please wait...');

      await _backendManager!.startBackend(host: '0.0.0.0', port: 8000);
      print('✅ DJANGO BACKEND LAUNCHED SUCCESSFULLY!');

      // Start broadcasting IP
      _statusMessage = 'Starting network broadcast...';
      notifyListeners();
      await _networkService.startMasterBroadcast();
      _masterIp = _networkService.currentMasterIp;

      // Update Dio client with new backend URL
      _updateBackendUrl();

      // Save configuration
      _mode = AppMode.master;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, _mode.toString());
      await prefs.setString(_backendPathKey, backendPath);

      _isStartingBackend = false;
      _statusMessage = 'Master mode active';
      print('✅ Master mode configured successfully - Backend running at $_masterIp:8000');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to set master mode: $e');
      _errorMessage = 'Failed to start master mode: $e';
      _statusMessage = 'Master mode failed';
      _mode = AppMode.notConfigured;
      _isStartingBackend = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setSlaveMode() async {
    try {
      print('🎯 Setting up SLAVE mode...');
      _errorMessage = null;
      _statusMessage = 'Starting network discovery...';
      notifyListeners();

      // Start listening for master broadcasts
      await _networkService.startSlaveDiscovery();

      // Listen for master IP changes
      _networkService.masterIpStream.listen((ip) {
        _masterIp = ip;
        _statusMessage = 'Connected to master at $ip';
        _updateBackendUrl();
        notifyListeners();
      });

      // Save configuration
      _mode = AppMode.slave;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, _mode.toString());

      _statusMessage = 'Listening for master...';
      print('✅ Slave mode configured successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to set slave mode: $e');
      _errorMessage = 'Failed to start slave mode: $e';
      _statusMessage = 'Slave mode failed';
      _mode = AppMode.notConfigured;
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _startMasterMode() async {
    final prefs = await SharedPreferences.getInstance();
    final backendPath = prefs.getString(_backendPathKey);

    if (backendPath != null) {
      print('🔄 Found saved backend path: $backendPath');
      print('🚀 AUTO-LAUNCHING BACKEND...');
      await setMasterMode(backendPath);
    } else {
      print('⚠️ Backend path not found, mode will be reset');
      _mode = AppMode.notConfigured;
      notifyListeners();
    }
  }

  Future<void> _startSlaveMode() async {
    await setSlaveMode();
  }

  void _updateBackendUrl() {
    final backendUrl = _networkService.getBackendUrl();
    print('🔄 Updating backend URL to: $backendUrl');
    DioClient().updateBaseUrl(backendUrl);
  }

  // ═══════════════════════════════════════════════════════════════
  // BACKEND URL
  // ═══════════════════════════════════════════════════════════════

  String getBackendUrl() {
    return _networkService.getBackendUrl();
  }

  // ═══════════════════════════════════════════════════════════════
  // RESET CONFIGURATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> resetMode() async {
    print('🔄 Resetting app mode...');

    // Stop all services
    _networkService.stop();
    await _backendManager?.stopBackend();

    // Clear storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
    await prefs.remove(_backendPathKey);

    // Reset state
    _mode = AppMode.notConfigured;
    _masterIp = null;
    _errorMessage = null;
    _backendManager = null;

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    print('🧹 Cleaning up AppModeProvider...');
    _networkService.dispose();
    _backendManager?.dispose();
    super.dispose();
  }
}
