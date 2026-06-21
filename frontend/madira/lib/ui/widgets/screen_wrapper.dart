import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:madira/core/constants/colors.dart';
import 'package:window_manager/window_manager.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showTitle;
  final VoidCallback? onClose;
  final VoidCallback? onReset;

  const ScreenWrapper({
    super.key,
    required this.child,
    required this.title,
    this.showTitle = true,
    this.onClose,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTitleBar(
          title: title,
          showTitle: showTitle,
          onClose: onClose,
          onReset: onReset,
        ),
        Expanded(child: child),
      ],
    );
  }
}

class CustomTitleBar extends StatelessWidget {
  final String title;
  final bool showTitle;
  final VoidCallback? onClose;
  final VoidCallback? onReset;

  const CustomTitleBar({
    super.key,
    required this.title,
    this.showTitle = true,
    this.onClose,
    this.onReset,
  });

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

            // White recolored logo image
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/logo.png', // Your logo asset path
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 12),

            if (showTitle)
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
              )
            else
              const Spacer(),

            if (onReset != null)
              _TitleBarButton(
                icon: Icons.refresh,
                tooltip: 'Reset Configuration',
                onPressed: onReset!,
              ),

            _SmartWindowButton(),
            _TitleBarButton(
              icon: Icons.remove,
              tooltip: 'Minimize',
              onPressed: () => windowManager.minimize(),
            ),
            _TitleBarButton(
              icon: Icons.close,
              tooltip: 'Close',
              isClose: true,
              onPressed:
                  onClose ??
                  () async {
                    // final networkService = Provider.of<NetworkService>(
                    //   context,
                    //   listen: false,
                    // );
                    // final backendService = Provider.of<BackendService>(
                    //   context,
                    //   listen: false,
                    // );
                    // await networkService.stop();
                    // await backendService.stopBackend();
                    await windowManager.close();
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartWindowButton extends StatefulWidget {
  const _SmartWindowButton();

  @override
  State<_SmartWindowButton> createState() => _SmartWindowButtonState();
}

class _SmartWindowButtonState extends State<_SmartWindowButton>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkWindowState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkWindowState() async {
    final isMax = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = isMax);
    }
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'maximize' || eventName == 'unmaximize') {
      _checkWindowState();
    }
  }

  @override
  void onWindowMaximize() {
    _checkWindowState();
  }

  @override
  void onWindowUnmaximize() {
    _checkWindowState();
  }

  @override
  Widget build(BuildContext context) {
    return _TitleBarButton(
      icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
      tooltip: _isMaximized ? 'Restore' : 'Maximize',
      onPressed: () async {
        if (_isMaximized) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
        _checkWindowState();
      },
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
