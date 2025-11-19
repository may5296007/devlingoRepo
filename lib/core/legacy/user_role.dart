enum UserRole {
  user('user', 'Utilisateur', 0),
  teacher('teacher', 'Professeur', 1),
  admin('admin', 'Administrateur', 2);

  final String value;
  final String displayName;
  final int level;

  const UserRole(this.value, this.displayName, this.level);

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role,
      orElse: () => UserRole.user,
    );
  }

  bool canCreateCours() => level >= 1;
  bool canEditAllCours() => level >= 2;
  bool canDeleteCours() => level >= 2;
  bool canManageUsers() => level >= 2;
}