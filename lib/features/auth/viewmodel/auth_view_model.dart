import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';

enum AuthStatus {
  idle,
  loading,
  success,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  AuthViewModel({required AuthService authService})
      : _authService = authService;

  void _setStatus(AuthStatus newStatus, {String? message}) {
    _status = newStatus;
    _errorMessage = message;
    notifyListeners();
  }

  /// Connexion email/mot de passe
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);

    try {
      await _authService.connexion(email: email, password: password);
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setStatus(AuthStatus.error, message: e.toString());
    }
  }

  /// Inscription email/mot de passe
  Future<void> signUp({
    required String prenom,
    required String nom,
    required String email,
    required String password,
    required String level,
    required DateTime birthDate,
  }) async {
    _setStatus(AuthStatus.loading);

    try {
      await _authService.inscription(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        niveau: level,
        birthday: birthDate,
      );
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setStatus(AuthStatus.error, message: e.toString());
    }
  }

  /// Connexion Google (si tu l’utilises dans l’UI)
  Future<void> loginWithGoogle() async {
    _setStatus(AuthStatus.loading);

    try {
      await _authService.connexionGoogle();
      _setStatus(AuthStatus.success);
    } catch (e) {
      _setStatus(AuthStatus.error, message: e.toString());
    }
  }

  void resetStatus() {
    _setStatus(AuthStatus.idle);
  }
}
