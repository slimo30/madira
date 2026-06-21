import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService reportService = ReportService();

  bool _isEstimating = false;
  bool _isDownloading = false;
  String? _error;

  Map<String, dynamic>? _estimateData;

  // Filters
  String _reportType = 'monthly'; // daily, weekly, monthly, all
  String? _startDate; // ISO
  String? _endDate;
  String? _clientId;
  String? _orderId;
  String? _supplierId;
  String? _productId;
  String? _status;
  bool _includeRelations = true;

  bool get isEstimating => _isEstimating;
  bool get isDownloading => _isDownloading;
  String? get error => _error;
  Map<String, dynamic>? get estimateData => _estimateData;

  String get reportType => _reportType;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get clientId => _clientId;
  String? get orderId => _orderId;
  String? get supplierId => _supplierId;
  String? get productId => _productId;
  String? get status => _status;
  bool get includeRelations => _includeRelations;

  // Estimate fields helpers
  double get totalSeconds =>
      (estimateData?['time_estimate']?['total_seconds'] ?? 0.0).toDouble();
  String get readable => estimateData?['time_estimate']?['readable'] ?? '';
  String get rangeReadable =>
      estimateData?['time_estimate']?['range_readable'] ?? '';
  Map<String, dynamic>? get breakdown =>
      estimateData?['time_estimate']?['breakdown'];
  String get recommendation => estimateData?['recommendation'] ?? '';
  String get message => estimateData?['message'] ?? '';

  void setReportType(String type) {
    if (_reportType != type) {
      _reportType = type;
      notifyListeners();
    }
  }

  void setDateRange({String? start, String? end}) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setClientId(String? id) {
    _clientId = id;
    notifyListeners();
  }

  void setOrderId(String? id) {
    _orderId = id;
    notifyListeners();
  }

  void setSupplierId(String? id) {
    _supplierId = id;
    notifyListeners();
  }

  void setProductId(String? id) {
    _productId = id;
    notifyListeners();
  }

  void setStatus(String? value) {
    _status = value;
    notifyListeners();
  }

  void setIncludeRelations(bool value) {
    _includeRelations = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchEstimate() async {
    _isEstimating = true;
    _error = null;
    notifyListeners();

    try {
      final data = await reportService.getEstimate(
        type: _reportType,
        startDate: _startDate,
        endDate: _endDate,
        clientId: _clientId,
        orderId: _orderId,
        supplierId: _supplierId,
        productId: _productId,
        status: _status,
        includeRelations: _includeRelations,
      );
      _estimateData = data;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _estimateData = null;
    } finally {
      _isEstimating = false;
      notifyListeners();
    }
  }

  Future<Response<dynamic>> downloadReportWithBytes({
    ProgressCallback? onReceiveProgress,
  }) async {
    _isDownloading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await reportService.downloadReport(
        type: _reportType,
        startDate: _startDate,
        endDate: _endDate,
        clientId: _clientId,
        orderId: _orderId,
        supplierId: _supplierId,
        productId: _productId,
        status: _status,
        includeRelations: _includeRelations,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
