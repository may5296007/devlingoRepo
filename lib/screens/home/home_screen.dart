import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool _isLoading = true;
  List<String> _joursCompletsSemaine = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Mettre à jour le streak si nécessaire
      await _authService.updateStreakSiNecessaire(user.uid);

      // Charger les données utilisateur
      final data = await _authService.getProfilUtilisateur(user.uid);

      // Charger les jours complétés de la semaine
      final joursCompletes = await _authService.getJoursCompletsSemaine(user.uid);

      setState(() {
        userData = data;
        _joursCompletsSemaine = joursCompletes;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // AppBar personnalisé
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // Statistiques du jour
              SliverToBoxAdapter(
                child: _buildDailyStats(),
              ),

              // Calendrier de la semaine
              SliverToBoxAdapter(
                child: _buildWeekCalendar(),
              ),

              // Objectif du jour
              SliverToBoxAdapter(
                child: _buildDailyGoal(),
              ),

              // Cours en cours
              SliverToBoxAdapter(
                child: _buildCurrentCourse(),
              ),

              // Badges
              SliverToBoxAdapter(
                child: _buildBadges(),
              ),

              // Espacement final
              SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final prenom = userData?['prenom'] ?? 'Développeur';
    final niveau = userData?['niveau'] ?? 'débutant';

    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          // Avatar avec niveau - CLIQUABLE VERS PROFIL
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2F80ED).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      prenom[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(niveau),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _getLevelIcon(niveau),
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16),

          // Texte de bienvenue
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut, $prenom ! 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Prêt à coder aujourd\'hui ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),


          // Bouton paramètres
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Color(0xFF2F80ED)),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),

          // ✅ BOUTON TEST (à côté des settings)
          IconButton(
            icon: Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await _authService.marquerJourComplete(user.uid);
                await _loadUserData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.celebration, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Aujourd\'hui marqué ! 🎉'),
                      ],
                    ),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.school, color: Color(0xFF2F80ED)),
            onPressed: () {
              Navigator.pushNamed(context, '/cours');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats() {
    final points = userData?['points'] ?? 0;
    final streak = userData?['streak'] ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department,
              label: 'Streak',
              value: '$streak',
              color: Color(0xFFFF6B6B),
              gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.stars,
              label: 'Points XP',
              value: '$points',
              color: Color(0xFFFFD93D),
              gradient: [Color(0xFFFFD93D), Color(0xFFFFA500)],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              label: 'Niveau',
              value: _getUserLevel(points),
              color: Color(0xFF4ECDC4),
              gradient: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cette semaine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final now = DateTime.now();
              final day = now.subtract(Duration(days: now.weekday - 1 - index));
              final isToday = day.day == now.day;
              final isCompleted = index < 4; // Simulé

              return _buildDayCircle(
                day: _getDayName(day.weekday),
                date: day.day.toString(),
                isToday: isToday,
                isCompleted: isCompleted,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle({
    required String day,
    required String date,
    required bool isToday,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted
                ? Color(0xFF4ECDC4)
                : isToday
                ? Color(0xFF2F80ED)
                : Colors.grey[200],
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: Color(0xFF2F80ED), width: 3)
                : null,
            boxShadow: isCompleted || isToday
                ? [
              BoxShadow(
                color: (isCompleted ? Color(0xFF4ECDC4) : Color(0xFF2F80ED))
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
              date,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoal() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objectif du jour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Complète 1 leçon pour maintenir ton streak !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Voici la partie mise à jour de home_screen.dart
// Remplace la fonction _buildCurrentCourse() dans ton home_screen.dart par celle-ci :

Widget _buildCurrentCourse() {
  return Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Langages disponibles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 16),
        // D'abord récupérer les langages
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('langages')
              .orderBy('nom')
              .snapshots(),
          builder: (context, langageSnapshot) {
            if (!langageSnapshot.hasData || langageSnapshot.data!.docs.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, 
                        size: 48, 
                        color: Colors.grey[400]
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun langage disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: langageSnapshot.data!.docs.map((langageDoc) {
                final langageData = langageDoc.data() as Map<String, dynamic>;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Afficher le langage
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2F80ED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            langageData['icon'] ?? '💻',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(width: 8),
                          Text(
                            langageData['nom'] ?? 'Langage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F80ED),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Récupérer les cours de ce langage
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('cours')
                          .where('langageId', isEqualTo: langageDoc.id)
                          .orderBy('ordre')
                          .snapshots(),
                      builder: (context, coursSnapshot) {
                        if (!coursSnapshot.hasData || coursSnapshot.data!.docs.isEmpty) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Aucun cours disponible pour ce langage',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: coursSnapshot.data!.docs.map((coursDoc) {
                            final coursData = coursDoc.data() as Map<String, dynamic>;
                            final cards = coursData['cards'] as List<dynamic>? ?? [];
                            
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/course-detail',
                                    arguments: {
                                      'courseId': coursDoc.id,
                                      'courseData': coursData,
                                      'langageData': langageData,
                                    },
                                  );
                                },
                                child: _buildCourseCard(
                                  title: coursData['titre'] ?? 'Cours sans titre',
                                  subtitle: '${cards.length} cartes • ${coursData['description'] ?? 'Cliquez pour commencer'}',
                                  progress: _calculateProgress(coursDoc.id),
                                  color: _getLanguageColor(langageData['nom']),
                                  icon: langageData['icon'] ?? '💻',
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}

// Ajoute aussi cette fonction pour calculer la progression (si elle n'existe pas déjà) :
double _calculateProgress(String courseId) {
  // TODO: Calculer la vraie progression depuis Firestore
  return 0.0;
}

// Et cette fonction pour obtenir la couleur du langage :
Color _getLanguageColor(String? langage) {
  switch (langage?.toLowerCase()) {
    case 'python':
      return Color(0xFF3776AB);
    case 'javascript':
      return Color(0xFFF7DF1E);
    case 'java':
      return Color(0xFF007396);
    case 'react':
      return Color(0xFF61DAFB);
    case 'flutter':
      return Color(0xFF02569B);
    case 'html':
      return Color(0xFFE34C26);
    case 'css':
      return Color(0xFF1572B6);
    default:
      return Color(0xFF2F80ED);
  }
}

  Widget _buildCourseCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 32)),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_forward_ios, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    final badges = userData?['badges'] ?? ['master'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges débloqués 🏆',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBadge('🎯', 'Premier pas', true),
              _buildBadge('🔥', 'Streak 7j', badges.contains('master')),
              _buildBadge('⭐', 'Master', badges.contains('master')),
              _buildBadge('🚀', 'Fusée', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String emoji, String label, bool isUnlocked) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? Color(0xFFFFD93D).withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: isUnlocked
            ? Border.all(color: Color(0xFFFFD93D), width: 2)
            : Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              color: isUnlocked ? Colors.black : Colors.grey,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Color(0xFF1A1A1A) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
        return Color(0xFF4ECDC4);
      case 'intermédiaire':
        return Color(0xFF2F80ED);
      case 'avancé':
        return Color(0xFFFF6B6B);
      default:
        return Color(0xFF4ECDC4);
    }
  }

  IconData _getLevelIcon(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
        return Icons.rocket_launch;
      case 'intermédiaire':
        return Icons.code;
      case 'avancé':
        return Icons.workspace_premium;
      default:
        return Icons.rocket_launch;
    }
  }

  String _getUserLevel(int points) {
    if (points < 100) return '1';
    if (points < 300) return '2';
    if (points < 600) return '3';
    if (points < 1000) return '4';
    return '5+';
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }
}