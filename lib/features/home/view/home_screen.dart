import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isAdmin = false;

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

    Future.microtask(() async {
      final vm = context.read<HomeViewModel>();
      await vm.loadUserData();
      await _checkAdminStatus();
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          _isAdmin = userData?['isAdmin'] == true || 
                     userData?['role'] == 'admin';
        });
      }
    } catch (e) {
      print('Erreur vérification admin: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============ SUPPRESSION LANGAGE ============
  
  Future<void> _deleteLanguage(String langageId, String langageName) async {
    // Vérifier s'il y a des cours associés
    final coursSnapshot = await _firestore
        .collection('cours')
        .where('langageId', isEqualTo: langageId)
        .get();

    if (coursSnapshot.docs.isNotEmpty) {
      // Si des cours existent, demander confirmation
      final confirmWithCourses = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Attention !'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ce langage contient ${coursSnapshot.docs.length} cours.',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                langageName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cette action va supprimer :',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Le langage "$langageName"\n• Tous les ${coursSnapshot.docs.length} cours associés\n• La progression de tous les utilisateurs',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tout supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmWithCourses != true) return;
    } else {
      // Si aucun cours, confirmation simple
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Supprimer le langage'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Êtes-vous sûr de vouloir supprimer ce langage ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                langageName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette action est irréversible',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Supprimer tous les cours associés
      for (var coursDoc in coursSnapshot.docs) {
        await coursDoc.reference.delete();
        
        // Supprimer la progression des utilisateurs pour ce cours
        final usersSnapshot = await _firestore.collection('users').get();
        for (var userDoc in usersSnapshot.docs) {
          final userData = userDoc.data();
          if (userData['coursProgress'] != null) {
            final coursProgress = Map<String, dynamic>.from(userData['coursProgress']);
            if (coursProgress.containsKey(coursDoc.id)) {
              coursProgress.remove(coursDoc.id);
              await userDoc.reference.update({'coursProgress': coursProgress});
            }
          }
        }
      }

      // Supprimer le langage
      await _firestore.collection('langages').doc(langageId).delete();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  coursSnapshot.docs.isEmpty
                      ? 'Langage supprimé avec succès'
                      : 'Langage et ${coursSnapshot.docs.length} cours supprimés',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await context.read<HomeViewModel>().loadUserData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ============ SUPPRESSION COURS ============

  Future<void> _deleteCourse(String courseId, String courseName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Supprimer le cours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir supprimer ce cours ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              courseName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _firestore.collection('cours').doc(courseId).delete();

      final usersSnapshot = await _firestore.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        if (userData['coursProgress'] != null) {
          final coursProgress = Map<String, dynamic>.from(userData['coursProgress']);
          if (coursProgress.containsKey(courseId)) {
            coursProgress.remove(courseId);
            await userDoc.reference.update({'coursProgress': coursProgress});
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Cours supprimé avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await context.read<HomeViewModel>().loadUserData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
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
                child: _buildHeader(userData, vm, isDark),
              ),
              SliverToBoxAdapter(
                child: _buildDailyStats(userData, isDark),
              ),
              SliverToBoxAdapter(
                child: _buildWeekCalendar(vm.joursCompletsSemaine, isDark),
              ),
              SliverToBoxAdapter(
                child: _buildDailyGoal(isDark),
              ),
              SliverToBoxAdapter(
                child: _buildCurrentCourse(isDark),
              ),
              SliverToBoxAdapter(
                child: _buildBadges(userData, isDark),
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

  Widget _buildHeader(Map<String, dynamic>? userData, HomeViewModel vm, bool isDark) {
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
                    gradient: LinearGradient(
                      colors: isDark
                        ? [const Color(0xFF4A9FFF), const Color(0xFF7EC8FF)]
                        : [const Color(0xFF2F80ED), const Color(0xFF56CCF2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      prenom.isNotEmpty ? prenom[0].toUpperCase() : '?',
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
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E2430) : Colors.white, 
                        width: 2,
                      ),
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
                Row(
                  children: [
                    Text(
                      'Salut, $prenom ! 👋',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Prêt à coder aujourd\'hui ?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),

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
            icon: Icon(
              Icons.school,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, '/cours');
              if (!mounted) return;
              await context.read<HomeViewModel>().loadUserData();
            },
          ),
        ],
      ),
    );
  }

  // ============ STATS ============

  Widget _buildDailyStats(Map<String, dynamic>? userData, bool isDark) {
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
              isDark: isDark,
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
              isDark: isDark,
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
              isDark: isDark,
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
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.3),
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

  Widget _buildWeekCalendar(List<String> joursCompletsSemaine, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cette semaine',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final now = DateTime.now();
              final day = now.subtract(Duration(days: now.weekday - 1 - index));
              final isToday = day.day == now.day;

              final dateKey =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final isCompleted = joursCompletsSemaine.contains(dateKey);

              return _buildDayCircle(
                day: _getDayName(day.weekday),
                date: day.day.toString(),
                isToday: isToday,
                isCompleted: isCompleted,
                isDark: isDark,
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
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          day,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
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
                    ? Theme.of(context).primaryColor
                    : isDark
                      ? const Color(0xFF2A3142)
                      : Colors.grey[200],
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  )
                : null,
            boxShadow: isCompleted || isToday
                ? [
                    BoxShadow(
                      color: (isCompleted
                              ? const Color(0xFF4ECDC4)
                              : Theme.of(context).primaryColor)
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
                      color: isToday
                          ? Colors.white
                          : isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ============ OBJECTIF DU JOUR ============

  Widget _buildDailyGoal(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
              ? [const Color(0xFF4A5A8A), const Color(0xFF5E4B7A)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF4A5A8A) : const Color(0xFF667EEA))
                  .withOpacity(0.3),
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

  Widget _buildCurrentCourse(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Langages disponibles',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 18,
                ),
              ),
              if (_isAdmin)
                IconButton(
                  icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-cours');
                  },
                  tooltip: 'Gérer les cours',
                ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('langages').orderBy('nom').snapshots(),
            builder: (context, langageSnapshot) {
              if (!langageSnapshot.hasData || langageSnapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3C445C) : Colors.grey[200]!,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun langage disponible',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const Spacer(),
                            // Bouton de suppression du langage (admin uniquement)
                            if (_isAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: () => _deleteLanguage(
                                  langageDoc.id,
                                  (langageData['nom'] ?? 'Langage').toString(),
                                ),
                                tooltip: 'Supprimer le langage',
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
                                color: isDark 
                                  ? const Color(0xFF2A3142) 
                                  : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Aucun cours disponible pour ce langage',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: coursSnapshot.data!.docs.map((coursDoc) {
                              final coursData =
                                  coursDoc.data() as Map<String, dynamic>;
                              final cards =
                                  coursData['cards'] as List<dynamic>? ?? [];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCourseCard(
                                  courseId: coursDoc.id,
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
                                  isDark: isDark,
                                  coursData: coursData,
                                  langageData: langageData,
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
    required String courseId,
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required String icon,
    required bool isDark,
    required Map<String, dynamic> coursData,
    required Map<String, dynamic> langageData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/course-detail',
            arguments: {
              'courseId': courseId,
              'courseData': coursData,
              'langageData': langageData,
            },
          );

          if (!mounted) return;
          await context.read<HomeViewModel>().loadUserData();
        },
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? const Color(0xFF2A3142)
                        : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (_isAdmin)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deleteCourse(courseId, title),
                tooltip: 'Supprimer',
              )
            else
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // ============ BADGES ============

  Widget _buildBadges(Map<String, dynamic>? userData, bool isDark) {
    final badges = userData?['badges'] ?? ['master'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges débloqués 🏆',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBadge('🎯', 'Premier pas', true, isDark),
              _buildBadge('🔥', 'Streak 7j', badges.contains('master'), isDark),
              _buildBadge('⭐', 'Master', badges.contains('master'), isDark),
              _buildBadge('🚀', 'Fusée', false, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String emoji, String label, bool isUnlocked, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFFFFD93D).withOpacity(0.2)
            : isDark
              ? const Color(0xFF2A3142)
              : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFFFFD93D)
              : isDark
                ? const Color(0xFF3C445C)
                : Colors.grey[300]!,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              color: isUnlocked
                  ? Colors.black
                  : isDark
                    ? Colors.grey[600]
                    : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                  : isDark
                    ? Colors.grey[500]
                    : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPERS ============

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