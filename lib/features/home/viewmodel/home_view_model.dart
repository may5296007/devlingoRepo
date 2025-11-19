import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/auth_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseAuth _firebaseAuth;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  List<String> _joursCompletsSemaine = [];

  HomeViewModel({
    required AuthService authService,
    FirebaseAuth? firebaseAuth,
  })  : _authService = authService,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  List<String> get joursCompletsSemaine => _joursCompletsSemaine;

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _userData = null;
      _joursCompletsSemaine = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _authService.updateStreakSiNecessaire(user.uid);

      final data = await _authService.getProfilUtilisateur(user.uid);
      final jours = await _authService.getJoursCompletsSemaine(user.uid);

      _userData = data;
      _joursCompletsSemaine = jours;
    } catch (e) {
      // tu peux logger si tu veux
      _userData = _userData; // on ne touche pas aux anciennes données
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markTodayAsComplete() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    await _authService.marquerJourComplete(user.uid);
    await loadUserData();
  }
}
