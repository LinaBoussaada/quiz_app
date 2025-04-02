/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:quiz_app/quiz_created_screen.dart';

class CreateQuizScreen extends StatefulWidget {
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  List<String> _options = ["", "", "", ""];
  String? _correctAnswer;

  // Générer un ID aléatoire pour le quiz
  String _generateQuizId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  void _addQuestion() {
    if (_questionController.text.isNotEmpty && _correctAnswer != null) {
      setState(() {
        _questions.add({
          'question': _questionController.text,
          'options': List.from(_options), // ✅ Correction ici
          'answer': _correctAnswer,
        });

        // Réinitialisation des champs
        _questionController.clear();
        _options = ["", "", "", ""];
        _correctAnswer = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Question ajoutée !"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Complétez la question avant d'ajouter !"),
            backgroundColor: Colors.red),
      );
    }
  }

  final databaseRef = FirebaseDatabase.instance.ref(); // Référence à la DB
  void _saveQuiz() async {
    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please add a title and at least one question.")));
      return;
    }

    String quizId = _generateQuizId();

    await databaseRef.child('quizzes').child(quizId).set({
      'quizId': quizId,
      'title': _titleController.text,
      'questions': _questions,
      'players': {} // 🔥 Stockage des joueurs pour le mode multi
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCreatedScreen(quizId: quizId),
      ),
    );

    _titleController.clear();
    setState(() {
      _questions.clear();
    });
  }

  //hedhy zedtha ll realtime db version
  Future<void> joinQuiz(String quizId, String userId, String playerName) async {
    await FirebaseFirestore.instance.collection('quizzes').doc(quizId).update({
      'players.$userId': {'name': playerName, 'score': 0}
    });
  }

/*
  void _saveQuiz() async {
    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please add a title and at least one question.")));
      return;
    }

    String quizId = _generateQuizId();

    await FirebaseFirestore.instance.collection('quizzes').doc(quizId).set({
      'quizId': quizId,
      'title': _titleController.text,
      'questions': _questions,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizCreatedScreen(quizId: quizId), // ✅ Corrigé ici !
      ),
    );

    // Réinitialiser les champs après l'enregistrement
    _titleController.clear();
    setState(() {
      _questions.clear();
    });
  }*/

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Confirmer"),
            content: Text("Voulez-vous enregistrer ce quiz ?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Oui, enregistrer"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Créer un Quiz"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ pour le titre du quiz
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Titre du Quiz",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Divider(),

            // Liste des questions ajoutées
            Expanded(
              child: _questions.isEmpty
                  ? Center(
                      child: Text("Aucune question ajoutée",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(_questions[index]['question']),
                            subtitle: Text(
                                "Réponse correcte: ${_questions[index]['answer']}"),
                          ),
                        );
                      },
                    ),
            ),
            Divider(),

            // Champ pour ajouter une nouvelle question
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: "Entrer la question",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Options de réponse
            Column(
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _options[index] = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Option ${index + 1}",
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 10),

            // Sélection de la bonne réponse
            DropdownButtonFormField<String>(
              hint: Text("Choisissez la bonne réponse"),
              value: _correctAnswer,
              items:
                  _options.where((option) => option.isNotEmpty).map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _correctAnswer = value;
                });
              },
            ),

            SizedBox(height: 20),

            // Boutons d'ajout et de sauvegarde
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: Icon(Icons.add),
                  label: Text("Ajouter Question"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _saveQuiz,
                  icon: Icon(Icons.save),
                  label: Text("Enregistrer Quiz"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/loginScreen.dart';
import 'dart:math';
import 'package:quiz_app/quiz_created_screen.dart';

class CreateQuizScreen extends StatefulWidget {
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  List<String> _options = ["", "", "", ""];
  String? _correctAnswer;

  String _generateQuizId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  void _addQuestion() {
    if (_questionController.text.isNotEmpty && _correctAnswer != null) {
      setState(() {
        _questions.add({
          'question': _questionController.text,
          'options': List.from(_options),
          'answer': _correctAnswer,
        });
        _questionController.clear();
        _options = ["", "", "", ""];
        _correctAnswer = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Question ajoutée !"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Complétez la question avant d'ajouter !"),
            backgroundColor: Colors.red),
      );
    }
  }

  final databaseRef = FirebaseDatabase.instance.ref();

  void _saveQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Please add a title and at least one question.")),
      );
      return;
    }

    String quizId = _generateQuizId();
    await databaseRef.child('quizzes').child(quizId).set({
      'quizId': quizId,
      'title': _titleController.text,
      'questions': _questions,
      'creatorId': user.uid, // Store creator's UID
      'players': {}
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCreatedScreen(quizId: quizId),
      ),
    );

    _titleController.clear();
    setState(() {
      _questions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Créer un Quiz"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                  labelText: "Titre du Quiz", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            Divider(),
            Expanded(
              child: _questions.isEmpty
                  ? Center(
                      child: Text("Aucune question ajoutée",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(_questions[index]['question']),
                            subtitle: Text(
                                "Réponse correcte: ${_questions[index]['answer']}"),
                          ),
                        );
                      },
                    ),
            ),
            Divider(),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                  labelText: "Entrer la question",
                  border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            Column(
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _options[index] = value;
                      });
                    },
                    decoration: InputDecoration(
                        labelText: "Option ${index + 1}",
                        border: OutlineInputBorder()),
                  ),
                );
              }),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              hint: Text("Choisissez la bonne réponse"),
              value: _correctAnswer,
              items:
                  _options.where((option) => option.isNotEmpty).map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _correctAnswer = value;
                });
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: Icon(Icons.add),
                  label: Text("Ajouter Question"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _saveQuiz,
                  icon: Icon(Icons.save),
                  label: Text("Enregistrer Quiz"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
