import 'package:flutter/foundation.dart';

import '../../../core/services/cours_service.dart';
import '../../../core/services/role_service.dart';
import '../../../core/legacy/langage_model.dart';
import '../../../core/legacy/user_role.dart';

class CoursListViewModel extends ChangeNotifier {
  final CoursService _coursService;
  final RoleService _roleService;

  // Stream des langages (vient direct du service)
  Stream<List<LangageModel>> get langagesStream =>
      _coursService.getAllLangages();

  bool _showAdminButton = false;
  bool _loadingRole = true;

  bool get showAdminButton => _showAdminButton;
  bool get loadingRole => _loadingRole;

  CoursListViewModel({
    required CoursService coursService,
    required RoleService roleService,
  })  : _coursService = coursService,
        _roleService = roleService {
    _init();
  }

  Future<void> _init() async {
    try {
      final UserRole role = await _roleService.getCurrentUserRole();
      _showAdminButton = role.canCreateCours();
    } catch (e) {
      _showAdminButton = false;
    } finally {
      _loadingRole = false;
      notifyListeners();
    }
  }
}
