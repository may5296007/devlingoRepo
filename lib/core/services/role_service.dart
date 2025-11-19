import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../legacy/user_role.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer le rôle de l'utilisateur actuel
  Future<UserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.user;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return UserRole.user;

      final roleString = doc.data()?['role'] as String? ?? 'user';
      return UserRole.fromString(roleString);
    } catch (e) {
      print('Erreur récupération rôle: $e');
      return UserRole.user;
    }
  }

  // Stream du rôle utilisateur
  Stream<UserRole> watchUserRole() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(UserRole.user);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return UserRole.user;
      final roleString = doc.data()?['role'] as String? ?? 'user';
      return UserRole.fromString(roleString);
    });
  }

  // Vérifier si l'utilisateur peut créer des cours
  Future<bool> canCreateCours() async {
    final role = await getCurrentUserRole();
    return role.canCreateCours();
  }

  // Vérifier si l'utilisateur peut éditer un cours
  Future<bool> canEditCours(String coursCreatedBy) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final role = await getCurrentUserRole();
    
    // Admin peut tout modifier
    if (role.canEditAllCours()) return true;
    
    // Teacher peut modifier ses propres cours
    if (role.canCreateCours() && coursCreatedBy == user.uid) return true;

    return false;
  }

  // Vérifier si l'utilisateur peut supprimer un cours
  Future<bool> canDeleteCours() async {
    final role = await getCurrentUserRole();
    return role.canDeleteCours();
  }

  // Changer le rôle d'un utilisateur (admin only)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    final canManage = (await getCurrentUserRole()).canManageUsers();
    if (!canManage) {
      throw Exception('Permissions insuffisantes');
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole.value,
    });
  }
}