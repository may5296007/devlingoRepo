import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/legacy/langage_model.dart';
import '../../../legacy/cours_model.dart';
import '../../../core/services/cours_service.dart';

class LangageCoursScreen extends StatefulWidget {
  final LangageModel langage;

  const LangageCoursScreen({Key? key, required this.langage}) : super(key: key);

  @override
  State<LangageCoursScreen> createState() => _LangageCoursScreenState();
}

class _LangageCoursScreenState extends State<LangageCoursScreen> {
  final CoursService _coursService = CoursService();

  @override
  void initState() {
    super.initState();
    _testConnection();  // ✅ Test automatique au démarrage
  }

  // 🧪 Fonction de test pour vérifier que tout fonctionne
  Future<void> _testConnection() async {
    print('\n🧪 ===TEST DE CONNEXION FIRESTORE ===');
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Test 1: Compter tous les cours
      final allCours = await firestore.collection('cours').get();
      print('📚 Total cours dans Firestore: ${allCours.docs.length}');
      
      if (allCours.docs.isEmpty) {
        print('⚠️  Aucun cours dans Firestore. Crée un cours d\'abord !');
        return;
      }
      
      // Afficher les cours
      for (var doc in allCours.docs) {
        final data = doc.data();
        print('   - ${data['titre']} (langageId: ${data['langageId']}, ordre: ${data['ordre']})');
      }
      
      // Test 2: Filtrer par langageId (sans orderBy)
      print('\n🔍 Test filtre par langageId: ${widget.langage.id}');
      final filtered = await firestore
          .collection('cours')
          .where('langageId', isEqualTo: widget.langage.id)
          .get();
      
      print('   Cours filtrés: ${filtered.docs.length}');
      
      // Test 3: Avec orderBy (nécessite l'index)
      print('\n🎯 Test avec orderBy (nécessite index)...');
      final ordered = await firestore
          .collection('cours')
          .where('langageId', isEqualTo: widget.langage.id)
          .orderBy('ordre')
          .get();
      
      print('✅ SUCCÈS ! L\'index fonctionne !');
      print('📋 Cours trouvés et triés:');
      for (var doc in ordered.docs) {
        final data = doc.data();
        print('   ${data['ordre']}. ${data['titre']}');
      }
    } catch (e) {
      print('❌ ERREUR: $e');
      
      if (e.toString().contains('index')) {
        print('\n💡 SOLUTION:');
        print('═══════════════════════════════════════');
        print('L\'index Firestore n\'est pas créé !');
        print('');
        print('1. Va sur Firebase Console');
        print('2. Clique sur l\'onglet "Indexes"');
        print('3. Clique sur "Create Index"');
        print('4. Configure:');
        print('   Collection: cours');
        print('   Fields:');
        print('     - langageId (Ascending)');
        print('     - ordre (Ascending)');
        print('5. Attends 2-5 minutes que ça devienne "Enabled"');
        print('═══════════════════════════════════════');
      }
    }
    
    print('=========================\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.langage.nom,
                style: const TextStyle(
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
                    colors: isDark
                      ? [const Color(0xFF4A9FFF), const Color(0xFF7EC8FF)]
                      : [const Color(0xFF2F80ED), const Color(0xFF56CCF2)],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.langage.icon,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),

          // Description
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? Border.all(color: const Color(0xFF3C445C), width: 2)
                    : null,
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À propos',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.langage.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Cours disponibles',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 22,
                ),
              ),
            ),
          ),

          StreamBuilder<List<CoursModel>>(
            stream: _coursService.getCoursByLangage(widget.langage.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                print('❌ Erreur Stream: ${snapshot.error}');
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final coursList = snapshot.data ?? [];

              if (coursList.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun cours disponible',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
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
                    return _buildCoursCard(context, coursList[index], isDark);
                  },
                  childCount: coursList.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCoursCard(BuildContext context, CoursModel cours, bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _coursService.getProgress(cours.id),
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data?['progress'] as int? ?? 0;
        final completed = progressSnapshot.data?['completed'] as bool? ?? false;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: const Color(0xFF3C445C), width: 2)
                : null,
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Navigue vers le cours via route nommée avec arguments
                Navigator.pushNamed(
                  context,
                  '/course-detail',
                  arguments: {
                    'courseId': cours.id,
                    'courseData': {
                      'titre': cours.titre,
                      'description': cours.description,
                      'cards': cours.cards.map((c) => c.toMap()).toList(),
                    },
                    'langageData': {
                      'nom': widget.langage.nom,
                      'icon': widget.langage.icon,
                    },
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                                  ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                  : isDark
                                    ? [const Color(0xFF4A9FFF), const Color(0xFF7EC8FF)]
                                    : [const Color(0xFF2F80ED), const Color(0xFF56CCF2)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: completed
                                ? const Icon(Icons.check, color: Colors.white, size: 24)
                                : Text(
                                    '${cours.ordre}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Titre et info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cours.titre,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.layers,
                                    size: 16,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cours.totalCards} cartes',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.quiz,
                                    size: 16,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cours.quizCount} quiz',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
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
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ],
                    ),

                    if (progress > 0) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? const Color(0xFF2A3142)
                              : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completed ? const Color(0xFF4CAF50) : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        completed ? 'Terminé ✓' : '$progress% complété',
                        style: TextStyle(
                          fontSize: 12,
                          color: completed ? const Color(0xFF4CAF50) : Theme.of(context).primaryColor,
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