// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../utils/performance_monitor.dart';

// /// Debug overlay widget to display performance metrics in real-time
// class PerformanceDebugOverlay extends StatefulWidget {
//   final Widget child;
//   final bool enabled;

//   const PerformanceDebugOverlay({
//     super.key,
//     required this.child,
//     this.enabled = true,
//   });

//   @override
//   State<PerformanceDebugOverlay> createState() =>
//       _PerformanceDebugOverlayState();
// }

// class _PerformanceDebugOverlayState extends State<PerformanceDebugOverlay> {
//   final _monitor = PerformanceMonitor();
//   bool _isExpanded = false;
//   bool _isDragging = false;
//   Offset _position = const Offset(20, 100);

//   @override
//   void initState() {
//     super.initState();
//     if (widget.enabled) {
//       _monitor.startMonitoring();
//     }
//   }

//   @override
//   void dispose() {
//     if (widget.enabled) {
//       _monitor.stopMonitoring();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.enabled) {
//       return widget.child;
//     }

//     return Stack(
//       children: [
//         widget.child,
//         Positioned(
//           left: _position.dx,
//           top: _position.dy,
//           child: GestureDetector(
//             onPanUpdate: (details) {
//               setState(() {
//                 _position = Offset(
//                   (_position.dx + details.delta.dx).clamp(
//                     0,
//                     MediaQuery.of(context).size.width - 300,
//                   ),
//                   (_position.dy + details.delta.dy).clamp(
//                     0,
//                     MediaQuery.of(context).size.height - 400,
//                   ),
//                 );
//               });
//             },
//             child: Material(
//               elevation: 8,
//               borderRadius: BorderRadius.circular(12),
//               color: Colors.black.withOpacity(0.85),
//               child: Container(
//                 width: _isExpanded ? 300 : 120,
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Header
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Flexible(
//                           child: Text(
//                             _isExpanded ? '📊 Performance' : '📊',
//                             style: GoogleFonts.inter(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             GestureDetector(
//                               onTap:
//                                   () => setState(
//                                     () => _isExpanded = !_isExpanded,
//                                   ),
//                               child: Icon(
//                                 _isExpanded ? Icons.compress : Icons.expand,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             GestureDetector(
//                               onTap: () {
//                                 _monitor.printReport();
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       'Performance report printed to console',
//                                     ),
//                                     duration: Duration(seconds: 2),
//                                   ),
//                                 );
//                               },
//                               child: const Icon(
//                                 Icons.print,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     const Divider(color: Colors.white30, height: 1),
//                     const SizedBox(height: 8),

//                     // Metrics
//                     _buildMetric(
//                       '🎬 FPS',
//                       _monitor.averageFps.toStringAsFixed(1),
//                       _getFpsColor(_monitor.averageFps),
//                     ),

//                     if (_isExpanded) ...[
//                       const SizedBox(height: 8),
//                       _buildMetric(
//                         '📦 Frames',
//                         _monitor.getSummary().frameCount.toString(),
//                         Colors.white70,
//                       ),
//                       const SizedBox(height: 8),
//                       _buildMetric(
//                         '⚠️ Slow Frames',
//                         _monitor.getSummary().slowFrameCount.toString(),
//                         Colors.orange,
//                       ),
//                       const SizedBox(height: 8),
//                       _buildMetric(
//                         '🌐 API Calls',
//                         _monitor.getSummary().apiCallCount.toString(),
//                         Colors.white70,
//                       ),
//                       const SizedBox(height: 8),
//                       _buildMetric(
//                         '⏱️ Avg API',
//                         '${_monitor.getSummary().averageApiDuration.toStringAsFixed(0)}ms',
//                         _getApiColor(_monitor.getSummary().averageApiDuration),
//                       ),
//                       const SizedBox(height: 12),

//                       // Action buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildButton('Reset', Icons.refresh, () {
//                               _monitor.reset();
//                               setState(() {});
//                             }),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: _buildButton(
//                               'Report',
//                               Icons.assessment,
//                               () => _monitor.printReport(),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMetric(String label, String value, Color color) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
//         ),
//         Text(
//           value,
//           style: GoogleFonts.inter(
//             color: color,
//             fontSize: 11,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildButton(String label, IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(6),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white70, size: 12),
//             const SizedBox(width: 4),
//             Text(
//               label,
//               style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getFpsColor(double fps) {
//     if (fps >= 55) return Colors.green;
//     if (fps >= 30) return Colors.orange;
//     return Colors.red;
//   }

//   Color _getApiColor(double ms) {
//     if (ms <= 200) return Colors.green;
//     if (ms <= 500) return Colors.orange;
//     return Colors.red;
//   }
// }
