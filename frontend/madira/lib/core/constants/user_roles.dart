class UserRole {
  static const String admin = 'admin';
  static const String responsible = 'responsible';
  static const String simpleUser = 'simple_user';

  static const List<String> allRoles = [admin, responsible, simpleUser];

  static String getDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'responsible':
        return 'Responsible';
      case 'simple_user':
        return 'Simple User';
      default:
        return role;
    }
  }

  static bool isAdmin(String role) => role.toLowerCase() == admin;
  static bool isResponsible(String role) => role.toLowerCase() == responsible;
  static bool isSimpleUser(String role) => role.toLowerCase() == simpleUser;
}
