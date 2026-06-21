class LoginModel {
  final String access;
  final int userId;
  final String username;
  final String role;

  LoginModel({
    required this.access,
    required this.userId,
    required this.username,
    required this.role,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      access: json['access'],
      userId: json['user_id'],
      username: json['username'],
      role: json['role'],
    );
  }
}
