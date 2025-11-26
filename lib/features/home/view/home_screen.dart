import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../viewmodel/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          HomeViewModel(authService: context.read<AuthService>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({Key? key}) : super(key: key);

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Charger les données utilisateur via le ViewModel
    Future.microtask(() async {
      final vm = context.read<HomeViewModel>();
      await vm.loadUserData();
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (vm.isLoading) {
  return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

  final userData = vm.userData;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(userData, vm),
              ),
              SliverToBoxAdapter(
                child: _buildDailyStats(userData),
              ),
              SliverToBoxAdapter(
                child: _buildWeekCalendar(vm.joursCompletsSemaine),
              ),
              SliverToBoxAdapter(
                child: _buildDailyGoal(),
              ),
              SliverToBoxAdapter(
                child: _buildCurrentCourse(),
              ),
              SliverToBoxAdapter(
                child: _buildBadges(userData),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ HEADER ============

  Widget _buildHeader(Map<String, dynamic>? userData, HomeViewModel vm) {
    final prenom = (userData?['prenom'] ?? 'Développeur').toString();
    final niveau = (userData?['niveau'] ?? 'débutant').toString();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F80ED).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      prenom.isNotEmpty
                          ? prenom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
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
                    padding: const EdgeInsets.all(4),
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

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salut, $prenom ! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2F80ED),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prêt à coder aujourd\'hui ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: const  Color(0xFF2F80ED),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.school, color: Color(0xFF2F80ED)),
            onPressed: () async {
              await Navigator.pushNamed(context, '/cours');
              if (!mounted) return;
              await context.read<HomeViewModel>().loadUserData();
            },
          ),


          // Bouton "marquer jour complet"
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            onPressed: () async {
              await vm.markTodayAsComplete();
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
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
            },
          ),

          IconButton(
            icon: const Icon(Icons.school, color: Color(0xFF2F80ED)),
            onPressed: () {
              Navigator.pushNamed(context, '/cours');
            },
          ),
        ],
      ),
    );
  }

  // ============ STATS ============

  Widget _buildDailyStats(Map<String, dynamic>? userData) {
    final points = userData?['points'] ?? 0;
    final streak = userData?['streak'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department,
              label: 'Streak',
              value: '$streak',
              color: const Color(0xFFFF6B6B),
              gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.stars,
              label: 'Points XP',
              value: '$points',
              color: const Color(0xFFFFD93D),
              gradient: const [Color(0xFFFFD93D), Color(0xFFFFA500)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              label: 'Niveau',
              value: _getUserLevel(points),
              color: const Color(0xFF4ECDC4),
              gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
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

  // ============ CALENDRIER ============

  Widget _buildWeekCalendar(List<String> joursCompletsSemaine) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cette semaine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final now = DateTime.now();
              final day =
                  now.subtract(Duration(days: now.weekday - 1 - index));
              final isToday = day.day == now.day;

              final dateKey =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final isCompleted = joursCompletsSemaine.contains(dateKey);

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
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF4ECDC4)
                : isToday
                    ? const Color(0xFF2F80ED)
                    : Colors.grey[200],
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: const Color(0xFF2F80ED), width: 3)
                : null,
            boxShadow: isCompleted || isToday
                ? [
                    BoxShadow(
                      color: (isCompleted
                              ? const Color(0xFF4ECDC4)
                              : const Color(0xFF2F80ED))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
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

  // ============ OBJECTIF DU JOUR ============

  Widget _buildDailyGoal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Objectif du jour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complète 1 leçon pour maintenir ton streak !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
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

  // ============ COURS ACTUELS ============

  Widget _buildCurrentCourse() {
    return Padding(
      padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langages disponibles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('langages').orderBy('nom').snapshots(),
          builder: (context, langageSnapshot) {
            if (!langageSnapshot.hasData ||
                langageSnapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
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
                final langageData =
                    langageDoc.data() as Map<String, dynamic>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            (langageData['icon'] ?? '💻').toString(),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (langageData['nom'] ?? 'Langage').toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F80ED),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('cours')
                          .where('langageId', isEqualTo: langageDoc.id)
                          .orderBy('ordre')
                          .snapshots(),
                      builder: (context, coursSnapshot) {
                        if (!coursSnapshot.hasData ||
                            coursSnapshot.data!.docs.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
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
                          children:
                              coursSnapshot.data!.docs.map((coursDoc) {
                            final coursData =
                                coursDoc.data() as Map<String, dynamic>;
                            final cards =
                                coursData['cards'] as List<dynamic>? ?? [];

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/course-detail',
                                    arguments: {
                                      'courseId': coursDoc.id,
                                      'courseData': coursData,
                                      'langageData': langageData,
                                    },
                                  );

                                  if (!mounted) return;
                                  await context.read<HomeViewModel>().loadUserData();
                                },


                                child: _buildCourseCard(
                                  title: (coursData['titre'] ??
                                          'Cours sans titre')
                                      .toString(),
                                  subtitle:
                                      '${cards.length} cartes • ${(coursData['description'] ?? 'Cliquez pour commencer').toString()}',
                                  progress:
                                      _calculateProgress(coursDoc.id),
                                  color: _getLanguageColor(
                                      langageData['nom']?.toString()),
                                  icon: (langageData['icon'] ?? '💻')
                                      .toString(),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
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

  double _calculateProgress(String courseId) {
  final vm = context.read<HomeViewModel>();
  final userData = vm.userData;

  if (userData == null) return 0.0;

  final coursProgress = userData['coursProgress'] as Map<String, dynamic>?;

  if (coursProgress == null) return 0.0;
  if (!coursProgress.containsKey(courseId)) return 0.0;

  final data = coursProgress[courseId] as Map<String, dynamic>?;

  if (data == null) return 0.0;

  final num progress = (data['progress'] ?? 0);

  // Convertir 100% → 1.0
  return (progress / 100).clamp(0.0, 1.0);
}


  Color _getLanguageColor(String? langage) {
    switch (langage?.toLowerCase()) {
      case 'python':
        return const Color(0xFF3776AB);
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'java':
        return const Color(0xFF007396);
      case 'react':
        return const Color(0xFF61DAFB);
      case 'flutter':
        return const Color(0xFF02569B);
      case 'html':
        return const Color(0xFFE34C26);
      case 'css':
        return const Color(0xFF1572B6);
      default:
        return const Color(0xFF2F80ED);
    }
  }

  Widget _buildCourseCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required String icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // ← prend la bonne couleur selon light/dark
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }


  // ============ BADGES ============

  Widget _buildBadges(Map<String, dynamic>? userData) {
    final badges = userData?['badges'] ?? ['master'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Badges débloqués 🏆',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFFFFD93D).withOpacity(0.2)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isUnlocked ? const Color(0xFFFFD93D) : Colors.grey[300]!,
          width: isUnlocked ? 2 : 1,
        ),
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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? const Color(0xFF1A1A1A) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPERS NIVEAU / JOUR ============

  Color _getLevelColor(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
        return const Color(0xFF4ECDC4);
      case 'intermédiaire':
        return const Color(0xFF2F80ED);
      case 'avancé':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF4ECDC4);
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
