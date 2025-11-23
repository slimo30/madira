// ===================================================================
// lib/ui/screens/master_waiting_screen.dart - WITH CHANGE MODE BUTTON
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
import '../../main.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'mode_selection_screen.dart';

class MasterWaitingScreen extends StatelessWidget {
  const MasterWaitingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              CustomTitleBar(title: 'Madera Kitchen - Master Mode'),
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
                            Icons.broadcast_on_personal,
                            size: 80,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Master Mode Active',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi,
                                  size: 20,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Broadcasting: ${networkService.localIp ?? "N/A"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Connected Slaves',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child:
                                networkService.connectedSlaves.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.devices_other,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Waiting for slaves to connect...',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          networkService.connectedSlaves.length,
                                      itemBuilder: (context, index) {
                                        final slaveIp =
                                            networkService
                                                .connectedSlaves[index];
                                        return ListTile(
                                          leading: Icon(
                                            Icons.devices,
                                            color: Colors.blue[700],
                                          ),
                                          title: Text(
                                            slaveIp,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.check_circle,
                                            color: Colors.green[600],
                                          ),
                                        );
                                      },
                                    ),
                          ),
                          const SizedBox(height: 32),

                          // START BUTTON
                          ElevatedButton.icon(
                            onPressed: () => _confirmAndStart(context),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              networkService.connectedSlaves.isEmpty
                                  ? 'Start Without Slaves'
                                  : 'Confirm & Start (${networkService.connectedSlaves.length} slaves)',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              backgroundColor: Colors.green[600],
                            ),
                          ),

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
                  'Do you want to switch from Master to Slave mode?',
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
                      _buildInfoItem('• Backend server will stop'),
                      _buildInfoItem('• Broadcasting will stop'),
                      _buildInfoItem('• All connected slaves will disconnect'),
                      _buildInfoItem('• You\'ll need to select mode again'),
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
                  const SizedBox(height: 8),
                  Text(
                    'Stopping backend and network services',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
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
      final backendService = Provider.of<BackendService>(
        context,
        listen: false,
      );

      print('🔄 Stopping backend and network services...');

      // Stop backend and network in parallel
      await Future.wait([
        backendService.stopBackend(),
        networkService.resetMode(),
      ]);

      print('✅ Services stopped - returning to mode selection');

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
      print('❌ Error changing mode: $e');

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

  void _confirmAndStart(BuildContext context) {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    networkService.confirmAndStart();

    // Master always uses localhost
    DioClient().resetToLocalhost();
    print('✅ Master using localhost: ${DioClient().getBaseUrl()}');

    final isLoggedIn = loginProvider.user != null;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
