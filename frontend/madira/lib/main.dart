// // ===================================================================
// // lib/main.dart - COMPLETE WITH TITLE BAR ON ALL SCREENS
// // ===================================================================
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:madira/providers/dashboard_provider.dart';
// import 'package:madira/providers/input_provider.dart';
// import 'package:madira/providers/login_provider.dart';
// import 'package:madira/providers/order_provider.dart';
// import 'package:madira/providers/output_proviider.dart';
// import 'package:madira/providers/product_provider.dart';
// import 'package:madira/providers/stock_movement_provider.dart';
// import 'package:madira/providers/supplier_provider.dart';
// import 'package:madira/providers/user_provider.dart';
// import 'package:madira/providers/client_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:window_manager/window_manager.dart';
// import 'dart:io' show Platform;
// import 'core/constants/colors.dart';
// import 'services/backend_service.dart';
// import 'ui/screens/login_screen.dart';
// import 'ui/screens/home_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Configure window for desktop
//   if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
//     await windowManager.ensureInitialized();

//     const windowOptions = WindowOptions(
//       size: Size(1920, 1080),
//       center: true,
//       backgroundColor: Colors.transparent,
//       skipTaskbar: false,
//       titleBarStyle: TitleBarStyle.hidden, // Hidden for custom title bar
//       fullScreen: false,
//     );

//     await windowManager.waitUntilReadyToShow(windowOptions, () async {
//       await windowManager.show();
//       await windowManager.focus();
//       await windowManager.maximize();
//       await windowManager.setResizable(false);
//       await windowManager.setMaximizable(false);
//       await windowManager.setMinimizable(true);
//     });
//   }

//   runApp(const MaderaKitchenApp());
// }

// // ============================================================================
// // MAIN APP WITH BACKEND SERVICE
// // ============================================================================
// class MaderaKitchenApp extends StatefulWidget {
//   const MaderaKitchenApp({Key? key}) : super(key: key);

//   @override
//   State<MaderaKitchenApp> createState() => _MaderaKitchenAppState();
// }

// class _MaderaKitchenAppState extends State<MaderaKitchenApp>
//     with WindowListener {
//   late BackendService _backendService;

//   @override
//   void initState() {
//     super.initState();
//     _backendService = BackendService();

//     if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
//       windowManager.addListener(this);
//     }
//   }

//   @override
//   void dispose() {
//     if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
//       windowManager.removeListener(this);
//     }
//     super.dispose();
//   }

//   @override
//   void onWindowClose() async {
//     print('🚪 Application closing - cleaning up resources...');

//     try {
//       await _backendService.stopBackend();
//       print('✅ Backend stopped successfully');
//     } catch (e) {
//       print('⚠️ Error during cleanup: $e');
//     }

//     await windowManager.destroy();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider.value(value: _backendService),
//         ChangeNotifierProvider(
//           create: (_) {
//             final loginProvider = LoginProvider();
//             loginProvider.checkStoredUserData();
//             return loginProvider;
//           },
//         ),
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//         ChangeNotifierProvider(create: (_) => ClientProvider()),
//         ChangeNotifierProvider(create: (_) => DashboardProvider()),
//         ChangeNotifierProvider(create: (_) => SupplierProvider()),
//         ChangeNotifierProvider(create: (_) => OrderProvider()),
//         ChangeNotifierProvider(create: (_) => InputProvider()),
//         ChangeNotifierProvider(create: (_) => ProductProvider()),
//         ChangeNotifierProvider(create: (_) => StockMovementProvider()),
//         ChangeNotifierProvider(create: (_) => OutputProvider()),
//       ],
//       child: MaterialApp(
//         title: 'Madera Kitchen Fabrication',
//         debugShowCheckedModeBanner: false,
//         theme: _buildTheme(),
//         home: const AppInitializer(),
//       ),
//     );
//   }

