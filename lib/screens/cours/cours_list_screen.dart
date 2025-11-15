import 'package:flutter/material.dart';
import '../../models/langage_model.dart';
import '../../services/cours_service.dart';
import '../../services/role_service.dart';
import '../../models/user_role.dart';
import 'langage_cours_screen.dart';

class CoursListScreen extends StatelessWidget {
  final CoursService _coursService = CoursService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Cours disponibles'),
        backgroundColor: Color(0xFF2F80ED),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                print('🔧 Navigation admin');
                Navigator.pushNamed(context, '/admin-cours');
              },
              tooltip: 'Admin',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<LangageModel>>(
        stream: _coursService.getAllLangages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final langages = snapshot.data ?? [];

          if (langages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Aucun cours disponible',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les cours seront bientôt ajoutés !',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16,
            ),
            itemCount: langages.length,
            itemBuilder: (context, index) {
              return _buildLangageCard(context, langages[index]);
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<UserRole>(
        future: RoleService().getCurrentUserRole(),
        builder: (context, snapshot) {
          // Pendant le chargement, n'affiche rien
          if (!snapshot.hasData) {
            return SizedBox.shrink();
          }

          final role = snapshot.data!;
          
          // Affiche le bouton SEULEMENT si teacher ou admin
          if (role.canCreateCours()) {
            return FloatingActionButton.extended(
              onPressed: () {
                print('🚀 Navigation admin - Role: ${role.value}');
                Navigator.pushNamed(context, '/admin-cours');
              },
              backgroundColor: Color(0xFF2F80ED),
              icon: Icon(Icons.admin_panel_settings),
              label: Text('Admin'),
            );
          }
          
          // Sinon, n'affiche rien
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLangageCard(BuildContext context, LangageModel langage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LangageCoursScreen(langage: langage),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2F80ED).withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône du langage
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  langage.icon,
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Nom du langage
            Text(
              langage.nom,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                langage.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 12),

            // Indicateur
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF2F80ED),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}