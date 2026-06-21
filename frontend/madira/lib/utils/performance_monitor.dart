// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';

// /// Performance monitoring utility for tracking app performance metrics
// class PerformanceMonitor {
//   static final PerformanceMonitor _instance = PerformanceMonitor._internal();
//   factory PerformanceMonitor() => _instance;
//   PerformanceMonitor._internal();

//   // Performance metrics
//   final List<double> _frameTimes = [];
//   final List<MemorySnapshot> _memorySnapshots = [];
//   final Map<String, ApiCallMetrics> _apiMetrics = {};
//   final Map<String, BuildMetrics> _buildMetrics = {};

//   int _frameCount = 0;
//   double _totalFrameTime = 0;
//   DateTime? _lastFrameTime;
//   bool _isMonitoring = false;

//   Timer? _memoryTimer;

//   // Getters for metrics
//   double get averageFps =>
//       _frameCount > 0 ? 1000 / (_totalFrameTime / _frameCount) : 0;
//   double get currentFps =>
//       _lastFrameTime != null
//           ? 1000 / DateTime.now().difference(_lastFrameTime!).inMilliseconds
//           : 0;

//   List<double> get recentFrameTimes =>
//       _frameTimes.length > 100
//           ? _frameTimes.sublist(_frameTimes.length - 100)
//           : _frameTimes;

//   MemorySnapshot? get latestMemory =>
//       _memorySnapshots.isNotEmpty ? _memorySnapshots.last : null;

//   Map<String, ApiCallMetrics> get apiMetrics => Map.unmodifiable(_apiMetrics);
//   Map<String, BuildMetrics> get buildMetrics => Map.unmodifiable(_buildMetrics);

//   /// Start monitoring performance
//   void startMonitoring() {
//     if (_isMonitoring) return;
//     _isMonitoring = true;

//     debugPrint('🔍 Performance monitoring started');

//     // Monitor frame rendering
//     SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

//     // Monitor memory periodically
//     _memoryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       _captureMemorySnapshot();
//     });

//     // Initial memory snapshot
//     _captureMemorySnapshot();
//   }

//   /// Stop monitoring
//   void stopMonitoring() {
//     if (!_isMonitoring) return;
//     _isMonitoring = false;

//     SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);
//     _memoryTimer?.cancel();
//     _memoryTimer = null;

//     debugPrint('🛑 Performance monitoring stopped');
//   }

//   void _onFrameTiming(List<FrameTiming> timings) {
//     for (final timing in timings) {
//       final frameTime = timing.totalSpan.inMilliseconds.toDouble();
//       _frameTimes.add(frameTime);
//       _totalFrameTime += frameTime;
//       _frameCount++;
//       _lastFrameTime = DateTime.now();

//       // Keep only last 1000 frame times
//       if (_frameTimes.length > 1000) {
//         _frameTimes.removeAt(0);
//       }

//       // Log slow frames
//       if (frameTime > 16.67) {
//         // > 60 FPS
//         debugPrint('⚠️ Slow frame detected: ${frameTime.toStringAsFixed(2)}ms');
//       }
//     }
//   }

//   void _captureMemorySnapshot() {
//     // Note: This is a simplified version. For more detailed memory info,
//     // you'd need platform-specific code or use DevTools
//     final snapshot = MemorySnapshot(
//       timestamp: DateTime.now(),
//       rss: 0, // Would need platform channel for actual RSS
//       heapUsage: 0, // Would need platform channel
//     );

//     _memorySnapshots.add(snapshot);

//     // Keep only last 100 snapshots
//     if (_memorySnapshots.length > 100) {
//       _memorySnapshots.removeAt(0);
//     }
//   }

//   /// Track API call performance
//   void trackApiCall(
//     String endpoint, {
//     required Duration duration,
//     required int statusCode,
//     required bool success,
//   }) {
//     final key = endpoint;
//     final existing = _apiMetrics[key] ?? ApiCallMetrics(endpoint: endpoint);

