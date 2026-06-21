import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false; // Prevent duplicate fetches

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all users (with duplicate prevention)
  Future<void> fetchUsers() async {
    if (_isFetching) {
      print(
        '️ UserProvider: Fetch already in progress, skipping duplicate request',
      );
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
      print(' UserProvider: Fetched ${_users.length} users successfully');
    } catch (e) {
      _error = e.toString();
      print(' UserProvider: Error fetching users: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // Create new user
  Future<void> createUser({
    required String username,
    required String password,
    required String role,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(' UserProvider: Creating user: $username');
      await _userService.createUser(
        username: username,
        password: password,
        role: role,
        fullName: fullName,
      );

      // Fetch all users to get the new user with correct ID
      print(' UserProvider: Fetching all users to get new user ID');
      _users = await _userService.getAllUsers();
      print(
        ' UserProvider: User created and users list refreshed. Total users: ${_users.length}',
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print(' UserProvider: Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Deactivate user
  Future<void> deactivateUser(int userId) async {
    try {
      print(' UserProvider: Deactivating user $userId');
      await _userService.deactivateUser(userId);

      // Refresh the user data
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = await _userService.getUserById(userId);
        print(' UserProvider: User $userId deactivated and refreshed');
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print(' UserProvider: Error deactivating user: $e');
      rethrow;
    }
  }

  // Reactivate user
  Future<void> reactivateUser(int userId) async {
    try {
      print(' UserProvider: Reactivating user $userId');
      await _userService.reactivateUser(userId);

      // Refresh the user data
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = await _userService.getUserById(userId);
        print(' UserProvider: User $userId reactivated and refreshed');
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print(' UserProvider: Error reactivating user: $e');
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
