import 'package:flutter/material.dart';
import '../../../models/cours_model.dart';
import '../../../models/card_model.dart';
import '../../../services/cours_service.dart';

class CourseEditorScreen extends StatefulWidget {
  final String langageId;
  final CoursModel? cours; // null = création, non-null = édition

  const CourseEditorScreen({
    Key? key,
    required this.langageId,
    this.cours,
  }) : super(key: key);

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final CoursService _coursService = CoursService();
  
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  
  List<CardModel> _cards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.cours?.titre ?? '');
    _descriptionController = TextEditingController(
      text: widget.cours?.description ?? '',
    );
    
    if (widget.cours != null) {
      _cards = List.from(widget.cours!.cards);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCours() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ajoutez au moins une carte')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.cours == null) {
        // Création
        await _coursService.createCours(
          titre: _titreController.text,
          langageId: widget.langageId,
          cards: _cards,
          description: _descriptionController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cours créé avec succès !')),
        );
      } else {
        // Modification
        await _coursService.updateCours(
          widget.cours!.id,
          titre: _titreController.text,
          cards: _cards,
          description: _descriptionController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cours modifié avec succès !')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.cours == null ? 'Nouveau cours' : 'Modifier cours'),
        backgroundColor: Color(0xFF2F80ED),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveCours,
              child: Text(
                'ENREGISTRER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Informations du cours
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _titreController,
                    decoration: InputDecoration(
                      labelText: 'Titre du cours',
                      prefixIcon: Icon(Icons.title, color: Color(0xFF2F80ED)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Color(0xFFF5F7FA),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez un titre';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnelle)',
                      prefixIcon: Icon(Icons.description, color: Color(0xFF2F80ED)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Color(0xFFF5F7FA),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Liste des cartes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cartes du cours (${_cards.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCardDialog(),
                  icon: Icon(Icons.add),
                  label: Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            if (_cards.isEmpty)
              Container(
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.layers_outlined, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Aucune carte ajoutée',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._cards.asMap().entries.map((entry) {
                return _buildCardItem(entry.key, entry.value);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(int index, CardModel card) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: card.isLesson ? Color(0xFF2F80ED).withOpacity(0.1) : Color(0xFFFFD93D).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            card.isLesson ? Icons.school : Icons.quiz,
            color: card.isLesson ? Color(0xFF2F80ED) : Color(0xFFFFD93D),
          ),
        ),
        title: Text(
          card.titre,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          card.isLesson ? 'Leçon' : 'Quiz',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF2F80ED)),
              onPressed: () => _showEditCardDialog(index, card),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _cards.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCardDialog() async {
    String cardType = 'lesson';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Type de carte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.school, color: Color(0xFF2F80ED)),
              title: Text('Leçon'),
              subtitle: Text('Contenu éducatif avec explications'),
              onTap: () {
                Navigator.pop(context);
                _showCardEditor(type: 'lesson');
              },
            ),
            ListTile(
              leading: Icon(Icons.quiz, color: Color(0xFFFFD93D)),
              title: Text('Quiz'),
              subtitle: Text('Question à choix multiples'),
              onTap: () {
                Navigator.pop(context);
                _showCardEditor(type: 'quiz');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditCardDialog(int index, CardModel card) async {
    _showCardEditor(type: card.type, existingCard: card, index: index);
  }

  Future<void> _showCardEditor({
    required String type,
    CardModel? existingCard,
    int? index,
  }) async {
    final titreController = TextEditingController(text: existingCard?.titre ?? '');
    final contenuController = TextEditingController(text: existingCard?.contenu ?? '');
    final codeController = TextEditingController(text: existingCard?.codeExample ?? '');
    final questionController = TextEditingController(text: existingCard?.question ?? '');
    final explanationController = TextEditingController(text: existingCard?.explanation ?? '');
    
    List<TextEditingController> optionControllers = [];
    if (type == 'quiz') {
      if (existingCard?.options != null) {
        optionControllers = existingCard!.options!.map((opt) => TextEditingController(text: opt)).toList();
      } else {
        optionControllers = List.generate(4, (_) => TextEditingController());
      }
    }
    
    int correctAnswer = existingCard?.correctAnswer ?? 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingCard == null ? 'Nouvelle carte' : 'Modifier carte'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                SizedBox(height: 16),
                
                if (type == 'lesson') ...[
                  TextField(
                    controller: contenuController,
                    decoration: InputDecoration(
                      labelText: 'Contenu',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Exemple de code (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ] else ...[
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),
                  Text('Options de réponse'),
                  SizedBox(height: 8),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: correctAnswer,
                            onChanged: (value) {
                              correctAnswer = value!;
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Option ${String.fromCharCode(65 + i)}',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 16),
                  TextField(
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: 'Explication',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titreController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Le titre est requis')),
                );
                return;
              }

              final newCard = CardModel(
                type: type,
                titre: titreController.text,
                contenu: type == 'lesson' ? contenuController.text : null,
                codeExample: type == 'lesson' && codeController.text.isNotEmpty 
                    ? codeController.text 
                    : null,
                question: type == 'quiz' ? questionController.text : null,
                options: type == 'quiz' 
                    ? optionControllers.map((c) => c.text).toList() 
                    : null,
                correctAnswer: type == 'quiz' ? correctAnswer : null,
                explanation: type == 'quiz' && explanationController.text.isNotEmpty
                    ? explanationController.text
                    : null,
              );

              setState(() {
                if (index != null) {
                  _cards[index] = newCard;
                } else {
                  _cards.add(newCard);
                }
              });

              Navigator.pop(context);
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}