//     existing.addCall(
//       duration: duration,
//       statusCode: statusCode,
//       success: success,
//     );

//     _apiMetrics[key] = existing;

//     // Log slow API calls
//     if (duration.inMilliseconds > 1000) {
//       debugPrint(
//         '🐌 Slow API call: $endpoint took ${duration.inMilliseconds}ms',
//       );
//     }
//   }

//   /// Track widget build performance
//   void trackBuild(String widgetName, Duration duration) {
//     final existing =
//         _buildMetrics[widgetName] ?? BuildMetrics(widgetName: widgetName);
//     existing.addBuild(duration);
//     _buildMetrics[widgetName] = existing;

//     // Log slow builds
//     if (duration.inMilliseconds > 16) {
//       debugPrint(
//         '🐌 Slow build: $widgetName took ${duration.inMilliseconds}ms',
//       );
//     }
//   }

//   /// Get performance summary
//   PerformanceSummary getSummary() {
//     return PerformanceSummary(
//       averageFps: averageFps,
//       frameCount: _frameCount,
//       slowFrameCount: _frameTimes.where((t) => t > 16.67).length,
//       apiCallCount: _apiMetrics.values.fold(0, (sum, m) => sum + m.callCount),
//       averageApiDuration: _calculateAverageApiDuration(),
//       buildMetrics: _buildMetrics,
//       memorySnapshots: _memorySnapshots,
//     );
//   }

//   double _calculateAverageApiDuration() {
//     if (_apiMetrics.isEmpty) return 0;
//     final total = _apiMetrics.values.fold<double>(
//       0,
//       (sum, m) => sum + m.averageDuration.inMilliseconds,
//     );
//     return total / _apiMetrics.length;
//   }

//   /// Reset all metrics
//   void reset() {
//     _frameTimes.clear();
//     _memorySnapshots.clear();
//     _apiMetrics.clear();
//     _buildMetrics.clear();
//     _frameCount = 0;
//     _totalFrameTime = 0;
//     _lastFrameTime = null;

//     debugPrint('🔄 Performance metrics reset');
//   }

//   /// Print detailed performance report
//   void printReport() {
//     final summary = getSummary();

//     debugPrint('\n' + '=' * 60);
//     debugPrint('📊 PERFORMANCE REPORT');
//     debugPrint('=' * 60);

//     debugPrint('\n🎬 Frame Performance:');
//     debugPrint('  Average FPS: ${summary.averageFps.toStringAsFixed(2)}');
//     debugPrint('  Total Frames: ${summary.frameCount}');
//     debugPrint('  Slow Frames (>16.67ms): ${summary.slowFrameCount}');
//     debugPrint(
//       '  Slow Frame %: ${((summary.slowFrameCount / summary.frameCount) * 100).toStringAsFixed(2)}%',
//     );

//     debugPrint('\n🌐 API Performance:');
//     debugPrint('  Total API Calls: ${summary.apiCallCount}');
//     debugPrint(
//       '  Average Duration: ${summary.averageApiDuration.toStringAsFixed(2)}ms',
//     );

//     if (_apiMetrics.isNotEmpty) {
//       debugPrint('\n  Top 5 Slowest APIs:');
//       final sorted =
//           _apiMetrics.values.toList()
//             ..sort((a, b) => b.averageDuration.compareTo(a.averageDuration));

//       for (var i = 0; i < sorted.length && i < 5; i++) {
//         final metric = sorted[i];
//         debugPrint('    ${i + 1}. ${metric.endpoint}');
//         debugPrint(
//           '       Avg: ${metric.averageDuration.inMilliseconds}ms, '
//           'Calls: ${metric.callCount}, '
//           'Success: ${(metric.successRate * 100).toStringAsFixed(1)}%',
//         );
//       }
//     }

