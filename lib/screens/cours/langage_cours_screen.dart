import 'package:flutter/material.dart';
import '../../models/langage_model.dart';
import '../../models/cours_model.dart';
import '../../services/cours_service.dart';
import 'cours_swipe_screen.dart';

class LangageCoursScreen extends StatelessWidget {
  final LangageModel langage;
  final CoursService _coursService = CoursService();

  LangageCoursScreen({Key? key, required this.langage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Color(0xFF2F80ED),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                langage.nom,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                  ),
                ),
                child: Center(
                  child: Text(
                    langage.icon,
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),

          // Description
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    langage.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des cours
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Cours disponibles',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          StreamBuilder<List<CoursModel>>(
            stream: _coursService.getCoursByLangage(langage.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Erreur de chargement'),
                    ),
                  ),
                );
              }

              final coursList = snapshot.data ?? [];

              if (coursList.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun cours disponible',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildCoursCard(context, coursList[index]);
                  },
                  childCount: coursList.length,
                ),
              );
            },
          ),

          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCoursCard(BuildContext context, CoursModel cours) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _coursService.getProgress(cours.id),
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data?['progress'] as int? ?? 0;
        final completed = progressSnapshot.data?['completed'] as bool? ?? false;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoursSwipeScreen(cours: cours),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Numéro du cours
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: completed
                                  ? [Color(0xFF4CAF50), Color(0xFF66BB6A)]
                                  : [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: completed
                                ? Icon(Icons.check, color: Colors.white, size: 24)
                                : Text(
                                    '${cours.ordre}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Titre et info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cours.titre,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.layers,
                                      size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    '${cours.totalCards} cartes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.quiz,
                                      size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    '${cours.quizCount} quiz',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Icône
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF2F80ED),
                          size: 20,
                        ),
                      ],
                    ),

                    if (progress > 0) ...[
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completed ? Color(0xFF4CAF50) : Color(0xFF2F80ED),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        completed ? 'Terminé ✓' : '$progress% complété',
                        style: TextStyle(
                          fontSize: 12,
                          color: completed ? Color(0xFF4CAF50) : Color(0xFF2F80ED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}