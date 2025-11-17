import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../services/auth_service.dart';
import '../core/storage/storage_service.dart';

class LoginProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  LoginModel? _user;
  bool _isLoading = false;

  LoginModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> login(String username, String password) async {
    print('🔐 LoginProvider: Starting login process...');
    print('🔐 Username: $username');

    _isLoading = true;
    notifyListeners();
    print('🔐 LoginProvider: Set loading to true, notified listeners');

    try {
      print('🔐 LoginProvider: Calling AuthService.login()');
      _user = await _authService.login(username, password);
      print('🔐 LoginProvider: Login successful! User data received:');
      print('🔐 User: $_user');
    } catch (e) {
      print('❌ LoginProvider: Login failed with error: $e');

      // Extract user-friendly message from the exception
      String userMessage = _extractUserMessage(e);
      throw Exception(userMessage);
    } finally {
      _isLoading = false;
      print('🔐 LoginProvider: Set loading to false');
      notifyListeners();
      print('🔐 LoginProvider: Final notification sent to listeners');
      print(
        '🔐 LoginProvider: Current user state: ${_user != null ? 'LOGGED IN' : 'NOT LOGGED IN'}',
      );
    }
  }

  Future<void> logout() async {
    print('🚪 LoginProvider: Starting logout process...');
    try {
      await _authService.logout();
      _user = null;
      print('🚪 LoginProvider: User set to null, notifying listeners');
      notifyListeners();
      print('🚪 LoginProvider: Logout complete');
    } catch (e) {
      print('❌ LoginProvider: Logout failed: $e');
      // Even if logout fails, clear the user state
      _user = null;
      notifyListeners();
      // Don't rethrow logout errors - always succeed from UI perspective
    }
  }

  // Method to check if user data exists in storage and restore session
  Future<void> checkStoredUserData() async {
    print('🔍 LoginProvider: Checking for stored user data...');
    try {
      final userData = await _storageService.readUserData();
      if (userData != null) {
        _user = LoginModel.fromJson(userData);
        print('🔍 LoginProvider: User session restored from storage');
        print('🔍 User: ${_user!.username} (${_user!.role})');
        notifyListeners();
      } else {
        print('🔍 LoginProvider: No stored user data found');
      }
    } catch (e) {
      print('❌ LoginProvider: Error checking stored user data: $e');
    }
  }

  // Extract clean user message from exception
  String _extractUserMessage(dynamic error) {
    String errorString = error.toString();

    // If the error is already a clean message from AuthService, use it
    if (errorString.startsWith('Exception: ') &&
        !errorString.toLowerCase().contains('dioexception')) {
      return errorString.replaceFirst('Exception: ', '');
    }

    // Fallback for any unexpected error format
    return 'Something went wrong. Please try again.';
  }
}
