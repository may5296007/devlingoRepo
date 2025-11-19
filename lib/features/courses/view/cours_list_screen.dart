import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cours_service.dart';
import '../../../core/services/role_service.dart';
import '../../../core/legacy/langage_model.dart';
import '../viewmodel/courses_view_model.dart';
import 'langage_cours_screen.dart';

class CoursListScreen extends StatelessWidget {
  CoursListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CoursListViewModel(
        coursService: CoursService(),
        roleService: RoleService(),
      ),
      child: const _CoursListView(),
    );
  }
}

class _CoursListView extends StatelessWidget {
  const _CoursListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CoursListViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Cours disponibles'),
        backgroundColor: const Color(0xFF2F80ED),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/admin-cours');
            },
            tooltip: 'Admin',
          ),
        ],
      ),
      body: StreamBuilder<List<LangageModel>>(
        stream: viewModel.langagesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
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
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style:
                        TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                  Icon(Icons.school_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun cours disponible',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les cours seront bientôt ajoutés !',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).size.width > 600 ? 3 : 2,
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
      floatingActionButton: viewModel.loadingRole
          ? const SizedBox.shrink()
          : viewModel.showAdminButton
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-cours');
                  },
                  backgroundColor: const Color(0xFF2F80ED),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin'),
                )
              : const SizedBox.shrink(),
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
              color: const Color(0xFF2F80ED).withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  langage.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nom du langage
            Text(
              langage.nom,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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

            const SizedBox(height: 12),

            const Icon(
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
