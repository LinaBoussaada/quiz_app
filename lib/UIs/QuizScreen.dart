import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateQuizScreen extends StatefulWidget {
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final TextEditingController _quizTitleController = TextEditingController();
  final List<Map<String, TextEditingController>> _questionsControllers = [];

  final databaseRef = FirebaseDatabase.instance.ref();

  void _addQuestionField() {
    setState(() {
      _questionsControllers.add({
        'question': TextEditingController(),
        'option1': TextEditingController(),
        'option2': TextEditingController(),
        'option3': TextEditingController(),
        'option4': TextEditingController(),
        'answer': TextEditingController(),
        'maxTime': TextEditingController(),
      });
    });
  }

  Future<void> _createQuiz() async {
    String title = _quizTitleController.text.trim();
    if (title.isEmpty || _questionsControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez saisir un titre et au moins une questionnnnnnnnnnnnn.")),
      );
      return;
    }

    DatabaseReference quizRef = databaseRef.child('quizzes').push();
    String quizId = quizRef.key!;

    Map<String, dynamic> questionsData = {};
    for (int i = 0; i < _questionsControllers.length; i++) {
      final controllers = _questionsControllers[i];

      int? maxTime = int.tryParse(controllers['maxTime']!.text);
      if (maxTime == null || maxTime <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Veuillez entrer un temps valide pour la question ${i + 1}.")),
        );
        return;
      }

      questionsData['q$i'] = {
        'question': controllers['question']!.text,
        'options': [
          controllers['option1']!.text,
          controllers['option2']!.text,
          controllers['option3']!.text,
          controllers['option4']!.text,
        ],
        'answer': controllers['answer']!.text,
        'maxTime': maxTime,
      };
    }

    await quizRef.set({
      'title': title,
      'questions': questionsData,
      'players': {}, // Initialisé vide
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Quiz créé avec succès !")),
    );

    // Réinitialiser les champs
    _quizTitleController.clear();
    _questionsControllers.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer un Quiz")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _quizTitleController,
              decoration: InputDecoration(labelText: 'Titre du quiz'),
            ),
            SizedBox(height: 20),

            ..._questionsControllers.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, TextEditingController> controllers = entry.value;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Question ${index + 1}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 10),
                      TextField(
                        controller: controllers['question'],
                        decoration: InputDecoration(labelText: 'Intitulé de la question'),
                      ),
                      TextField(
                        controller: controllers['option1'],
                        decoration: InputDecoration(labelText: 'Option 1'),
                      ),
                      TextField(
                        controller: controllers['option2'],
                        decoration: InputDecoration(labelText: 'Option 2'),
                      ),
                      TextField(
                        controller: controllers['option3'],
                        decoration: InputDecoration(labelText: 'Option 3'),
                      ),
                      TextField(
                        controller: controllers['option4'],
                        decoration: InputDecoration(labelText: 'Option 4'),
                      ),
                      TextField(
                        controller: controllers['answer'],
                        decoration: InputDecoration(labelText: 'Bonne réponse'),
                      ),
                      TextField(
                        controller: controllers['maxTime'],
                        decoration: InputDecoration(labelText: 'Temps max (en secondes)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addQuestionField,
              child: Text("Ajouter une question"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createQuiz,
              child: Text("Créer le Quiz"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
