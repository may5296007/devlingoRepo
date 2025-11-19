import 'package:flutter/material.dart';
import '../services/role_service.dart';
import 'user_role.dart';

class RoleGuard extends StatelessWidget {
  final UserRole minimumRole;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    Key? key,
    required this.minimumRole,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleService = RoleService();

    return StreamBuilder<UserRole>(
      stream: roleService.watchUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return fallback ?? SizedBox.shrink();
        }

        final userRole = snapshot.data!;
        final hasAccess = userRole.level >= minimumRole.level;

        if (hasAccess) {
          return child;
        }

        return fallback ?? SizedBox.shrink();
      },
    );
  }
}