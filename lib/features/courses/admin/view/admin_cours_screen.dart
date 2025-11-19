import 'package:flutter/material.dart';
import '../../../../core/legacy/langage_model.dart';
import '../../../../legacy/cours_model.dart';
import '../../../../core/services/cours_service.dart';
import '../../../../core/services/role_service.dart';
import '../../../../core/legacy/user_role.dart';
import 'course_editor_screen.dart';

class AdminCoursScreen extends StatefulWidget {
  const AdminCoursScreen({Key? key}) : super(key: key);

  @override
  State<AdminCoursScreen> createState() => _AdminCoursScreenState();
}

class _AdminCoursScreenState extends State<AdminCoursScreen> {
  final CoursService _coursService = CoursService();
  final RoleService _roleService = RoleService();
  
  String? _selectedLangageId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Gestion des cours'),
        backgroundColor: Color(0xFF2F80ED),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sélection du langage
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: StreamBuilder<List<LangageModel>>(
              stream: _coursService.getAllLangages(),
              builder: (context, snapshot) {
                final langages = snapshot.data ?? [];
                
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLangageId,
                        decoration: InputDecoration(
                          labelText: 'Sélectionner un langage',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F7FA),
                        ),
                        items: langages.map((langage) {
                          return DropdownMenuItem(
                            value: langage.id,
                            child: Row(
                              children: [
                                Text(langage.icon, style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text(langage.nom),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLangageId = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.add_circle, size: 32),
                      color: Color(0xFF2F80ED),
                      onPressed: () => _showAddLangageDialog(),
                    ),
                  ],
                );
              },
            ),
          ),

          // Liste des cours
          Expanded(
            child: _selectedLangageId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Sélectionnez un langage',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<CoursModel>>(
                    stream: _coursService.getCoursByLangage(_selectedLangageId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2F80ED)),
                          ),
                        );
                      }

                      final coursList = snapshot.data ?? [];

                      if (coursList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined,
                                  size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Aucun cours créé',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: coursList.length,
                        itemBuilder: (context, index) {
                          return _buildCoursCard(coursList[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedLangageId != null
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToEditor(),
              backgroundColor: Color(0xFF2F80ED),
              icon: Icon(Icons.add),
              label: Text('Nouveau cours'),
            )
          : null,
    );
  }

  Widget _buildCoursCard(CoursModel cours) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${cours.ordre}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(
          cours.titre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${cours.totalCards} cartes • ${cours.quizCount} quiz',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _navigateToEditor(cours: cours);
            } else if (value == 'delete') {
              _confirmDelete(cours);
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF2F80ED)),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: FutureBuilder<UserRole>(
                  future: _roleService.getCurrentUserRole(),
                  builder: (context, snapshot) {
                    if (snapshot.data?.canDeleteCours() ?? false) {
                      return Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  void _navigateToEditor({CoursModel? cours}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseEditorScreen(
          langageId: _selectedLangageId!,
          cours: cours,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CoursModel cours) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le cours ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${cours.titre}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _coursService.deleteCours(cours.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cours supprimé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showAddLangageDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = '📚';

    final icons = ['🐍', '⚡', '☕', '🌐', '📱', '💻', '🔧', '📚'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouveau langage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du langage',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              Text('Choisir une icône'),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: icons.map((icon) {
                  return GestureDetector(
                    onTap: () {
                      selectedIcon = icon;
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF2F80ED)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(icon, style: TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _coursService.createLangage(
                    nameController.text,
                    selectedIcon,
                    descController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Langage créé avec succès')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }
}