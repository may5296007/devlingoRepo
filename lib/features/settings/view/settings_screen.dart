import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/ theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Color(0xFF2F80ED),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Compte
              _buildSectionTitle('Compte'),
              SizedBox(height: 16),
              _buildSettingsCard(
                icon: Icons.person_outline,
                title: 'Modifier le profil',
                subtitle: 'Changer vos informations',
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.lock_outline,
                title: 'Mot de passe',
                subtitle: 'Changer votre mot de passe',
                onTap: () {
                  _showPasswordDialog();
                },
              ),
              SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: FirebaseAuth.instance.currentUser?.email ?? '',
                onTap: () {},
              ),

              SizedBox(height: 32),

              // Section Notifications
              _buildSectionTitle('Notifications'),
              SizedBox(height: 16),
              _buildSwitchCard(
                icon: Icons.notifications_outlined,
                title: 'Notifications push',
                subtitle: 'Recevoir des rappels',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              SizedBox(height: 12),
              _buildSwitchCard(
                icon: Icons.volume_up_outlined,
                title: 'Sons',
                subtitle: 'Activer les sons',
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                },
              ),

              SizedBox(height: 32),

              // Section Apparence
              _buildSectionTitle('Apparence'),
              SizedBox(height: 16),
              _buildSwitchCard(
                icon: Icons.dark_mode_outlined,
                title: 'Mode sombre',
                subtitle: 'Activer le thème sombre',
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),

              SizedBox(height: 32),

              // Section À propos
              _buildSectionTitle('À propos'),
              SizedBox(height: 16),
              _buildSettingsCard(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.policy_outlined,
                title: 'Politique de confidentialité',
                subtitle: 'Voir nos conditions',
                onTap: () {},
              ),
              SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.help_outline,
                title: 'Support',
                subtitle: 'Besoin d\'aide ?',
                onTap: () {},
              ),

              SizedBox(height: 32),

              // Bouton Déconnexion
              _buildLogoutButton(),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: Color(0xFF3C445C), width: 2)
              : null,
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Color(0xFF3C445C), width: 2)
            : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('Déconnexion'),
              content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.deconnexion();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome',
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Déconnexion'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(Icons.logout),
        label: Text(
          'Se déconnecter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showPasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Ancien mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text == confirmPasswordController.text) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final credential = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: oldPasswordController.text,
                  );

                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);

                  if (!mounted) return;
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mot de passe changé avec succès !'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : Ancien mot de passe incorrect'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2F80ED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}