import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;

  QuizScreen({required this.quizId}) {
    print("QuizScreen initialized with quizId: $quizId");
  }

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _playerData = {};

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    print("Fetching quiz data for quizId: ${widget.quizId}");
    try {
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(widget.quizId).get();

      if (snapshot.exists && snapshot.value is Map<Object?, Object?>) {
        Map<String, dynamic> quizData =
            (snapshot.value as Map<Object?, Object?>).cast<String, dynamic>();

        print("Raw quizData: $quizData");

        if (quizData.containsKey('questions') &&
            quizData['questions'] is List) {
          setState(() {
            _questions = List<Map<String, dynamic>>.from(
                (quizData['questions'] as List).map((q) =>
                    q is Map<Object?, Object?>
                        ? q.cast<String, dynamic>()
                        : {}));
          });
        } else {
          print("No valid questions found in quiz data!");
        }

        if (quizData.containsKey('players') && quizData['players'] is Map) {
          setState(() {
            _playerData = (quizData['players'] as Map<Object?, Object?>)
                .cast<String, dynamic>();
          });
        } else {
          print("No players data found!");
        }
      } else {
        print("No quiz data found for quizId: ${widget.quizId}");
      }
    } catch (e) {
      print("Error loading quiz data: $e");
    }
  }

  void _submitAnswer(String selectedAnswer) {
    String currentPlayerId = _playerData.keys.first;
    String correctAnswer = _questions[_currentQuestionIndex]['answer'];

    if (selectedAnswer == correctAnswer) {
      _playerData[currentPlayerId]['score'] += 1;
    }

    databaseRef
        .child('quizzes')
        .child(widget.quizId)
        .child('players')
        .child(currentPlayerId)
        .update({'score': _playerData[currentPlayerId]['score']});

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Quiz Completed"),
          content: Text("Your score: ${_playerData[currentPlayerId]['score']}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic> currentQuestion = _questions[_currentQuestionIndex];
    List<String> options = List<String>.from(currentQuestion['options'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text("Quiz: ${widget.quizId}")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${_currentQuestionIndex + 1}: ${currentQuestion['question']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...options.map((option) {
              return ElevatedButton(
                onPressed: () => _submitAnswer(option),
                child: Text(option),
              );
            }).toList(),
            SizedBox(height: 20),
            Text(
                "Score: ${_playerData.isNotEmpty ? _playerData[_playerData.keys.first]['score'] : 0}"),
          ],
        ),
      ),
    );
  }
}
