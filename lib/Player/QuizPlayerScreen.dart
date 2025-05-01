import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PlayerScreen extends StatefulWidget {
  final String quizId;
  final String playerId;
  final String playerName;

  const PlayerScreen({
    Key? key,
    required this.quizId,
    required this.playerId,
    required this.playerName,
  }) : super(key: key);

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final DatabaseReference _quizRef;
  late final DatabaseReference _playerRef;
  bool _quizActive = false;
  int _currentQuestionIndex = 0;
  List<dynamic> _questions = [];
  int _remainingTime = 30;
  bool _timeExpired = false;
  bool _quizFinished = false;
  int? _selectedAnswerIndex;
  bool _answerSubmitted = false;
  int _playerScore = 0;

  @override
  void initState() {
    super.initState();
    _quizRef = FirebaseDatabase.instance.ref('quizzes/${widget.quizId}');
    _playerRef = _quizRef.child('players/${widget.playerId}');

    // Initialize player data
    _playerRef.set({
      'name': widget.playerName,
      'score': 0,
      'isCorrect': false,
      'lastAnswer': null,
    });

    _loadQuizData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    final snapshot = await _quizRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _questions = List<dynamic>.from(data['questions'] ?? []);
        _currentQuestionIndex =
            (data['currentQuestionIndex'] as num?)?.toInt() ?? 0;
        _quizActive = data['isActive'] ?? false;
        _remainingTime = _getCurrentQuestionTime();
      });
    }
  }

  int _getCurrentQuestionTime() {
    if (_currentQuestionIndex < _questions.length) {
      return _questions[_currentQuestionIndex]['time'] ?? 30;
    }
    return 30;
  }

  void _setupRealTimeUpdates() {
    _quizRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final newIndex = (data['currentQuestionIndex'] as num?)?.toInt() ?? 0;

        setState(() {
          _quizActive = data['isActive'] ?? false;
          _questions = List<dynamic>.from(data['questions'] ?? []);

          if (newIndex != _currentQuestionIndex) {
            _currentQuestionIndex = newIndex;
            _remainingTime = _getCurrentQuestionTime();
            _timeExpired = false;
            _selectedAnswerIndex = null;
            _answerSubmitted = false;
          }

          _quizFinished = _quizActive &&
              _currentQuestionIndex >= _questions.length - 1 &&
              _timeExpired;
        });
      }
    });

    // Listen to player's own data updates
    _playerRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _playerScore = (data['score'] as num?)?.toInt() ?? 0;
        });
      }
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswerIndex == null || _answerSubmitted) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswerIndex == currentQuestion['correctAnswer'];

    await _playerRef.update({
      'isCorrect': isCorrect,
      'lastAnswer': _selectedAnswerIndex,
      'score': isCorrect ? _playerScore + 1 : _playerScore,
    });

    setState(() {
      _answerSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz - ${widget.playerName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Score: $_playerScore',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_quizFinished)
                    const Text(
                      'QUIZ TERMINÉ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  else if (!_quizActive)
                    const Text(
                      'En attente du début du quiz...',
                      style: TextStyle(fontSize: 20),
                    )
                  else ...[
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Temps restant: $_remainingTime secondes',
                      style: TextStyle(
                        fontSize: 16,
                        color: _remainingTime <= 10 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_questions.isNotEmpty &&
                        _currentQuestionIndex < _questions.length)
                      Text(
                        _questions[_currentQuestionIndex]['question'],
                        style: const TextStyle(fontSize: 18),
                      ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          if (_quizActive &&
              !_quizFinished &&
              _currentQuestionIndex < _questions.length)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          _questions[_currentQuestionIndex]['answers'].length,
                      itemBuilder: (context, index) {
                        final answer =
                            _questions[_currentQuestionIndex]['answers'][index];
                        return Card(
                          color: _answerSubmitted
                              ? index ==
                                      _questions[_currentQuestionIndex]
                                          ['correctAnswer']
                                  ? Colors.green.withOpacity(0.3)
                                  : _selectedAnswerIndex == index
                                      ? Colors.red.withOpacity(0.3)
                                      : null
                              : _selectedAnswerIndex == index
                                  ? Colors.blue.withOpacity(0.3)
                                  : null,
                          child: ListTile(
                            title: Text(answer),
                            onTap: _answerSubmitted
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAnswerIndex = index;
                                    });
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed:
                          _answerSubmitted || _selectedAnswerIndex == null
                              ? null
                              : _submitAnswer,
                      child: Text(
                          _answerSubmitted ? 'Réponse envoyée' : 'Valider'),
                    ),
                  ),
                ],
              ),
            ),
          if (_quizFinished)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Votre score final:',
                      style: TextStyle(fontSize: 24),
                    ),
                    Text(
                      '$_playerScore / ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