//   ThemeData _buildTheme() {
//     return ThemeData(
//       useMaterial3: true,
//       textTheme: GoogleFonts.interTextTheme(),
//       colorScheme: ColorScheme.light(
//         primary: AppColors.primary,
//         secondary: AppColors.secondary,
//         surface: AppColors.surface,
//         background: AppColors.background,
//       ),
//       scaffoldBackgroundColor: AppColors.background,
//       appBarTheme: AppBarTheme(
//         backgroundColor: AppColors.secondary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         titleTextStyle: GoogleFonts.inter(
//           fontSize: 20,
//           fontWeight: FontWeight.w600,
//           color: Colors.white,
//           letterSpacing: -0.5,
//         ),
//       ),
//       cardTheme: CardTheme(
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: AppColors.surface,
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           textStyle: GoogleFonts.inter(
//             fontWeight: FontWeight.w600,
//             fontSize: 14,
//           ),
//         ),
//       ),
//       dividerTheme: const DividerThemeData(
//         color: AppColors.surfaceVariant,
//         thickness: 1,
//       ),
//     );
//   }
// }

// // ============================================================================
// // APP INITIALIZER - Handles backend check and navigation
// // ============================================================================
// class AppInitializer extends StatefulWidget {
//   const AppInitializer({Key? key}) : super(key: key);

//   @override
//   State<AppInitializer> createState() => _AppInitializerState();
// }

// class _AppInitializerState extends State<AppInitializer> {
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     final backendService = Provider.of<BackendService>(context, listen: false);
//     await backendService.initialize();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<BackendService, LoginProvider>(
//       builder: (context, backendService, loginProvider, child) {
//         // Show backend setup if path not configured
//         if (backendService.needsConfiguration) {
//           return const BackendSetupScreen();
//         }

//         // Show loading while starting backend
//         if (backendService.isStarting) {
//           return _buildLoadingScreen(backendService);
//         }

//         // Navigate to appropriate screen WITH TITLE BAR
//         final isLoggedIn = loginProvider.user != null;
//         return _ScreenWrapper(
//           child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
//         );
//       },
//     );
//   }

//   Widget _buildLoadingScreen(BackendService backendService) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Column(
//         children: [
//           CustomTitleBar(
//             title: 'Madera Kitchen',
//             onClose: () async {
//               await backendService.stopBackend();
//               await windowManager.close();
//             },
//           ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     AppColors.primary.withOpacity(0.1),
//                     AppColors.secondary.withOpacity(0.1),
//                   ],
//                 ),
//               ),
//               child: Center(
//                 child: Card(
//                   elevation: 8,
//                   margin: const EdgeInsets.all(32),
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 500),
//                     padding: const EdgeInsets.all(48),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.rocket_launch,
//                           size: 80,
//                           color: AppColors.primary,
//                         ),
//                         const SizedBox(height: 32),
//                         Text(
//                           'Starting Madira Kitchen',
//                           style: GoogleFonts.inter(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.secondary,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           backendService.statusMessage,
//                           style: GoogleFonts.inter(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 32),
//                         CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             AppColors.primary,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         Text(
//                           '🚀 Launching Django backend...',
//                           style: GoogleFonts.inter(
//                             color: AppColors.primary,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'This may take a few seconds',
//                           style: GoogleFonts.inter(
//                             color: Colors.grey[500],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================================
// // SCREEN WRAPPER - Adds title bar to all screens (NO RESET BUTTON)
// // ============================================================================
// class _ScreenWrapper extends StatelessWidget {
//   final Widget child;

//   const _ScreenWrapper({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<LoginProvider>(
//       builder: (context, loginProvider, _) {
//         final isLoggedIn = loginProvider.user != null;

//         return Scaffold(
//           backgroundColor: AppColors.background,
//           body: Column(
//             children: [
//               CustomTitleBar(
//                 title:
//                     isLoggedIn
//                         ? 'Madera Kitchen - ${loginProvider.user?.username ?? "Home"}'
//                         : 'Madera Kitchen - Login',
//                 showResetButton: false, // ← CHANGED: No reset button
//                 onClose: () async {
//                   final backendService = Provider.of<BackendService>(
//                     context,
//                     listen: false,
//                   );
//                   await backendService.stopBackend();
//                   await windowManager.close();
//                 },
//               ),
//               Expanded(child: SelectionArea(child: child)),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // ============================================================================
// // CUSTOM TITLE BAR WITH CONTROLS (SIMPLIFIED - NO RESET)
// // ============================================================================
// class CustomTitleBar extends StatelessWidget {
//   final String title;
//   final VoidCallback? onClose;
//   final bool showResetButton;

