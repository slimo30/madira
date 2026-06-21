// ===================================================================
// lib/ui/screens/slave_waiting_screen.dart - WITH CHANGE MODE BUTTON
// ===================================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/core/network/dio_client.dart';
import 'package:madira/ui/widgets/screen_wrapper.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../services/network_service.dart';
import '../../services/backend_service.dart';
import '../../providers/login_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'mode_selection_screen.dart';

class SlaveWaitingScreen extends StatelessWidget {
  const SlaveWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        final hasMaster = networkService.masterIp != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              CustomTitleBar(
                title: 'Madera Kitchen - Slave Mode',
                onReset: () async {
                  final backendService = Provider.of<BackendService>(
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
                        children: [
                          Icon(
                            hasMaster ? Icons.link : Icons.search,
                            size: 80,
                            color:
                                hasMaster
                                    ? Colors.green[600]
                                    : AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            hasMaster
                                ? 'Master Found!'
                                : 'Searching for Master...',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!hasMaster) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Listening for master broadcasts on local network',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // HELP TEXT
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Make sure a Master device is running on the same network',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.computer,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Master IP: ${networkService.masterIp}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // CONNECT BUTTON
                            ElevatedButton.icon(
                              onPressed: () => _connectToMaster(context),
                              icon: const Icon(Icons.login),
                              label: const Text('Connect to Master'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.green[600],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // DIVIDER
                          Divider(color: Colors.grey[300], thickness: 1),

                          const SizedBox(height: 16),

                          // CHANGE MODE BUTTON
                          OutlinedButton.icon(
                            onPressed: () => _showChangeModeDialog(context),
                            icon: Icon(
                              Icons.swap_horiz,
                              size: 18,
                              color: Colors.orange[700],
                            ),
                            label: Text(
                              'Change Mode',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              side: BorderSide(
                                color: Colors.orange[700]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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

  void _showChangeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.orange[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Change Device Mode',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Do you want to switch from Slave to Master mode?',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(
                        '• Current network connections will close',
                      ),
                      _buildInfoItem(
                        '• You\'ll need to select Master or Slave again',
                      ),
                      _buildInfoItem(
                        '• Master mode requires backend configuration',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close dialog
                  await _changeMode(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Change Mode',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
      ),
    );
  }

  Future<void> _changeMode(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Switching mode...',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      final networkService = Provider.of<NetworkService>(
        context,
        listen: false,
      );

      // Reset network configuration
      await networkService.resetMode();
      print(' Mode reset - returning to selection');

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Navigate to mode selection
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ModeSelectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print(' Error changing mode: $e');

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to change mode: $e',
                    style: GoogleFonts.inter(),
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

  Future<void> _connectToMaster(BuildContext context) async {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    // Connect to master (sends ACK message)
    await networkService.connectToMaster();

    // Update API base URL to master's IP
    final masterUrl = 'http://${networkService.masterIp}:8000';
    DioClient().updateBaseUrl(masterUrl);

    print(' API requests will now go to: $masterUrl/api');

    if (context.mounted) {
      final isLoggedIn = loginProvider.user != null;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }
}
