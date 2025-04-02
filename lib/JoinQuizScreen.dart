import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/QuizScreen.dart';

class JoinQuizScreen extends StatefulWidget {
  @override
  _JoinQuizScreenState createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final TextEditingController _quizCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();

  final databaseRef =
      FirebaseDatabase.instance.ref(); // Référence à la Realtime Database

  Future<void> _joinQuiz() async {
    String quizId = _quizCodeController.text.trim();
    String playerName = _playerNameController.text.trim();

    // Générer un identifiant unique pour le joueur (si pas d'authentification)
    String userId = DateTime.now().millisecondsSinceEpoch.toString();

    if (quizId.isEmpty || playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please enter both quiz code and your name."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      // Vérifier si le quiz existe dans la Realtime Database
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(quizId).get();

      if (snapshot.exists) {
        // Ajouter le joueur au quiz
        await joinQuiz(quizId, userId, playerName);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Joined the quiz successfully!"),
          backgroundColor: Colors.green,
        ));

        // Naviguer vers l'écran du quiz
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizScreen(quizId: quizId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Quiz not found."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error joining quiz: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> joinQuiz(String quizId, String userId, String playerName) async {
    final DatabaseReference quizRef =
        FirebaseDatabase.instance.ref('quizzes/$quizId');

    final snapshot = await quizRef.get();
    if (!snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz not found!"), backgroundColor: Colors.red),
      );
      return;
    }

    // Ajouter le joueur à la liste des participants
    await quizRef.child('players').child(userId).set({
      'name': playerName,
      'score': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join a Quiz")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _quizCodeController,
              decoration: InputDecoration(
                labelText: "Enter Quiz Code",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: "Enter Your Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinQuiz,
              child: Text("Join Quiz"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
