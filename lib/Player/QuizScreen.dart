import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
//import 'package:quiz_app/SimpleQrCode.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  final bool isHost;
  final String? playerName;

  const QuizScreen({
    required this.quizId,
    this.isHost = false,
    this.playerName,
    Key? key,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _playerData = {};
  int _remainingTime = 0;
  Timer? _timer;
  bool _quizActive = false;
  bool _isAnswered = false;
  bool _quizFinished = false;
  int _finalScore = 0;
  StreamSubscription? _quizStateSubscription;

  @override
  void initState() {
    super.initState();
    _quizFinished = false;
    _loadQuizData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _quizStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(widget.quizId).get();

      if (snapshot.exists) {
        Map<String, dynamic> quizData =
            (snapshot.value as Map<Object?, Object?>).cast<String, dynamic>();

        setState(() {
          _questions = List<Map<String, dynamic>>.from(
            (quizData['questions'] as List)
                .map((q) => (q as Map).cast<String, dynamic>()),
          );
          _playerData = (quizData['players'] as Map<Object?, Object?>)
              .cast<String, dynamic>();
          _currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
          _quizActive = quizData['isActive'] ?? false;
          _quizFinished =
              !_quizActive && _currentQuestionIndex >= _questions.length - 1;
        });

        if (widget.isHost && !_quizActive && !_quizFinished) {
          await databaseRef.child('quizzes').child(widget.quizId).update({
            'currentQuestionIndex': 0,
            'isActive': false,
          });
        }
      }
    } catch (e) {
      print("Error loading quiz data: $e");
    }
  }

  void _setupRealTimeUpdates() {
    _quizStateSubscription = databaseRef
        .child('quizzes')
        .child(widget.quizId)
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        Map<String, dynamic> quizData =
            (event.snapshot.value as Map<Object?, Object?>)
                .cast<String, dynamic>();

        setState(() {
          _currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
          _quizActive = quizData['isActive'] ?? false;
          _playerData = (quizData['players'] as Map<Object?, Object?>)
              .cast<String, dynamic>();
          _quizFinished =
              !_quizActive && _currentQuestionIndex >= _questions.length - 1;
        });

        if (_quizActive && _questions.isNotEmpty && !_quizFinished) {
          _startQuestionTimer();
        }
      }
    });
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    _isAnswered = false;

    final questionTime = _questions[_currentQuestionIndex]['time'] ?? 15;
    setState(() {
      _remainingTime = questionTime;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        if (!_isAnswered && widget.isHost) {
          _nextQuestion();
        }
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _questions.length - 1) {
      await databaseRef.child('quizzes').child(widget.quizId).update({
        'currentQuestionIndex': _currentQuestionIndex + 1,
      });
    } else {
      await _endQuiz();
    }
  }

  Future<void> _startQuiz() async {
    await databaseRef.child('quizzes').child(widget.quizId).update({
      'isActive': true,
      'currentQuestionIndex': 0,
    });
    _startQuestionTimer();
  }

  Future<void> _endQuiz() async {
    await databaseRef.child('quizzes').child(widget.quizId).update({
      'isActive': false,
    });
  }

  void _submitAnswer(String selectedAnswer) {
    if (!_quizActive || _isAnswered || _quizFinished) return;

    _isAnswered = true;
    _timer?.cancel();

    if (_playerData.isEmpty) return;

    String currentPlayerId = _playerData.keys.first;
    String correctAnswer = _questions[_currentQuestionIndex]['answer'];
    bool isCorrect = selectedAnswer == correctAnswer;

    setState(() {
      if (isCorrect) {
        _playerData[currentPlayerId]['score'] =
            (_playerData[currentPlayerId]['score'] ?? 0) + 1;
      }
    });

    databaseRef
        .child('quizzes')
        .child(widget.quizId)
        .child('players')
        .child(currentPlayerId)
        .update({'score': _playerData[currentPlayerId]['score']});

    if (widget.isHost) {
      Future.delayed(const Duration(seconds: 2), () => _nextQuestion());
    }
  }

  Widget _buildWaitingScreen({bool isAfterQuiz = false}) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              isAfterQuiz
                  ? "Le quiz est terminé. Merci d'avoir participé!"
                  : "En attente du démarrage du quiz...",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            Text(
              "Code du quiz: ${widget.quizId}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isHost && !isAfterQuiz) ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _startQuiz,
                child: const Text("Démarrer le quiz"),
              ),
            ],
            if (isAfterQuiz) ...[
              const SizedBox(height: 30),
              Text(
                "Votre score final: ${_playerData[_playerData.keys.first]['score'] ?? 0}",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final options = List<String>.from(currentQuestion['options'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title:
            Text("Question ${_currentQuestionIndex + 1}/${_questions.length}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
            ),
            const SizedBox(height: 20),
            Text(
              "Temps restant: $_remainingTime secondes",
              style: TextStyle(
                fontSize: 16,
                color: _remainingTime <= 5 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentQuestion['question'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...options.map((option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ElevatedButton(
                    onPressed: _isAnswered ? null : () => _submitAnswer(option),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(option),
                  ),
                )),
            const SizedBox(height: 20),
            Text(
              "Score: ${_playerData[_playerData.keys.first]['score'] ?? 0}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // Dans votre build:
    // SimpleQrCode(data: "Votre texte ou code ici");
    if (!_quizActive || _quizFinished) {
      return _buildWaitingScreen(isAfterQuiz: _quizFinished);
    }

    return _buildQuizScreen();
  }
}
