// Ton code CoursePreviewScreen complètement réécrit proprement
// Version stable, cohérente, sans doublons, sans bugs
// Compatible avec ton CardModel et ton cours service

import 'package:flutter/material.dart';
import '../../../core/services/cours_service.dart';
import '../../../core/legacy/card_model.dart';
import '../widgets/exercise_editor_dialog.dart';

class CoursePreviewScreen extends StatefulWidget {
  final dynamic cours;
  const CoursePreviewScreen({super.key, required this.cours});

  @override
  State<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends State<CoursePreviewScreen> {
  List<CardModel> cards = [];

  @override
  void initState() {
    super.initState();
    cards = widget.cours.cards ?? [];
  }

  // ---------------------- UI HELPERS ----------------------
  IconData _getIcon(String type) {
    switch (type) {
      case "lesson":
        return Icons.menu_book_rounded;
      case "quiz":
        return Icons.quiz_rounded;
      case "example":
        return Icons.code_rounded;
      case "exercise":
        return Icons.fitness_center_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Color _getCardColor(String type) {
    switch (type) {
      case "lesson":
        return Colors.blue.shade100;
      case "quiz":
        return Colors.orange.shade100;
      case "example":
        return Colors.green.shade100;
      case "exercise":
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  // ---------------------- LESSON EDITOR ----------------------
  void _openLessonEditor(CardModel? card) async {
    final titleC = TextEditingController(text: card?.title ?? "");
    final questionC = TextEditingController(text: card?.question ?? "");
    final answerC = TextEditingController(text: card?.reponse ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(card == null ? "Ajouter une leçon" : "Modifier la leçon"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Titre", titleC),
              _field("Contenu / Concept", questionC, max: 3),
              _field("Réponse simple", answerC, max: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final newCard = CardModel(
                id: card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                type: "lesson",
                title: titleC.text,
                question: questionC.text,
                reponse: answerC.text,
              );

              if (card == null) {
                cards.add(newCard);
              } else {
                final index = cards.indexOf(card);
                cards[index] = newCard;
              }

              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  // ---------------------- QUIZ EDITOR ----------------------
  void _openQuizEditor(CardModel? card) async {
    final titleC = TextEditingController(text: card?.title ?? "");
    final questionC = TextEditingController(text: card?.question ?? "");

    final optionC = List.generate(4, (i) => TextEditingController(
          text: card?.options != null && card!.options!.length > i ? card.options![i] : "",
        ));

    final correctC = TextEditingController(text: card?.correctAnswer ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(card == null ? "Ajouter un quiz" : "Modifier le quiz"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Titre du quiz", titleC),
              _field("Question", questionC, max: 3),
              for (int i = 0; i < 4; i++) _field("Option ${i + 1}", optionC[i]),
              _field("Réponse correcte", correctC),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final newCard = CardModel(
                id: card?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                type: "quiz",
                title: titleC.text,
                question: questionC.text,
                options: optionC.map((c) => c.text).toList(),
                correctAnswer: correctC.text.trim(),
              );

              if (card == null) {
                cards.add(newCard);
              } else {
                final index = cards.indexOf(card);
                cards[index] = newCard;
              }

              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  // ---------------------- EXERCISE EDITOR ----------------------
  void _openExerciseEditor(CardModel? card) async {
    final result = await showDialog<CardModel>(
      context: context,
      builder: (_) => ExerciseEditorDialog(cardToEdit: card, onSave: (CardModel p1) {  },),
    );

    if (result != null) {
      if (card == null) {
        cards.add(result);
      } else {
        final index = cards.indexOf(card);
        cards[index] = result;
      }
      setState(() {});
    }
  }

  // ---------------------- MAIN UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cours.title ?? "Cours")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTypePicker,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final c = cards[i];
          return Card(
            color: _getCardColor(c.type),
            child: ListTile(
              leading: Icon(_getIcon(c.type)),
              title: Text(c.title),
              subtitle: Text(c.question ?? c.content ?? ""),
              onTap: () => _editCard(c),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => cards.remove(c)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------- HELPERS ----------------------
  void _editCard(CardModel card) {
    switch (card.type) {
      case "lesson":
        _openLessonEditor(card);
        break;
      case "quiz":
        _openQuizEditor(card);
        break;
      case "exercise":
        _openExerciseEditor(card);
        break;
    }
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text("Ajouter une leçon"),
            onTap: () {
              Navigator.pop(context);
              _openLessonEditor(null);
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text("Ajouter un quiz"),
            onTap: () {
              Navigator.pop(context);
              _openQuizEditor(null);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text("Ajouter un exercice"),
            onTap: () {
              Navigator.pop(context);
              _openExerciseEditor(null);
            },
          ),
        ],
      ),
    );
  }

    Widget _field(String label, TextEditingController c, {int max = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: max,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

