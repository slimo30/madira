import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/providers/dashboard_provider.dart';
import 'package:madira/providers/input_provider.dart';
import 'package:madira/providers/login_provider.dart';
import 'package:madira/providers/order_provider.dart';
import 'package:madira/providers/output_proviider.dart';
import 'package:madira/providers/product_provider.dart';
import 'package:madira/providers/stock_movement_provider.dart';
import 'package:madira/providers/supplier_provider.dart';
import 'package:madira/providers/user_provider.dart';
import 'package:madira/providers/client_provider.dart';
import 'package:madira/providers/app_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'core/constants/colors.dart';

import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/mode_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop platforms (macOS, Windows, Linux)
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1920, 1080), // Set a large default size
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      fullScreen: false, // Set to true if you want truly full screen
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize(); // Maximize the window
      await windowManager.setResizable(false); // Prevent resizing
      await windowManager.setMaximizable(false); // Disable maximize button
      await windowManager.setMinimizable(true); // Allow minimize
    });
  }

  runApp(const MaderaKitchenApp());
}

// ============================================================================
// MAIN APP WITH LIFECYCLE MANAGEMENT
// ============================================================================
class MaderaKitchenApp extends StatefulWidget {
  const MaderaKitchenApp({Key? key}) : super(key: key);

  @override
  State<MaderaKitchenApp> createState() => _MaderaKitchenAppState();
}

class _MaderaKitchenAppState extends State<MaderaKitchenApp>
    with WindowListener {
  late AppModeProvider _appModeProvider;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Clean up resources when window is closing
    print('🚪 Application closing - cleaning up resources...');

    // Stop backend and network services if they are running
    try {
      _appModeProvider.dispose();
    } catch (e) {
      print('⚠️ Error during cleanup: $e');
    }

    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            _appModeProvider = AppModeProvider();
            _appModeProvider.initialize();
            return _appModeProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final loginProvider = LoginProvider();
            // Check for stored user data when app starts
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
      ],
      child: MaterialApp(
        title: 'Madera Kitchen Fabrication',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            background: AppColors.background,
          ),
          scaffoldBackgroundColor: AppColors.background,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppColors.surface,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        ),
        home: Consumer2<AppModeProvider, LoginProvider>(
          builder: (context, appModeProvider, loginProvider, child) {
            print('🏠 MainApp Consumer: Building home widget...');
            print('🏠 App Mode: ${appModeProvider.mode}');
            print('🏠 Is Initialized: ${appModeProvider.isInitialized}');
            print('🏠 Is Starting Backend: ${appModeProvider.isStartingBackend}');
            print('🏠 Master IP: ${appModeProvider.masterIp}');
            print('🏠 Status: ${appModeProvider.statusMessage}');
            print('🏠 Login Provider User: ${loginProvider.user}');

            // Show loading screen while backend is starting
            if (appModeProvider.isStartingBackend || !appModeProvider.isInitialized) {
              print('🏠 Navigation: LOADING (Backend Starting)');
              return Scaffold(
                body: Container(
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
                              'Starting Madira Kitchen',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              appModeProvider.statusMessage,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            const CircularProgressIndicator(),
                            if (appModeProvider.mode == AppMode.master) ...[
                              const SizedBox(height: 24),
                              Text(
                                '🚀 Launching Django backend...',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This may take a few seconds',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            // Check if app mode is configured
            if (appModeProvider.mode == AppMode.notConfigured) {
              print('🏠 Navigation: MODE_SELECTION');
              return SelectionArea(child: ModeSelectionScreen());
            }

            // Then check if user is logged in
            final isLoggedIn = loginProvider.user != null;
            print('🏠 Navigation Decision: ${isLoggedIn ? 'HOME' : 'LOGIN'}');

            // Wrap each screen with SelectionArea for text selection
            return SelectionArea(
              child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
            );
          },
        ),
        routes: {
          '/home': (context) => const SelectionArea(child: HomeScreen()),
          '/login': (context) => const SelectionArea(child: LoginScreen()),
          '/mode-selection':
              (context) => const SelectionArea(child: ModeSelectionScreen()),
        },
      ),
    );
  }
}
