import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/providers/dashboard_provider.dart';
import 'package:madira/providers/input_provider.dart';
import 'package:madira/providers/login_provider.dart';
import 'package:madira/providers/order_provider.dart';
import 'package:madira/providers/output_proviider.dart';
import 'package:madira/providers/product_provider.dart';
import 'package:madira/providers/report_provider.dart';
import 'package:madira/providers/stock_movement_provider.dart';
import 'package:madira/providers/supplier_provider.dart';
import 'package:madira/providers/user_provider.dart';
import 'package:madira/providers/client_provider.dart';
import 'package:madira/ui/screens/home_screen.dart';
import 'package:madira/ui/screens/login_screen.dart';
import 'package:madira/ui/widgets/screen_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'core/constants/colors.dart';
import 'services/backend_service.dart';
import 'services/network_service.dart';
import 'ui/screens/mode_selection_screen.dart';
import 'ui/screens/backend_setup_screen.dart';
import 'services/backup_service.dart';
import 'services/backup_preferences.dart';
import 'widgets/backup_dialog.dart';
import 'widgets/performance_overlay.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  await LogManager.initialize();

  // Override debugPrint only
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      LogManager.log(message);
    }
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };

  // Intercept all print calls using Zone
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        windowManager.ensureInitialized().then((_) async {
          const windowOptions = WindowOptions(
            center: true,
            backgroundColor: Colors.transparent,
            skipTaskbar: false,
            titleBarStyle: TitleBarStyle.hidden,
          );
          await windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
            await windowManager.focus();
            await windowManager.maximize(); // Maximize after showing
            await windowManager.setResizable(false);
            await windowManager.setMaximizable(false);
            await windowManager.setMinimizable(true);
            await windowManager.setPreventClose(true);
          });
        });
      }
      runApp(const MaderaKitchenApp());
    },
    (error, stack) {
      LogManager.log('Uncaught error: $error\n$stack');
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        LogManager.log(line);
        parent.print(zone, line);
      },
    ),
  );
}

class LogManager {
  static LogManager? _instance;
  late final IOSink _sink;
  bool _initialized = false;
  String? _logPath;

  LogManager._();

  static Future<void> initialize() async {
    if (_instance != null) return;
    _instance = LogManager._();
    await _instance!._init();
  }

  static LogManager? get instance => _instance;

  Future<void> _init() async {
    String dirPath;
    try {
      // First try: Use logs subdirectory in installation folder
      dirPath = '${File(Platform.resolvedExecutable).parent.path}\\logs';
      Directory logsDir = Directory(dirPath);

      // Create logs directory if it doesn't exist
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      String path = '$dirPath\\madira_app_log.txt';
      File file = File(path);
      IOSink? sink;

      try {
        // Try to write to logs directory
        sink = file.openWrite(mode: FileMode.writeOnlyAppend);
        sink.writeln('[${DateTime.now()}] Log initialized in logs directory');
      } catch (e) {
        // Second try: Use root installation directory
        dirPath = File(Platform.resolvedExecutable).parent.path;
        path = '$dirPath\\madira_app_log.txt';
        file = File(path);

        try {
          sink = file.openWrite(mode: FileMode.writeOnlyAppend);
          sink.writeln(
            '[${DateTime.now()}] Log initialized in installation directory',
          );
        } catch (e2) {
          // Third fallback: Documents folder
          final appDir = await getApplicationDocumentsDirectory();
          path = '${appDir.path}\\madira_app_log.txt';
          file = File(path);
          sink = file.openWrite(mode: FileMode.writeOnlyAppend);
          sink.writeln(
            '[${DateTime.now()}] Warning: Could not write to installation folder. Logging to Documents instead.',
          );
        }
      }

      _logPath = path;
      _sink = sink;
      _initialized = true;
    } catch (e) {
      // Complete failure - can't log anywhere
      return;
    }
  }

  static void log(String message) {
    final inst = _instance;
    if (inst?._initialized ?? false) {
      inst!._sink.writeln('[${DateTime.now()}] $message');
    }
  }

  static Future<void> dispose() async {
    final inst = _instance;
    if (inst?._initialized ?? false) {
      await inst!._sink.flush();
      await inst._sink.close();
      inst._initialized = false;
    }
  }

  static Future<String?> getLogFilePath() async {
    return _instance?._logPath;
  }
}

class MaderaKitchenApp extends StatefulWidget {
  const MaderaKitchenApp({super.key});

  @override
  State<MaderaKitchenApp> createState() => _MaderaKitchenAppState();
}

