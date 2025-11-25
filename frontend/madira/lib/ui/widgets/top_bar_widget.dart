import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/constants/colors.dart';
import '../../providers/login_provider.dart';
import '../../services/network_service.dart';
import '../../services/backend_service.dart';
import '../screens/mode_selection_screen.dart';

class TopBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const TopBarWidget({super.key, required this.title});

  @override
  _TopBarWidgetState createState() => _TopBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(104); // 40 (title bar) + 64 (top bar)
}

class _TopBarWidgetState extends State<TopBarWidget> {
  bool _showTitleBar = false;

  void _onEnter(PointerEvent _) => setState(() => _showTitleBar = true);
  void _onExit(PointerEvent _) => setState(() => _showTitleBar = false);

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final networkService = Provider.of<NetworkService>(context);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom Title Bar - shows/hides on hover
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showTitleBar ? 40 : 0,
            child:
                _showTitleBar
                    ? _CustomTitleBar(title: widget.title)
                    : const SizedBox.shrink(),
          ),

          // Main Top Bar - always visible
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Logo and Company Name
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MADERA',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 40),

                    // Centered Page Title
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 40),

                    // Network Status Badge
                    _buildNetworkStatusBadge(networkService),

                    const SizedBox(width: 16),

                    // Settings Menu
                    _buildSettingsMenu(context, networkService, loginProvider),

                    const SizedBox(width: 16),

                    // User Profile Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.surfaceVariant,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                loginProvider.user?.username
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loginProvider.user?.username ?? 'User',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  (loginProvider.user?.role ?? 'user')
                                      .toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusBadge(NetworkService networkService) {
    IconData icon;
    Color color;
    String tooltip;
    String label;

    switch (networkService.mode) {
      case DeviceMode.master:
        icon = Icons.computer;
        color = Colors.green;
        label = 'MASTER';
        tooltip =
            'Master Mode\nIP: ${networkService.localIp ?? "N/A"}\nSlaves: ${networkService.connectedSlaves.length}';
        break;
      case DeviceMode.slave:
        icon = Icons.devices;
        color = Colors.blue;
        label = 'SLAVE';
        tooltip =
            'Slave Mode\nConnected to: ${networkService.masterIp ?? "Discovering..."}';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        label = 'N/A';
        tooltip = 'Not Configured';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(
    BuildContext context,
    NetworkService networkService,
    LoginProvider loginProvider,
  ) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Icon(Icons.settings, size: 20, color: AppColors.textPrimary),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        networkService.mode == DeviceMode.master
                            ? Icons.computer
                            : Icons.devices,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Network Configuration',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Mode:',
                    networkService.mode
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                  ),
                  if (networkService.localIp != null)
                    _buildInfoRow('Local IP:', networkService.localIp!),
                  if (networkService.mode == DeviceMode.master)
                    _buildInfoRow(
                      'Slaves:',
                      '${networkService.connectedSlaves.length} connected',
                    ),
                  if (networkService.mode == DeviceMode.slave &&
                      networkService.masterIp != null)
                    _buildInfoRow('Master:', networkService.masterIp!),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Text(
                    'Reset Configuration',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
      onSelected: (String value) async {
        if (value == 'reset') {
          _showResetConfirmationDialog(context, networkService);
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(
    BuildContext context,
    NetworkService networkService,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 28,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 12),
                Text(
                  'Reset Configuration',
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
                  'This will reset your entire configuration:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
                      _buildWarningItem('• Network mode will be cleared'),
                      _buildWarningItem('• Backend path will be removed'),
                      _buildWarningItem(
                        '• Backend server will stop (if Master)',
                      ),
                      _buildWarningItem('• All network connections will close'),
                      _buildWarningItem(
                        '• You\'ll need to reconfigure on restart',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to continue?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performReset(context, networkService);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
      ),
    );
  }

  Future<void> _performReset(
    BuildContext context,
    NetworkService networkService,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

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
                    'Resetting configuration...',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait',
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
      final backendService = Provider.of<BackendService>(
        context,
        listen: false,
      );
      print('🔄 Starting reset process...');
      await Future.wait([
        backendService.resetConfiguration(),
        networkService.resetMode(),
      ]);
      print('✅ All configurations reset');
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Configuration reset! Redirecting...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(milliseconds: 800),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      print('🔄 Navigating to ModeSelectionScreen...');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
        (route) => false,
      );
      print('✅ Navigation complete');
    } catch (e) {
      print('❌ Reset error: $e');
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Failed to reset: $e', style: GoogleFonts.inter()),
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

// Custom Title Bar that appears on hover
class _CustomTitleBar extends StatelessWidget {
  final String title;

  const _CustomTitleBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => windowManager.startDragging(),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TitleBarButton(
              icon: Icons.remove,
              tooltip: 'Minimize',
              onPressed: () => windowManager.minimize(),
            ),
            _TitleBarButton(
              icon: Icons.close,
              tooltip: 'Close',
              isClose: true,
              onPressed: () async {
                final networkService = Provider.of<NetworkService>(
                  context,
                  listen: false,
                );
                final backendService = Provider.of<BackendService>(
                  context,
                  listen: false,
                );
                await networkService.stop();
                await backendService.stopBackend();
                await windowManager.close();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _TitleBarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              color:
                  _isHovered
                      ? (widget.isClose
                          ? Colors.red[600]
                          : Colors.white.withOpacity(0.1))
                      : Colors.transparent,
            ),
            child: Icon(widget.icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
