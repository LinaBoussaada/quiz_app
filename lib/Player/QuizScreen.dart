import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  final bool isHost;
  final String? playerName;
  final String? playerAvatar;
  final String? playerId;

  const QuizScreen({
    required this.quizId,
    this.isHost = false,
    this.playerName,
    this.playerAvatar,
    this.playerId,
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
  String? _currentPlayerId;
  StreamSubscription? _quizStateSubscription;
  List<Map<String, dynamic>> _topPlayers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _quizFinished = false;
    _currentPlayerId = widget.playerId;
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(widget.quizId).get();

      if (!mounted) return;

      if (snapshot.exists) {
        Map<String, dynamic> quizData =
            (snapshot.value as Map<Object?, Object?>).cast<String, dynamic>();

        setState(() {
          _questions = List<Map<String, dynamic>>.from(
            (quizData['questions'] as List? ?? [])
                .map((q) => (q as Map).cast<String, dynamic>()),
          );

          if (quizData.containsKey('players') && quizData['players'] != null) {
            _playerData = (quizData['players'] as Map<Object?, Object?>)
                .cast<String, dynamic>();
          } else {
            _playerData = {};
          }

          if (!widget.isHost && _currentPlayerId != null) {
            if (!_playerData.containsKey(_currentPlayerId)) {
              _addPlayerToDatabase();
            }
          }

          _currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
          _quizActive = quizData['isActive'] ?? false;
          _quizFinished =
              !_quizActive && _currentQuestionIndex >= _questions.length - 1;

          _updateTopPlayers();
          _isLoading = false;
        });

        if (_quizActive && !_quizFinished) {
          _startQuestionTimer();
        }
      } else {
        setState(() {
          _errorMessage = "Quiz not found. Check quiz ID and try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading quiz data: $e");
      setState(() {
        _errorMessage = "Failed to load quiz: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _addPlayerToDatabase() async {
    if (_currentPlayerId == null) return;

    _playerData[_currentPlayerId!] = {
      'name': widget.playerName ?? 'Player',
      'score': 0,
      'avatar': widget.playerAvatar ?? 'avatar1',
    };

    try {
      await databaseRef
          .child('quizzes')
          .child(widget.quizId)
          .child('players')
          .child(_currentPlayerId!)
          .set({
        'name': widget.playerName ?? 'Player',
        'score': 0,
        'avatar': widget.playerAvatar ?? 'avatar1',
      });
    } catch (e) {
      print("Error adding player to database: $e");
    }
  }

  void _setupRealTimeUpdates() {
    _quizStateSubscription = databaseRef
        .child('quizzes')
        .child(widget.quizId)
        .onValue
        .listen((event) {
      if (!mounted) return;

      if (event.snapshot.exists) {
        try {
          Map<String, dynamic> quizData =
              (event.snapshot.value as Map<Object?, Object?>)
                  .cast<String, dynamic>();

          setState(() {
            _currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
            _quizActive = quizData['isActive'] ?? false;

            if (quizData.containsKey('players') && quizData['players'] != null) {
              _playerData = (quizData['players'] as Map<Object?, Object?>)
                  .cast<String, dynamic>();
            }

            _checkIfQuestionAnswered();

            _quizFinished =
                !_quizActive && _currentQuestionIndex >= _questions.length - 1;

            _updateTopPlayers();
          });

          if (_quizActive && !_quizFinished) {
            _startQuestionTimer();
          } else {
            _timer?.cancel();
          }
        } catch (e) {
          print("Error processing quiz update: $e");
        }
      }
    }, onError: (error) {
      print("Error in real-time updates: $error");
      setState(() {
        _errorMessage = "Connection error. Please try again.";
      });
    });
  }

  void _checkIfQuestionAnswered() {
    if (_currentPlayerId == null || _questions.isEmpty) return;

    _isAnswered = false;

    databaseRef
        .child('quizzes')
        .child(widget.quizId)
        .child('responses')
        .child(_currentQuestionIndex.toString())
        .child(_currentPlayerId!)
        .get()
        .then((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _isAnswered = true;
        });
      }
    });
  }

  void _updateTopPlayers() {
    List<Map<String, dynamic>> players = [];
    _playerData.forEach((id, data) {
      if (data is Map) {
        players.add({
          'id': id,
          'name': data['name'] ?? 'Unknown',
          'score': data['score'] ?? 0,
          'avatar': data['avatar'] ?? 'avatar1',
        });
      }
    });

    players.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    _topPlayers = players.take(5).toList();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    _isAnswered = false;

    if (_quizActive &&
        _questions.isNotEmpty &&
        _currentQuestionIndex < _questions.length) {
      final questionTime = _questions[_currentQuestionIndex]['time'] ?? 15;
      setState(() {
        _remainingTime = questionTime;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            timer.cancel();
            if (!_isAnswered && widget.isHost) {
              _nextQuestion();
            }
          }
        });
      });
    }
  }

  Future<void> _nextQuestion() async {
    _timer?.cancel();
    if (_currentQuestionIndex < _questions.length - 1) {
      await databaseRef.child('quizzes').child(widget.quizId).update({
        'currentQuestionIndex': _currentQuestionIndex + 1,
        'isActive': true,
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
  }

  Future<void> _endQuiz() async {
    await databaseRef.child('quizzes').child(widget.quizId).update({
      'isActive': false,
    });
  }

  Future<void> _submitAnswer(String selectedAnswer) async {
    if (!_quizActive || _isAnswered || _quizFinished || _currentPlayerId == null) {
      return;
    }

    setState(() {
      _isAnswered = true;
    });

    String correctAnswer = _questions[_currentQuestionIndex]['answer'];
    bool isCorrect = selectedAnswer == correctAnswer;

    try {
      if (isCorrect) {
        int scoreToAdd = 1000 + (_remainingTime * 100);

        if (_playerData.containsKey(_currentPlayerId)) {
          setState(() {
            _playerData[_currentPlayerId!]['score'] =
                (_playerData[_currentPlayerId!]['score'] ?? 0) + scoreToAdd;
          });

          await databaseRef
              .child('quizzes')
              .child(widget.quizId)
              .child('players')
              .child(_currentPlayerId!)
              .update({'score': _playerData[_currentPlayerId!]['score']});
        }
      }

      await databaseRef
          .child('quizzes')
          .child(widget.quizId)
          .child('responses')
          .child(_currentQuestionIndex.toString())
          .child(_currentPlayerId!)
          .set({
        'answer': selectedAnswer,
        'correct': isCorrect,
        'timeSpent': _questions[_currentQuestionIndex]['time'] - _remainingTime,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? 'Correct!' : 'Sorry, incorrect!'),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.isHost) {
        Future.delayed(const Duration(seconds: 5), () {
          _nextQuestion();
        });
      }
    } catch (e) {
      print('Error submitting answer: $e');
      setState(() {
        _isAnswered = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit your answer. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlayerList() {
    if (_topPlayers.isEmpty) {
      return const Center(
        child: Text('No players yet',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView(
        children: _topPlayers.map((player) {
          final bool isCurrentPlayer = player['id'] == _currentPlayerId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  AssetImage('assets/images/avatars/${player['avatar']}.jpeg'),
            ),
            title: Text(
              player['name'],
              style: TextStyle(
                fontWeight:
                    isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                color: isCurrentPlayer ? Theme.of(context).primaryColor : null,
              ),
            ),
            trailing: Text(
              '${player['score']} pts',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuestionIndex >= _questions.length) {
      return const Center(child: Text('No more questions available'));
    }

    final question = _questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] ?? []);

    return Column(
      children: [
        LinearProgressIndicator(
          value: _remainingTime / (question['time'] ?? 15),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _remainingTime < 5 ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Time: $_remainingTime/${question['time'] ?? 15}s',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 10),
                Text(
                  question['question'] ?? 'No question text',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (options.isEmpty)
                  const Text('No options available',
                      style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ...options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: (_isAnswered || !_quizActive)
                            ? null
                            : () => _submitAnswer(option),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(option, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                if (_isAnswered)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Answer submitted. Waiting for next question...',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.people, size: 60, color: Colors.blue),
                    const SizedBox(height: 20),
                    Text(
                      'Waiting for quiz to start',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Quiz code: ${widget.quizId}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    if (widget.playerName != null)
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(
                                'assets/images/avatars/${widget.playerAvatar ?? 'avatar1'}.jpeg'),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Ready, ${widget.playerName}!',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    const Text(
                      'Waiting players:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: _playerData.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No players yet',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _playerData.length,
                              itemBuilder: (context, index) {
                                final playerId =
                                    _playerData.keys.elementAt(index);
                                final player = _playerData[playerId];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/images/avatars/${player['avatar'] ?? 'avatar1'}.jpeg'),
                                  ),
                                  title: Text(player['name'] ?? 'Player'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isHost) _buildHostControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizFinishedView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Quiz Finished!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Final Ranking',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_topPlayers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No participants',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ..._topPlayers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final player = entry.value;
                        final isCurrent = player['id'] == _currentPlayerId;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isCurrent
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage(
                                  'assets/images/avatars/${player['avatar']}.jpeg'),
                            ),
                            title: Text(
                              player['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                            subtitle: Text('${player['score']} points'),
                            trailing: idx < 3
                                ? Icon(
                                    Icons.emoji_events,
                                    color: [
                                      Colors.amber,
                                      Colors.grey,
                                      Colors.brown
                                    ][idx],
                                  )
                                : Text(
                                    '#${idx + 1}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        );
                      }),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isHost
                              ? 'Back to dashboard'
                              : 'Leave quiz',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          if (!_quizActive && !_quizFinished)
            ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Quiz',
                style: TextStyle(fontSize: 16),
              ),
            ),
          if (_quizActive)
            Column(
              children: [
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Next Question',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _endQuiz,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'End Quiz',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadQuizData,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading quiz...',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuizView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _remainingTime < 5
                      ? Colors.red.withOpacity(0.2)
                      : Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: _remainingTime < 5
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_remainingTime/${_questions[_currentQuestionIndex]['time'] ?? 15}s',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _remainingTime < 5
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_currentPlayerId != null &&
                  _playerData.containsKey(_currentPlayerId))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_playerData[_currentPlayerId!]['score']} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          _questions[_currentQuestionIndex]['question'] ??
                              'Question',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ...List.generate(
                          _questions[_currentQuestionIndex]['options'].length,
                          (index) {
                            final option = _questions[_currentQuestionIndex]
                                ['options'][index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton(
                                onPressed: (_isAnswered || !_quizActive)
                                    ? null
                                    : () => _submitAnswer(option),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: _isAnswered
                                      ? (option ==
                                              _questions[_currentQuestionIndex]
                                                  ['answer']
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2))
                                      : Theme.of(context).primaryColor,
                                  foregroundColor: _isAnswered
                                      ? (option ==
                                              _questions[_currentQuestionIndex]
                                                  ['answer']
                                          ? Colors.green
                                          : Colors.red)
                                      : Colors.white,
                                  disabledBackgroundColor: Colors.grey[200],
                                  disabledForegroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_isAnswered)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              'Answer submitted. Waiting for next question...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_topPlayers.isNotEmpty)
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Ranking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._topPlayers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final player = entry.value;
                            final isCurrent = player['id'] == _currentPlayerId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2)
                                      : Colors.grey[200],
                                  backgroundImage: AssetImage(
                                      'assets/images/avatars/${player['avatar']}.jpeg'),
                                ),
                                title: Text(
                                  player['name'],
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                ),
                                trailing: Text(
                                  '${player['score']} pts',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor: isCurrent
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.05)
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.isHost) _buildHostControls(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Live',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: !_quizActive,
        actions: [
          if (!widget.isHost && !_quizActive)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Leave',
              onPressed: () => Navigator.pop(context),
            ),
        ],
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor.withOpacity(0.05),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: _isLoading
              ? _buildLoadingView()
              : _errorMessage != null
                  ? _buildErrorView()
                  : _quizFinished
                      ? _buildQuizFinishedView()
                      : (_quizActive
                          ? _buildActiveQuizView()
                          : _buildLobbyView()),
        ),
      ),
    );
  }
}