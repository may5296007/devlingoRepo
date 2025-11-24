import 'package:flutter/material.dart';
import '../../../../legacy/cours_model.dart';
import '../../../../core/services/cours_service.dart';
import '../../../../core/legacy/card_model.dart';

class CourseEditorScreen extends StatefulWidget {
  final String langageId;
  final CoursModel? cours;

  const CourseEditorScreen({
    super.key,
    required this.langageId,
    this.cours,
  });

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final CoursService _coursService = CoursService();

  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  // Liste des cartes
  List<CardModel> _cards = [];

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.cours?.titre ?? '');
    _descriptionController =
        TextEditingController(text: widget.cours?.description ?? '');
    
    // Charger les cartes existantes si on édite un cours
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

    setState(() => _isLoading = true);

    try {
      if (widget.cours == null) {
        // Création d'un nouveau cours
        await _coursService.createCours(
          titre: _titreController.text.trim(),
          langageId: widget.langageId,
          cards: _cards,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cours créé avec succès !')),
          );
        }
      } else {
        // Mise à jour du cours existant
        await _coursService.updateCours(
          widget.cours!.id,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          cards: _cards,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cours modifié avec succès !')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addCard(String type) {
    showDialog(
      context: context,
      builder: (context) => _CardEditorDialog(
        type: type,
        onSave: (card) {
          setState(() {
            _cards.add(card);
          });
        },
      ),
    );
  }

  void _editCard(int index) {
    showDialog(
      context: context,
      builder: (context) => _CardEditorDialog(
        type: _cards[index].type,
        card: _cards[index],
        onSave: (card) {
          setState(() {
            _cards[index] = card;
          });
        },
      ),
    );
  }

  void _deleteCard(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la carte'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette carte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cards.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _reorderCards(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final card = _cards.removeAt(oldIndex);
      _cards.insert(newIndex, card);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.cours == null ? 'Nouveau cours' : 'Modifier le cours',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCours,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'ENREGISTRER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Formulaire de base
            Container(
              color: isDark ? const Color(0xFF1E2430) : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titreController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Titre du cours',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnelle)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                    ),
                  ),
                ],
              ),
            ),

            // En-tête des cartes
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cartes (${_cards.length})',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    onSelected: _addCard,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'lesson',
                        child: Row(
                          children: [
                            Icon(Icons.book, color: Color(0xFF2F80ED)),
                            SizedBox(width: 8),
                            Text('📚 Leçon'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'example',
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, color: Color(0xFF4ECDC4)),
                            SizedBox(width: 8),
                            Text('💡 Exemple'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'quiz',
                        child: Row(
                          children: [
                            Icon(Icons.quiz, color: Color(0xFFFF6B6B)),
                            SizedBox(width: 8),
                            Text('❓ Quiz'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Liste des cartes
            Expanded(
              child: _cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune carte',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appuyez sur + pour ajouter une carte',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _cards.length,
                      onReorder: _reorderCards,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return _buildCardItem(card, index, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(CardModel card, int index, bool isDark) {
    Color cardColor;
    IconData cardIcon;
    String cardLabel;

    switch (card.type.toLowerCase()) {
      case 'lesson':
        cardColor = const Color(0xFF2F80ED);
        cardIcon = Icons.book;
        cardLabel = '📚 Leçon';
        break;
      case 'example':
        cardColor = const Color(0xFF4ECDC4);
        cardIcon = Icons.lightbulb;
        cardLabel = '💡 Exemple';
        break;
      case 'quiz':
        cardColor = const Color(0xFFFF6B6B);
        cardIcon = Icons.quiz;
        cardLabel = '❓ Quiz';
        break;
      default:
        cardColor = const Color(0xFF2F80ED);
        cardIcon = Icons.help;
        cardLabel = '📝 Carte';
    }

    return Container(
      key: ValueKey(card.id.isEmpty ? 'card_$index' : card.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: const Color(0xFF3C445C), width: 2)
            : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(cardIcon, color: cardColor, size: 24),
          ),
        ),
        title: Text(
          cardLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          card.title.length > 50
              ? '${card.title.substring(0, 50)}...'
              : card.title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: cardColor),
              onPressed: () => _editCard(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCard(index),
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Dialog pour créer/éditer une carte
class _CardEditorDialog extends StatefulWidget {
  final String type;
  final CardModel? card;
  final Function(CardModel) onSave;

  const _CardEditorDialog({
    required this.type,
    this.card,
    required this.onSave,
  });

  @override
  State<_CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<_CardEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _codeExampleController;
  late final TextEditingController _explanationController;
  final List<TextEditingController> _optionsControllers = [];
  int _correctAnswerIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?.title ?? '');
    _contentController = TextEditingController(text: widget.card?.content ?? '');
    _codeExampleController = TextEditingController(text: widget.card?.codeExample ?? '');
    _explanationController = TextEditingController(text: widget.card?.explanation ?? '');

    if (widget.type.toLowerCase() == 'quiz') {
      if (widget.card != null && widget.card!.options.isNotEmpty) {
        for (var option in widget.card!.options) {
          _optionsControllers.add(TextEditingController(text: option));
        }
        // Trouver l'index de la bonne réponse
        if (widget.card!.correctAnswer != null) {
          _correctAnswerIndex = widget.card!.options.indexOf(widget.card!.correctAnswer!);
          if (_correctAnswerIndex == -1) _correctAnswerIndex = 0;
        }
      } else {
        // 4 options par défaut
        for (int i = 0; i < 4; i++) {
          _optionsControllers.add(TextEditingController());
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _codeExampleController.dispose();
    _explanationController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }

    if (widget.type.toLowerCase() == 'quiz') {
      // Vérifier que toutes les options sont remplies
      for (var controller in _optionsControllers) {
        if (controller.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toutes les options sont obligatoires')),
          );
          return;
        }
      }

      final options = _optionsControllers.map((c) => c.text.trim()).toList();

      widget.onSave(
        CardModel(
          id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.type,
          title: _titleController.text.trim(),
          content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
          explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
          options: options,
          correctAnswer: options[_correctAnswerIndex],
          question: null,
          reponse: '',
        ),
      );
    } else {
      if (_contentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le contenu est obligatoire')),
        );
        return;
      }

      widget.onSave(
        CardModel(
          id: widget.card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.type,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          codeExample: _codeExampleController.text.trim().isEmpty ? null : _codeExampleController.text.trim(),
          explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
          question: null,
          reponse: '',
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        widget.card == null
            ? 'Nouvelle carte ${_getTypeLabel()}'
            : 'Modifier la carte',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.type.toLowerCase() == 'quiz') ...[
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Question (optionnelle)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_optionsControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswerIndex,
                          onChanged: (value) {
                            setState(() {
                              _correctAnswerIndex = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _optionsControllers[index],
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  'Cochez la bonne réponse',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _explanationController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Explication (optionnelle)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Contenu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeExampleController,
                  maxLines: 4,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Exemple de code (optionnel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _explanationController,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Explication supplémentaire (optionnelle)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A3142) : const Color(0xFFF5F7FA),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  String _getTypeLabel() {
    switch (widget.type.toLowerCase()) {
      case 'lesson':
        return '📚';
      case 'example':
        return '💡';
      case 'quiz':
        return '❓';
      default:
        return '📝';
    }
  }
}