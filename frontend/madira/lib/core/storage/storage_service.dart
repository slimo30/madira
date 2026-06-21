import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'access_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _roleKey = 'role';

  Future<void> saveToken(String token) async {
    print(' StorageService: Saving token to SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print(' StorageService: Token saved successfully to SharedPreferences');
    } catch (e) {
      print(' StorageService: Failed to save token: $e');
      rethrow;
    }
  }

  Future<void> saveUserData({
    required String token,
    required int userId,
    required String username,
    required String role,
  }) async {
    print(' StorageService: Saving all user data to SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_roleKey, role);
      print(' StorageService: All user data saved successfully');
      print(' Token: ${token.substring(0, 20)}...');
      print(' User ID: $userId');
      print(' Username: $username');
      print(' Role: $role');
    } catch (e) {
      print(' StorageService: Failed to save user data: $e');
      rethrow;
    }
  }

  Future<String?> readToken() async {
    print(' StorageService: Reading token from SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        print(
          ' StorageService: Token read successfully from SharedPreferences',
        );
      } else {
        print(' StorageService: No token found in SharedPreferences');
      }
      return token;
    } catch (e) {
      print(' StorageService: Failed to read token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> readUserData() async {
    print(' StorageService: Reading all user data from SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_tokenKey);
      final userId = prefs.getInt(_userIdKey);
      final username = prefs.getString(_usernameKey);
      final role = prefs.getString(_roleKey);

      if (token != null && userId != null && username != null && role != null) {
        final userData = {
          'access': token,
          'user_id': userId,
          'username': username,
          'role': role,
        };
        print(' StorageService: All user data read successfully');
        print(' User ID: $userId');
        print(' Username: $username');
        print(' Role: $role');
        return userData;
      } else {
        print(
          ' StorageService: Incomplete user data found in SharedPreferences',
        );
        return null;
      }
    } catch (e) {
      print(' StorageService: Failed to read user data: $e');
      return null;
    }
  }

  Future<int?> readUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      print(' StorageService: Failed to read user ID: $e');
      return null;
    }
  }

  Future<String?> readUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print(' StorageService: Failed to read username: $e');
      return null;
    }
  }

  Future<String?> readRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    } catch (e) {
      print(' StorageService: Failed to read role: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    print('️ StorageService: Deleting token from SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print(
        '️ StorageService: Token deleted successfully from SharedPreferences',
      );
    } catch (e) {
      print(' StorageService: Failed to delete token: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserData() async {
    print('️ StorageService: Deleting all user data from SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_roleKey);
      print(
        '️ StorageService: All user data deleted successfully from SharedPreferences',
      );
    } catch (e) {
      print(' StorageService: Failed to delete user data: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    print('️ StorageService: Clearing all data from SharedPreferences...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print(
        '️ StorageService: All data cleared successfully from SharedPreferences',
      );
    } catch (e) {
      print(' StorageService: Failed to clear all data: $e');
      rethrow;
    }
  }
}
