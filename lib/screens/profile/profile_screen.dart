import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool _isLoading = true;

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
      final data = await _authService.getProfilUtilisateur(user.uid);
      setState(() {
        userData = data;
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
    }

    final prenom = userData?['prenom'] ?? 'Développeur';
    final nom = userData?['nom'] ?? '';
    final email = userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
    final niveau = userData?['niveau'] ?? 'débutant';
    final points = userData?['points'] ?? 0;
    final streak = userData?['streak'] ?? 0;
    final badges = (userData?['badges'] as List?)?.length ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // AppBar simple
              SliverAppBar(
                backgroundColor: Color(0xFF1A1F36),
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar + Info
                      _buildProfileHeader(prenom, nom, niveau),

                      SizedBox(height: 24),

                      // Date d'inscription
                      _buildJoinedDate(),

                      SizedBox(height: 32),

                      // Section Statistics
                      _buildSectionTitle('Statistics'),

                      SizedBox(height: 16),

                      // Stats Cards
                      _buildStatsGrid(streak, points, badges),

                      SizedBox(height: 32),

                      // Section Achievements
                      _buildSectionTitle('Achievements'),

                      SizedBox(height: 16),

                      // Achievements List
                      _buildAchievementsList(),

                      SizedBox(height: 32),

                      // Section Account
                      _buildSectionTitle('Account Information'),

                      SizedBox(height: 16),

                      // Account Info
                      _buildAccountInfo(email, prenom, nom, niveau),

                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String prenom, String nom, String niveau) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF58CC02),
                border: Border.all(color: Color(0xFF46A302), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF58CC02).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  prenom[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 40,
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF1CB0F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF1A1F36), width: 3),
                ),
                child: Icon(
                  Icons.verified,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          '$prenom $nom',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getLevelColor(niveau).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getLevelColor(niveau), width: 1),
          ),
          child: Text(
            _getNiveauText(niveau),
            style: TextStyle(
              fontSize: 14,
              color: _getLevelColor(niveau),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM yyyy');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, color: Colors.grey[400], size: 18),
        SizedBox(width: 8),
        Text(
          'Joined ${formatter.format(now)}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int streak, int points, int badges) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                value: streak.toString(),
                label: 'Day streak',
                color: Color(0xFFFF9600),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.bolt,
                value: points.toString(),
                label: 'Total XP',
                color: Color(0xFFFFC800),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events,
                value: _getLeague(points),
                label: 'Current league',
                color: Color(0xFF58CC02),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.workspace_premium,
                value: badges.toString(),
                label: 'Achievements',
                color: Color(0xFF1CB0F6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2B3252),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3C445C), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 12),
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
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    final achievements = [
      {
        'title': 'Legendary',
        'description': 'Complete 25 legendary levels',
        'progress': 10,
        'total': 25,
        'color': Color(0xFFFFC800),
        'level': 4,
      },
      {
        'title': 'Challenger',
        'description': 'Earn 500 XP in timed challenges',
        'progress': 228,
        'total': 500,
        'color': Color(0xFFCE82FF),
        'level': 3,
      },
      {
        'title': 'Wildfire',
        'description': 'Reach a 50 day streak',
        'progress': 40,
        'total': 50,
        'color': Color(0xFFFF4B4B),
        'level': 2,
      },
    ];

    return Column(
      children: achievements.map((achievement) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildAchievementCard(achievement),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final progress = achievement['progress'] as int;
    final total = achievement['total'] as int;
    final percentage = progress / total;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2B3252),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3C445C), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: achievement['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: achievement['color'], size: 28),
                SizedBox(height: 2),
                Text(
                  'LEVEL ${achievement['level']}',
                  style: TextStyle(
                    fontSize: 8,
                    color: achievement['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$progress/$total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  achievement['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Color(0xFF3C445C),
                    valueColor: AlwaysStoppedAnimation<Color>(achievement['color']),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(String email, String prenom, String nom, String niveau) {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.email_outlined,
          label: 'Email',
          value: email,
          onTap: () => _showEditDialog('email', email),
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.person_outline,
          label: 'Prénom',
          value: prenom,
          onTap: () => _showEditDialog('prenom', prenom),
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.person_outline,
          label: 'Nom',
          value: nom,
          onTap: () => _showEditDialog('nom', nom),
        ),
        SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.code,
          label: 'Niveau',
          value: _getNiveauText(niveau),
          onTap: () => _showLevelDialog(),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2B3252),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF3C445C), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF58CC02), size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2B3252),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Modifier $field',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nouveau $field',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Color(0xFF1A1F36),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await _firestore.collection('users').doc(user.uid).update({
                  field: controller.text,
                });
                await _loadUserData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$field mis à jour !'),
                    backgroundColor: Color(0xFF58CC02),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF58CC02),
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

  void _showLevelDialog() {
    final levels = [
      {'id': 'débutant', 'label': 'Débutant', 'color': Color(0xFF58CC02)},
      {'id': 'intermédiaire', 'label': 'Intermédiaire', 'color': Color(0xFF1CB0F6)},
      {'id': 'avancé', 'label': 'Avancé', 'color': Color(0xFFFF4B4B)},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2B3252),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Changer de niveau',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await _firestore.collection('users').doc(user.uid).update({
                      'niveau': level['id'],
                    });
                    await _loadUserData();
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1F36),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: level['color'] as Color, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: level['color'] as Color, size: 24),
                      SizedBox(width: 16),
                      Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getLevelColor(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
        return Color(0xFF58CC02);
      case 'intermédiaire':
        return Color(0xFF1CB0F6);
      case 'avancé':
        return Color(0xFFFF4B4B);
      default:
        return Color(0xFF58CC02);
    }
  }

  String _getNiveauText(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
        return 'Débutant';
      case 'intermédiaire':
        return 'Intermédiaire';
      case 'avancé':
        return 'Avancé';
      default:
        return 'Débutant';
    }
  }

  String _getLeague(int points) {
    if (points < 100) return 'Bronze';
    if (points < 500) return 'Silver';
    if (points < 1000) return 'Gold';
    if (points < 2000) return 'Emerald';
    return 'Diamond';
  }
}