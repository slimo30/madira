// ===================================================================
// lib/ui/screens/mode_selection_screen.dart - WITH LOADING & BACKEND
// ===================================================================
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/ui/widgets/screen_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../services/network_service.dart';
import '../../services/backend_service.dart';
import 'backend_setup_screen.dart';
import 'master_waiting_screen.dart';
import 'slave_waiting_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenWrapper(
        title: 'Device Mode',
        child: Stack(
          children: [
            Center(
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.device_hub,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Device Mode',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose how this device will operate',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.computer,
                              title: 'Master',
                              description:
                                  'Run backend server and manage slave devices',
                              color: AppColors.primary,
                              onTap:
                                  _isProcessing
                                      ? null
                                      : () => _selectMasterMode(context),
                              isEnabled: !_isProcessing,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.devices,
                              title: 'Slave',
                              description:
                                  'Connect to master device on local network',
                              color: Colors.blue[700]!,
                              onTap:
                                  _isProcessing
                                      ? null
                                      : () => _selectSlaveMode(context),
                              isEnabled: !_isProcessing,
                            ),
                          ),
                        ],
                      ),
                      if (_isProcessing) ...[
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
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _statusMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Full-screen loading overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const SizedBox.expand(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMasterMode(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Setting up Master mode...';
    });

    try {
      final networkService = Provider.of<NetworkService>(
        context,
        listen: false,
      );
      final backendService = Provider.of<BackendService>(
        context,
        listen: false,
      );

      // Initialize network
      await networkService.initialize();
      print('✅ Network initialized');

      // Set master mode
      await networkService.setMasterMode();
      print('✅ Master mode set');

      // Check if backend path is configured
      setState(() {
        _statusMessage = 'Checking backend configuration...';
      });

      final prefs = await SharedPreferences.getInstance();
      final backendPath = prefs.getString('backend_path');

      if (backendPath == null || !await Directory(backendPath).exists()) {
        // Navigate to backend setup
        print('⚠️ Backend not configured - showing setup screen');

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BackendSetupScreen()),
          );
        }
        return;
      }

      // Backend path exists - start backend
      setState(() {
        _statusMessage = 'Starting Django backend...';
      });

      print('🚀 Starting backend from path: $backendPath');
      final started = await backendService.startBackend();

      if (started) {
        print('✅ Backend started successfully');

        // Start broadcasting after backend is ready
        setState(() {
          _statusMessage = 'Starting network broadcasting...';
        });

        await networkService.startBroadcastingAfterBackend();
        print('✅ Broadcasting started');

        if (mounted) {
          setState(() {
            _isProcessing = false;
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
      print('❌ Master mode setup failed: $e');

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to setup Master mode: $e',
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

  Future<void> _selectSlaveMode(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Setting up Slave mode...';
    });

    try {
      final networkService = Provider.of<NetworkService>(
        context,
        listen: false,
      );

      // Initialize network
      await networkService.initialize();
      print('✅ Network initialized');

      // Set slave mode (this starts listening)
      setState(() {
        _statusMessage = 'Connecting to network...';
      });

      await networkService.setSlaveMode();
      print('✅ Slave mode set - listening for master');

      // Small delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Navigate to slave waiting screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SlaveWaitingScreen()),
        );
      }
    } catch (e) {
      print('❌ Slave mode setup failed: $e');

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to setup Slave mode: $e',
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

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter:
          widget.isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit:
          widget.isEnabled ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color:
                  _isHovered && widget.isEnabled
                      ? widget.color.withOpacity(0.05)
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isHovered && widget.isEnabled
                        ? widget.color
                        : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(widget.icon, size: 64, color: widget.color),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
