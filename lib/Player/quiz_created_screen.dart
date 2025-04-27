import 'package:flutter/material.dart';
import '../Creator/QuizAdminDashboard.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'QuizScreen.dart'; // Make sure to import your QuizScreen

class QuizCreatedScreen extends StatefulWidget {
  final String quizId;

  const QuizCreatedScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizCreatedScreenState createState() => _QuizCreatedScreenState();
}

class _QuizCreatedScreenState extends State<QuizCreatedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Created')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Quiz Code:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.quizId,
              style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startQuiz,
              child: const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  // Dans _QuizCreatedScreenState
  Future<void> _startQuiz() async {
    try {
      // Activer le quiz dans Firebase
      await FirebaseDatabase.instance.ref('quizzes/${widget.quizId}').update({
        'isActive': true,
        'currentQuestionIndex': 0,
      });

      // Rediriger vers le DASHBOARD ADMIN - PAS l'écran participant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizAdminDashboard(quizId: widget.quizId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
}