//   const CustomTitleBar({
//     Key? key,
//     required this.title,
//     this.onClose,
//     this.showResetButton = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onPanStart: (details) => windowManager.startDragging(),
//       child: Container(
//         height: 40,
//         decoration: BoxDecoration(
//           color: AppColors.secondary,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 16),
//             Icon(Icons.kitchen, size: 20, color: Colors.white.withOpacity(0.9)),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 title,
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.white,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             // Reset button removed - only minimize and close remain
//             _TitleBarButton(
//               icon: Icons.remove,
//               tooltip: 'Minimize',
//               onPressed: () => windowManager.minimize(),
//             ),
//             _TitleBarButton(
//               icon: Icons.close,
//               tooltip: 'Close',
//               isClose: true,
//               onPressed:
//                   onClose ??
//                   () async {
//                     final backendService = Provider.of<BackendService>(
//                       context,
//                       listen: false,
//                     );
//                     await backendService.stopBackend();
//                     await windowManager.close();
//                   },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TitleBarButton extends StatefulWidget {
//   final IconData icon;
//   final String tooltip;
//   final VoidCallback onPressed;
//   final bool isClose;

//   const _TitleBarButton({
//     required this.icon,
//     required this.tooltip,
//     required this.onPressed,
//     this.isClose = false,
//   });

//   @override
//   State<_TitleBarButton> createState() => _TitleBarButtonState();
// }

// class _TitleBarButtonState extends State<_TitleBarButton> {
//   bool _isHovered = false;

//   @override
//   Widget build(BuildContext context) {
//     return Tooltip(
//       message: widget.tooltip,
//       child: MouseRegion(
//         onEnter: (_) => setState(() => _isHovered = true),
//         onExit: (_) => setState(() => _isHovered = false),
//         child: GestureDetector(
//           onTap: widget.onPressed,
//           child: Container(
//             width: 46,
//             height: 40,
//             decoration: BoxDecoration(
//               color:
//                   _isHovered
//                       ? (widget.isClose
//                           ? Colors.red[600]
//                           : Colors.white.withOpacity(0.1))
//                       : Colors.transparent,
//             ),
//             child: Icon(widget.icon, size: 18, color: Colors.white),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================================================
// // BACKEND SETUP SCREEN
// // ============================================================================
// class BackendSetupScreen extends StatefulWidget {
//   const BackendSetupScreen({Key? key}) : super(key: key);

//   @override
//   State<BackendSetupScreen> createState() => _BackendSetupScreenState();
// }

