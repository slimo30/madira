// ===================================================================
// lib/ui/screens/backend_setup_screen.dart - FIXED
// ===================================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/ui/widgets/screen_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/constants/colors.dart';
import '../../services/backend_service.dart';
import '../../services/network_service.dart';
import 'master_waiting_screen.dart';
import 'mode_selection_screen.dart';

class BackendSetupScreen extends StatefulWidget {
  const BackendSetupScreen({super.key});

  @override
  State<BackendSetupScreen> createState() => _BackendSetupScreenState();
}

class _BackendSetupScreenState extends State<BackendSetupScreen> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<BackendService>(
      builder: (context, backendService, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              CustomTitleBar(
                title: 'Madera Kitchen - Backend Setup',
                onClose: () async {
                  await backendService.stopBackend();
                  await windowManager.close();
                },
                onReset: () async {
                  final networkService = Provider.of<NetworkService>(
                    context,
                    listen: false,
                  );
                  await backendService.resetConfiguration();
                  await networkService.resetMode();

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const ModeSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
              Expanded(
                child: Center(
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(32),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.settings_applications,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Backend Configuration',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select the Django backend folder containing manage.py',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Example: F:\\madira\\backend\\madira',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (backendService.backendPath != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      backendService.backendPath!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (backendService.backendPath != null)
                            const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                _isStarting
                                    ? null
                                    : () => backendService.selectBackendPath(
                                      context,
                                    ),
                            icon: const Icon(Icons.folder_open),
                            label: Text(
                              backendService.backendPath == null
                                  ? 'Select Backend Folder'
                                  : 'Change Folder',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // START BACKEND BUTTON (with navigation)
                          if (backendService.backendPath != null)
                            ElevatedButton.icon(
                              onPressed: _isStarting ? null : _startAndNavigate,
                              icon:
                                  _isStarting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Icon(Icons.play_arrow),
                              label: Text(
                                _isStarting
                                    ? 'Starting Backend...'
                                    : 'Start Backend',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.green[600],
                              ),
                            ),

                          if (backendService.errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: Text(
                                backendService.errorMessage,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startAndNavigate() async {
    setState(() {
      _isStarting = true;
    });

    try {
      final backendService = Provider.of<BackendService>(
        context,
        listen: false,
      );
      final networkService = Provider.of<NetworkService>(
        context,
        listen: false,
      );

      print(' Starting backend from BackendSetupScreen...');

      // Start backend
      final started = await backendService.startBackend();

      if (started) {
        print(' Backend started successfully');

        // Start broadcasting after backend is ready
        print(' Starting broadcasting...');
        await networkService.startBroadcastingAfterBackend();
        print(' Broadcasting started');

        if (mounted) {
          setState(() {
            _isStarting = false;
          });

          // Navigate to master waiting screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MasterWaitingScreen()),
          );
        }
      } else {
        throw Exception('Failed to start backend');
      }
    } catch (e) {
      print(' Failed to start backend: $e');

      if (mounted) {
        setState(() {
          _isStarting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to start backend: $e',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
