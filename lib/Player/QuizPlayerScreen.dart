import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class QuizAdminDashboard extends StatefulWidget {
  final String quizId;

  const QuizAdminDashboard({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizAdminDashboardState createState() => _QuizAdminDashboardState();
}

class _QuizAdminDashboardState extends State<QuizAdminDashboard> {
  late final DatabaseReference _quizRef;
  Map<String, dynamic> _players = {};
  bool _quizActive = false;
  int _currentQuestionIndex = 0;
  List<dynamic> _questions = [];
  Timer? _questionTimer;
  int _remainingTime = 30;
  bool _timeExpired = false;
  bool _quizFinished = false;
  DateTime? _questionStartTime;

  @override
  void initState() {
    _quizRef = FirebaseDatabase.instance.ref('quizzes/${widget.quizId}');
    super.initState();
    _loadQuizData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
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

        if (_quizActive) {
          _startQuestionTimer();
        }
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
          _players = Map<String, dynamic>.from(data['players'] ?? {});
          _quizActive = data['isActive'] ?? false;
          _questions = List<dynamic>.from(data['questions'] ?? []);

          if (newIndex != _currentQuestionIndex) {
            _currentQuestionIndex = newIndex;
            _remainingTime = _getCurrentQuestionTime();
            _timeExpired = false;
            if (_quizActive) {
              _startQuestionTimer();
            }
          }

          _quizFinished = _quizActive &&
              _currentQuestionIndex >= _questions.length - 1 &&
              _timeExpired;
        });
      }
    });
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _timeExpired = false;
    _questionStartTime = DateTime.now();

    setState(() {
      _remainingTime = _getCurrentQuestionTime();
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final elapsedSeconds = now.difference(_questionStartTime!).inSeconds;
      final totalTime = _getCurrentQuestionTime();

      setState(() {
        _remainingTime = totalTime - elapsedSeconds;

        if (_remainingTime <= 0) {
          _remainingTime = 0;
          _timeExpired = true;
          timer.cancel();
          _nextQuestion();
        }
      });
    });
  }

  Future<void> _startQuiz() async {
    await _quizRef.update({
      'isActive': true,
      'currentQuestionIndex': 0,
      'players': {},
    });
    _startQuestionTimer();
  }

  Future<void> _nextQuestion() async {
    _questionTimer?.cancel();

    if (_currentQuestionIndex < _questions.length - 1) {
      await _quizRef.update({
        'currentQuestionIndex': _currentQuestionIndex + 1,
      });
    } else {
      await _endQuiz();
    }
  }

  Future<void> _endQuiz() async {
    _questionTimer?.cancel();
    await _quizRef.update({
      'isActive': false,
    });
    setState(() {
      _quizFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _quizFinished
          ? null
          : FloatingActionButton(
              onPressed: _quizActive ? null : _startQuiz,
              child: const Icon(Icons.play_arrow),
              tooltip: 'Démarrer le quiz',
            ),
      appBar: AppBar(
        title: const Text("Tableau de contrôle"),
        actions: [
          if (_quizActive && !_quizFinished)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _endQuiz,
              tooltip: 'Terminer le quiz',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_quizActive && !_quizFinished)
                          ElevatedButton(
                            onPressed: _startQuiz,
                            child: const Text('Démarrer le Quiz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        if (_quizActive && !_timeExpired && !_quizFinished)
                          ElevatedButton(
                            onPressed: _nextQuestion,
                            child: const Text('Passer à la suivante'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Participants',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _players.isEmpty
                      ? const Center(child: Text("Aucun participant"))
                      : ListView.builder(
                          itemCount: _players.length,
                          itemBuilder: (context, index) {
                            final playerId = _players.keys.elementAt(index);
                            final player = _players[playerId];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text((index + 1).toString()),
                              ),
                              title: Text(player['name'] ?? 'Anonyme'),
                              subtitle: Text('Score: ${player['score'] ?? 0}'),
                              trailing: _quizActive && _questions.isNotEmpty
                                  ? Icon(
                                      player['isCorrect'] == true
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: player['isCorrect'] == true
                                          ? Colors.green
                                          : Colors.grey,
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