// class _BackendSetupScreenState extends State<BackendSetupScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<BackendService>(
//       builder: (context, backendService, child) {
//         return Scaffold(
//           backgroundColor: AppColors.background,
//           body: Column(
//             children: [
//               CustomTitleBar(
//                 title: 'Madera Kitchen - Backend Setup',
//                 onClose: () async {
//                   await windowManager.close();
//                 },
//               ),
//               Expanded(
//                 child: Center(
//                   child: Card(
//                     elevation: 2,
//                     margin: const EdgeInsets.all(32),
//                     child: Container(
//                       constraints: const BoxConstraints(maxWidth: 600),
//                       padding: const EdgeInsets.all(48),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Icon(
//                             Icons.settings_applications,
//                             size: 64,
//                             color: AppColors.primary,
//                           ),
//                           const SizedBox(height: 24),
//                           Text(
//                             'Backend Configuration',
//                             textAlign: TextAlign.center,
//                             style: GoogleFonts.inter(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.secondary,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             'Select the Django backend folder containing manage.py',
//                             textAlign: TextAlign.center,
//                             style: GoogleFonts.inter(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           const SizedBox(height: 32),
//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: AppColors.primary.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                 color: AppColors.primary.withOpacity(0.3),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.info_outline,
//                                   size: 20,
//                                   color: AppColors.primary,
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Text(
//                                     'Example: F:\\madira\\backend\\madira',
//                                     style: GoogleFonts.inter(
//                                       fontSize: 13,
//                                       color: AppColors.secondary,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 24),
//                           if (backendService.backendPath != null)
//                             Container(
//                               padding: const EdgeInsets.all(16),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.green[300]!),
//                               ),
//                               child: Row(
//                                 children: [
//                                   const Icon(
//                                     Icons.check_circle,
//                                     color: Colors.green,
//                                     size: 20,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Text(
//                                       backendService.backendPath!,
//                                       style: GoogleFonts.inter(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                       maxLines: 2,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           if (backendService.backendPath != null)
//                             const SizedBox(height: 16),
//                           ElevatedButton.icon(
//                             onPressed:
//                                 backendService.isStarting
//                                     ? null
//                                     : () => backendService.selectBackendPath(
//                                       context,
//                                     ),
//                             icon: const Icon(Icons.folder_open),
//                             label: Text(
//                               backendService.backendPath == null
//                                   ? 'Select Backend Folder'
//                                   : 'Change Folder',
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           if (backendService.backendPath != null)
//                             ElevatedButton.icon(
//                               onPressed:
//                                   backendService.isStarting
//                                       ? null
//                                       : () => backendService.startBackend(),
//                               icon:
//                                   backendService.isStarting
//                                       ? const SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           valueColor:
//                                               AlwaysStoppedAnimation<Color>(
//                                                 Colors.white,
//                                               ),
//                                         ),
//                                       )
//                                       : const Icon(Icons.play_arrow),
//                               label: Text(
//                                 backendService.isStarting
//                                     ? 'Starting Backend...'
//                                     : 'Start Backend',
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 backgroundColor: Colors.green[600],
//                               ),
//                             ),
//                           if (backendService.errorMessage.isNotEmpty) ...[
//                             const SizedBox(height: 24),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.red[50],
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: Colors.red[300]!),
//                               ),
//                               child: Text(
//                                 backendService.errorMessage,
//                                 textAlign: TextAlign.center,
//                                 style: GoogleFonts.inter(
//                                   fontSize: 13,
//                                   color: Colors.red[900],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
// ===================================================================
// lib/main.dart - COMPLETE MASTER/SLAVE FLOW
// ===================================================================

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
import 'package:madira/ui/screens/home_screen.dart';
import 'package:madira/ui/screens/login_screen.dart';
import 'package:madira/ui/widgets/screen_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'core/constants/colors.dart';
import 'services/backend_service.dart';
import 'services/network_service.dart';
import 'ui/screens/mode_selection_screen.dart';
import 'ui/screens/backend_setup_screen.dart';
import 'ui/screens/master_waiting_screen.dart';
import 'ui/screens/slave_waiting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1920, 1080),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      fullScreen: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setMinimizable(true);
    });
  }

  runApp(const MaderaKitchenApp());
}

class MaderaKitchenApp extends StatefulWidget {
  const MaderaKitchenApp({Key? key}) : super(key: key);

  @override
  State<MaderaKitchenApp> createState() => _MaderaKitchenAppState();
}

class _MaderaKitchenAppState extends State<MaderaKitchenApp>
    with WindowListener {
  late BackendService _backendService;
  late NetworkService _networkService;

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
    super.dispose();
  }

  @override
  void onWindowClose() async {
    print('🚪 Application closing - cleaning up resources...');

    try {
      await _networkService.stop();
      await _backendService.stopBackend();
      print('✅ Cleanup completed');
    } catch (e) {
      print('⚠️ Error during cleanup: $e');
    }

    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
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
      ],
      child: MaterialApp(
        title: 'Madera Kitchen Fabrication',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AppInitializer(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
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
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

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

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        return const ModeSelectionScreen();
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
                          '🚀 Launching Django backend...',
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
