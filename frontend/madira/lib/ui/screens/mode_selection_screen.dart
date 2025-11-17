import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/app_mode_provider.dart';
import '../../core/constants/colors.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.settings_input_component,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Madira Kitchen - Configuration',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Select how you want to run this application',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Master Mode Card
                  _buildModeCard(
                    context: context,
                    icon: Icons.computer,
                    title: 'Master Mode',
                    description:
                        'Run as the main server with backend. '
                        'This device will host the database and serve other devices.',
                    color: AppColors.primary,
                    onTap: _isLoading ? null : () => _selectMasterMode(context),
                  ),

                  const SizedBox(height: 24),

                  // Slave Mode Card
                  _buildModeCard(
                    context: context,
                    icon: Icons.devices,
                    title: 'Slave Mode',
                    description:
                        'Connect to an existing master server. '
                        'Automatically discovers the master on your network.',
                    color: AppColors.secondary,
                    onTap: _isLoading ? null : () => _selectSlaveMode(context),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Configuring, please wait...',
                      style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMasterMode(BuildContext context) async {
    // Show file picker to select backend directory
    final result = await _showBackendPathDialog(context);

    if (result == null) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AppModeProvider>(context, listen: false);
      await provider.setMasterMode(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Master mode configured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigation will happen automatically via main.dart
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to configure master mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectSlaveMode(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AppModeProvider>(context, listen: false);
      await provider.setSlaveMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Slave mode configured! Listening for master...'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigation will happen automatically via main.dart
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to configure slave mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showBackendPathDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: '/Users/macbookair/Desktop/Madira/backend/madira',
    );

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Backend Directory'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the path to your Django backend directory\n(the folder containing manage.py)',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Backend Path',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final result =
                            await FilePicker.platform.getDirectoryPath();
                        if (result != null) {
                          controller.text = result;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context, controller.text);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }
}