class _MaderaKitchenAppState extends State<MaderaKitchenApp>
    with WindowListener {
  late BackendService _backendService;
  late NetworkService _networkService;
  bool _isClosing = false; // Track closing state

  @override
  void initState() {
    super.initState();
    _backendService = BackendService();
    _networkService = NetworkService();

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    LogManager.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    setState(() {
      _isClosing = true;
    });
    debugPrint(' Application closing - cleaning up resources...');

    try {
      await _networkService.stop();
      await _backendService.stopBackend();
      debugPrint(' Cleanup completed');
    } catch (e) {
      debugPrint('️ Error during cleanup: $e');
    }

    // Wait for UI to show closing screen
    await Future.delayed(const Duration(seconds: 1));
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    if (_isClosing) {
      // Only show the fallback (closing) screen, do NOT build providers or AppInitializer
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const FallbackScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _backendService),
        ChangeNotifierProvider.value(value: _networkService),
        ChangeNotifierProvider(
          create: (_) {
            final loginProvider = LoginProvider();
            loginProvider.checkStoredUserData();
            return loginProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => InputProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StockMovementProvider()),
        ChangeNotifierProvider(create: (_) => OutputProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'Madera Kitchen Fabrication',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: SelectionArea(child: AppInitializer(isClosing: _isClosing)),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceVariant,
        thickness: 1,
      ),
    );
  }
}

// ============================================================================
// APP INITIALIZER - IMPLEMENTS THE COMPLETE FLOW
// ============================================================================

class AppInitializer extends StatefulWidget {
  final bool isClosing;
  const AppInitializer({super.key, required this.isClosing});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  BackupService? _backupService;
  BackupPreferences? _backupPreferences;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final backendService = Provider.of<BackendService>(context, listen: false);
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    // Initialize core services and check stored login
    await networkService.initialize();
    await backendService.initialize();
    await loginProvider.checkStoredUserData();

    // Initialize backup service
    _backupPreferences = await BackupPreferences.getInstance();
    _backupService = await BackupService.initialize();

    // Clear last backup date (for testing)
    // await _backupPreferences?.clearBackupInfos();

    setState(() {
      _initialized = true;
    });

    // Trigger backup check after initialization
    _checkAndTriggerBackup();
  }

  Future<void> _checkAndTriggerBackup() async {
    if (_backupService == null || _backupPreferences == null) return;

    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    // Only trigger backup if user is logged in (to avoid 401 errors)
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    if (loginProvider.user == null) {
      debugPrint('⏭️ Skipping backup - user not logged in yet');
      return;
    }

    // Check if backup is configured
    if (!_backupPreferences!.isBackupConfigured()) {
      // First time - show setup dialog
      if (mounted) {
        _showBackupSetupDialog();
      }
      return;
    }

    // Check if backup is needed today
    if (_backupService!.shouldBackupToday()) {
      // Trigger background backup
      _performBackgroundBackup();
    }
  }

  void _showBackupSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BackupSetupDialog(
            onSetup: () async {
              Navigator.of(context).pop();
              await _showPathSelectionDialog();
            },
            onSkip: () {
              Navigator.of(context).pop();
              // Mark as skipped (don't ask again today)
              _backupPreferences?.setBackupConsent(false);
            },
          ),
    );
  }

  Future<void> _showPathSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BackupPathSelectionDialog(
            currentPath: _backupPreferences?.getBackupPath(),
            onPathSelected: (path) async {
              await _backupPreferences?.setBackupPath(path);
              await _backupPreferences?.setBackupConsent(true);

              // Trigger backup immediately after setup
              if (mounted) {
                Navigator.of(context).pop();
                _performBackgroundBackup();
              }
            },
          ),
    );
  }

  Future<void> _performBackgroundBackup() async {
    if (_backupService == null) return;

    // Perform backup in background
    // DioClient automatically handles authentication via interceptors
    final result = await _backupService!.downloadBackupInBackground();

    // Show result notification (non-intrusive)
    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Database backup completed successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backup failed: ${result.error ?? "Unknown error"}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isClosing) {
      return const FallbackScreen();
    }
    if (!_initialized) {
      return _buildInitializingScreen();
    }
    return Consumer3<NetworkService, BackendService, LoginProvider>(
      builder: (context, networkService, backendService, loginProvider, child) {
        // Mode not selected? Show ModeSelectionScreen
        if (networkService.mode == DeviceMode.notSelected) {
          return const ModeSelectionScreen();
        }

        // MASTER mode: backend config needed?
        if (networkService.mode == DeviceMode.master) {
          if (backendService.needsConfiguration) {
            return const BackendSetupScreen();
          }
          if (backendService.isStarting) {
            return _buildLoadingScreen(backendService);
          }
          if (backendService.isRunning) {
            if (networkService.isBroadcasting) networkService.confirmAndStart();
            // User logged in? Home: Login
            if (loginProvider.user != null) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          }
        }

        // SLAVE mode: Home if logged in else Login
        if (networkService.mode == DeviceMode.slave) {
          if (loginProvider.user != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        }

        // Fallback
        if (widget.isClosing) {
          return const FallbackScreen();
        }
        return const FallbackScreen();
      },
    );
  }

  Widget _buildInitializingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomTitleBar(
            title: 'Madera Kitchen',
            onClose: () => windowManager.close(),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Madera Kitchen Fabrication',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(BackendService backendService) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomTitleBar(
            title: 'Madera Kitchen - Starting Backend',
            onClose: () async {
              await backendService.stopBackend();
              await windowManager.close();
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Card(
                  elevation: 8,
                  margin: const EdgeInsets.all(32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          size: 80,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Starting Master Backend',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          backendService.statusMessage,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          ' Launching  backend...',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a few seconds',
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FallbackScreen extends StatelessWidget {
  const FallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Closing...',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