//     debugPrint('\n🏗️ Build Performance:');
//     if (_buildMetrics.isNotEmpty) {
//       debugPrint('  Top 5 Slowest Builds:');
//       final sorted =
//           _buildMetrics.values.toList()
//             ..sort((a, b) => b.averageDuration.compareTo(a.averageDuration));

//       for (var i = 0; i < sorted.length && i < 5; i++) {
//         final metric = sorted[i];
//         debugPrint('    ${i + 1}. ${metric.widgetName}');
//         debugPrint(
//           '       Avg: ${metric.averageDuration.inMilliseconds.toStringAsFixed(2)}ms, '
//           'Builds: ${metric.buildCount}',
//         );
//       }
//     } else {
//       debugPrint('  No build metrics tracked yet');
//     }

//     debugPrint('\n💾 Memory:');
//     if (latestMemory != null) {
//       debugPrint('  Latest snapshot: ${latestMemory!.timestamp}');
//       debugPrint('  (Enable platform channels for detailed memory stats)');
//     }

//     debugPrint('\n' + '=' * 60 + '\n');
//   }
// }

// /// Memory snapshot data
// class MemorySnapshot {
//   final DateTime timestamp;
//   final int rss; // Resident Set Size
//   final int heapUsage;

//   MemorySnapshot({
//     required this.timestamp,
//     required this.rss,
//     required this.heapUsage,
//   });
// }

// /// API call metrics
// class ApiCallMetrics {
//   final String endpoint;
//   final List<Duration> _durations = [];
//   final List<int> _statusCodes = [];
//   int _successCount = 0;

//   ApiCallMetrics({required this.endpoint});

//   void addCall({
//     required Duration duration,
//     required int statusCode,
//     required bool success,
//   }) {
//     _durations.add(duration);
//     _statusCodes.add(statusCode);
//     if (success) _successCount++;
//   }

//   int get callCount => _durations.length;

//   Duration get averageDuration {
//     if (_durations.isEmpty) return Duration.zero;
//     final total = _durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
//     return Duration(milliseconds: total ~/ _durations.length);
//   }

//   double get successRate => callCount > 0 ? _successCount / callCount : 0;
// }

// /// Widget build metrics
// class BuildMetrics {
//   final String widgetName;
//   final List<Duration> _buildDurations = [];

//   BuildMetrics({required this.widgetName});

//   void addBuild(Duration duration) {
//     _buildDurations.add(duration);
//   }

//   int get buildCount => _buildDurations.length;

//   Duration get averageDuration {
//     if (_buildDurations.isEmpty) return Duration.zero;
//     final total = _buildDurations.fold<int>(
//       0,
//       (sum, d) => sum + d.inMilliseconds,
//     );
//     return Duration(milliseconds: total ~/ _buildDurations.length);
//   }
// }

// /// Performance summary
// class PerformanceSummary {
//   final double averageFps;
//   final int frameCount;
//   final int slowFrameCount;
//   final int apiCallCount;
//   final double averageApiDuration;
//   final Map<String, BuildMetrics> buildMetrics;
//   final List<MemorySnapshot> memorySnapshots;

//   PerformanceSummary({
//     required this.averageFps,
//     required this.frameCount,
//     required this.slowFrameCount,
//     required this.apiCallCount,
//     required this.averageApiDuration,
//     required this.buildMetrics,
//     required this.memorySnapshots,
//   });
// }

// /// Mixin for tracking widget build performance
// mixin PerformanceTracking<T extends StatefulWidget> on State<T> {
//   @override
//   Widget build(BuildContext context) {
//     final stopwatch = Stopwatch()..start();
//     final result = buildWithTracking(context);
//     stopwatch.stop();

//     if (kDebugMode) {
//       PerformanceMonitor().trackBuild(
//         widget.runtimeType.toString(),
//         stopwatch.elapsed,
//       );
//     }

//     return result;
//   }

//   Widget buildWithTracking(BuildContext context);
// }
