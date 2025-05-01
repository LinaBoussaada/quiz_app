import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
/*
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

          // If we're not the host and we have an ID, focus on our player data
          if (!widget.isHost && _currentPlayerId != null) {
            // Make sure this player is in the database
            if (!_playerData.containsKey(_currentPlayerId)) {
              _addPlayerToDatabase();
            }
          }

          _currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
          _quizActive = quizData['isActive'] ?? false;
          _quizFinished =
              !_quizActive && _currentQuestionIndex >= _questions.length - 1;

          // Update top players
          _updateTopPlayers();
          _isLoading = false;
        });

        if (widget.isHost && !_quizActive && !_quizFinished) {
          await databaseRef.child('quizzes').child(widget.quizId).update({
            'currentQuestionIndex': 0,
            'isActive': false,
          });
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

    // Add player to player data locally
    _playerData[_currentPlayerId!] = {
      'name': widget.playerName ?? 'Player',
      'score': 0,
      'avatar': widget.playerAvatar ?? 'avatar1',
    };

    // Update the database
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

            if (quizData.containsKey('players') &&
                quizData['players'] != null) {
              _playerData = (quizData['players'] as Map<Object?, Object?>)
                  .cast<String, dynamic>();
            }

            // Check if this question has been answered by the current player
            _checkIfQuestionAnswered();

            _quizFinished =
                !_quizActive && _currentQuestionIndex >= _questions.length - 1;

            // Update top players
            _updateTopPlayers();
          });

          if (_quizActive && _questions.isNotEmpty && !_quizFinished) {
            _startQuestionTimer();
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

    // Reset answered state for new questions
    _isAnswered = false;

    // Try to fetch existing responses from database to check if player already answered
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
    // Convert player data to a list and sort by score
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

    // Sort by score (descending)
    players.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Take top 5
    _topPlayers = players.take(5).toList();
  }

  void _startQuestionTimer() {
    _timer?.cancel();

    // Don't reset _isAnswered here - it's handled in _checkIfQuestionAnswered

    // Only start timer if we're not already in a question and the quiz is active
    if (_quizActive &&
        _questions.isNotEmpty &&
        _currentQuestionIndex < _questions.length) {
      final questionTime = _questions[_currentQuestionIndex]['time'] ?? 15;
      setState(() {
        _remainingTime = questionTime;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0 && mounted) {
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
  }

  Future<void> _nextQuestion() async {
    _timer?.cancel();
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
  }

  Future<void> _endQuiz() async {
    await databaseRef.child('quizzes').child(widget.quizId).update({
      'isActive': false,
    });
  }

  Future<void> _submitAnswer(String selectedAnswer) async {
    // Debug info
    print('Submit answer attempt: $selectedAnswer');
    print('Quiz active: $_quizActive');
    print('Is answered: $_isAnswered');
    print('Quiz finished: $_quizFinished');
    print('Current player ID: $_currentPlayerId');

    if (!_quizActive) {
      print('Cannot submit: quiz not active');
      return;
    }

    if (_isAnswered) {
      print('Cannot submit: already answered');
      return;
    }

    if (_quizFinished) {
      print('Cannot submit: quiz finished');
      return;
    }

    if (_currentPlayerId == null) {
      print('Cannot submit: no player ID');
      return;
    }

    // Set answered flag immediately to prevent double submissions
    setState(() {
      _isAnswered = true;
    });

    // Get the current question and check if the answer is correct
    if (_currentQuestionIndex >= _questions.length) {
      print('Question index out of bounds');
      return;
    }

    String correctAnswer = _questions[_currentQuestionIndex]['answer'];
    bool isCorrect = selectedAnswer == correctAnswer;

    try {
      // Calculate score if answer is correct
      if (isCorrect) {
        // Calculate score based on remaining time (more time = more points)
        int scoreToAdd = 1000 + (_remainingTime * 100);

        // Update local player data
        if (_playerData.containsKey(_currentPlayerId)) {
          setState(() {
            _playerData[_currentPlayerId!]['score'] =
                (_playerData[_currentPlayerId!]['score'] ?? 0) + scoreToAdd;
          });

          // Update the score in the database
          await databaseRef
              .child('quizzes')
              .child(widget.quizId)
              .child('players')
              .child(_currentPlayerId!)
              .update({'score': _playerData[_currentPlayerId!]['score']});
        }
      }

      // Record player's answer for this question
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

      // Show feedback on the UI (correct/incorrect)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? 'Correct!' : 'Sorry, incorrect!'),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // If we're the host, move to the next question after a delay
      if (widget.isHost) {
        Future.delayed(Duration(seconds: 5), () {
          _nextQuestion();
        });
      }
    } catch (e) {
      print('Error submitting answer: $e');
      // Reset answer state on error so player can try again
      setState(() {
        _isAnswered = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit your answer. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlayerList() {
    if (_topPlayers.isEmpty) {
      return Center(
        child: Text('No players yet',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
      );
    }

    return Container(
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
              style: TextStyle(
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
      return Center(child: CircularProgressIndicator());
    }

    if (_currentQuestionIndex >= _questions.length) {
      return Center(child: Text('No more questions available'));
    }

    final question = _questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] ?? []);

    return Column(
      children: [
        // Timer indicator
        LinearProgressIndicator(
          value: _remainingTime / (question['time'] ?? 15),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _remainingTime < 5 ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Time: $_remainingTime',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        // Question
        Card(
          elevation: 4,
          margin: EdgeInsets.all(10),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 10),
                Text(
                  question['question'] ?? 'No question text',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Answer options
                if (options.isEmpty)
                  Text('No options available',
                      style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ...options.map((option) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: (_isAnswered || !_quizActive)
                            ? null
                            : () => _submitAnswer(option),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(option, style: TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                if (_isAnswered)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
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

  Widget _buildQuizFinishedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Final Standings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildPlayerList(),
          SizedBox(height: 30),
          if (widget.isHost)
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Exit Quiz'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHostControls() {
    if (!widget.isHost) return SizedBox();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (!_quizActive && !_quizFinished)
            ElevatedButton(
              onPressed: _startQuiz,
              child: Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),
          if (_quizActive)
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text('Skip to Next Question'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.orange,
              ),
            ),
          if (_quizActive)
            ElevatedButton(
              onPressed: _endQuiz,
              child: Text('End Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLobbyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Waiting for quiz to start...',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          'Quiz ID: ${widget.quizId}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 30),
        Text(
          'Players in Lobby:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        _buildPlayerList(),
        SizedBox(height: 20),
        if (widget.isHost) _buildHostControls(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Error',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              _loadQuizData();
            },
            child: Text('Retry'),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Quiz'),
        automaticallyImplyLeading: !_quizActive,
        actions: [
          if (!widget.isHost && !_quizActive)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading quiz...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? _buildErrorView()
                : _quizFinished
                    ? _buildQuizFinishedView()
                    : (_quizActive
                        ? Column(
                            children: [
                              Expanded(child: _buildQuestionCard()),
                              if (widget.isHost) _buildHostControls(),
                            ],
                          )
                        : _buildLobbyView()),
      ),
    );
  }
}
*/

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

          // If we're not the host and we have an ID, focus on our player data
          if (!widget.isHost && _currentPlayerId != null) {
            // Make sure this player is in the database
            if (!_playerData.containsKey(_currentPlayerId)) {
              _addPlayerToDatabase();
            }
          }

          _currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
          _quizActive = quizData['isActive'] ?? false;
          _quizFinished =
              !_quizActive && _currentQuestionIndex >= _questions.length - 1;

          // Update top players
          _updateTopPlayers();
          _isLoading = false;
        });

        if (widget.isHost && !_quizActive && !_quizFinished) {
          await databaseRef.child('quizzes').child(widget.quizId).update({
            'currentQuestionIndex': 0,
            'isActive': false,
          });
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

    // Add player to player data locally
    _playerData[_currentPlayerId!] = {
      'name': widget.playerName ?? 'Player',
      'score': 0,
      'avatar': widget.playerAvatar ?? 'avatar1',
    };

    // Update the database
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

            if (quizData.containsKey('players') &&
                quizData['players'] != null) {
              _playerData = (quizData['players'] as Map<Object?, Object?>)
                  .cast<String, dynamic>();
            }

            // Check if this question has been answered by the current player
            _checkIfQuestionAnswered();

            _quizFinished =
                !_quizActive && _currentQuestionIndex >= _questions.length - 1;

            // Update top players
            _updateTopPlayers();
          });

          if (_quizActive && _questions.isNotEmpty && !_quizFinished) {
            _startQuestionTimer();
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

    // Reset answered state for new questions
    _isAnswered = false;

    // Try to fetch existing responses from database to check if player already answered
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
    // Convert player data to a list and sort by score
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

    // Sort by score (descending)
    players.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Take top 5
    _topPlayers = players.take(5).toList();
  }

  void _startQuestionTimer() {
    _timer?.cancel();

    // Don't reset _isAnswered here - it's handled in _checkIfQuestionAnswered

    // Only start timer if we're not already in a question and the quiz is active
    if (_quizActive &&
        _questions.isNotEmpty &&
        _currentQuestionIndex < _questions.length) {
      final questionTime = _questions[_currentQuestionIndex]['time'] ?? 15;
      setState(() {
        _remainingTime = questionTime;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0 && mounted) {
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
  }

  Future<void> _nextQuestion() async {
    _timer?.cancel();
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
  }

  Future<void> _endQuiz() async {
    await databaseRef.child('quizzes').child(widget.quizId).update({
      'isActive': false,
    });
  }

  Future<void> _submitAnswer(String selectedAnswer) async {
    // Debug info
    print('Submit answer attempt: $selectedAnswer');
    print('Quiz active: $_quizActive');
    print('Is answered: $_isAnswered');
    print('Quiz finished: $_quizFinished');
    print('Current player ID: $_currentPlayerId');

    if (!_quizActive) {
      print('Cannot submit: quiz not active');
      return;
    }

    if (_isAnswered) {
      print('Cannot submit: already answered');
      return;
    }

    if (_quizFinished) {
      print('Cannot submit: quiz finished');
      return;
    }

    if (_currentPlayerId == null) {
      print('Cannot submit: no player ID');
      return;
    }

    // Set answered flag immediately to prevent double submissions
    setState(() {
      _isAnswered = true;
    });

    // Get the current question and check if the answer is correct
    if (_currentQuestionIndex >= _questions.length) {
      print('Question index out of bounds');
      return;
    }

    String correctAnswer = _questions[_currentQuestionIndex]['answer'];
    bool isCorrect = selectedAnswer == correctAnswer;

    try {
      // Calculate score if answer is correct
      if (isCorrect) {
        // Calculate score based on remaining time (more time = more points)
        int scoreToAdd = 1000 + (_remainingTime * 100);

        // Update local player data
        if (_playerData.containsKey(_currentPlayerId)) {
          setState(() {
            _playerData[_currentPlayerId!]['score'] =
                (_playerData[_currentPlayerId!]['score'] ?? 0) + scoreToAdd;
          });

          // Update the score in the database
          await databaseRef
              .child('quizzes')
              .child(widget.quizId)
              .child('players')
              .child(_currentPlayerId!)
              .update({'score': _playerData[_currentPlayerId!]['score']});
        }
      }

      // Record player's answer for this question
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

      // Show feedback on the UI (correct/incorrect)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCorrect ? 'Correct!' : 'Sorry, incorrect!'),
          backgroundColor: isCorrect ? Colors.green : Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // If we're the host, move to the next question after a delay
      if (widget.isHost) {
        Future.delayed(Duration(seconds: 5), () {
          _nextQuestion();
        });
      }
    } catch (e) {
      print('Error submitting answer: $e');
      // Reset answer state on error so player can try again
      setState(() {
        _isAnswered = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit your answer. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlayerList() {
    if (_topPlayers.isEmpty) {
      return Center(
        child: Text('No players yet',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
      );
    }

    return Container(
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
              style: TextStyle(
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
      return Center(child: CircularProgressIndicator());
    }

    if (_currentQuestionIndex >= _questions.length) {
      return Center(child: Text('No more questions available'));
    }

    final question = _questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] ?? []);

    return Column(
      children: [
        // Timer indicator
        LinearProgressIndicator(
          value: _remainingTime / (question['time'] ?? 15),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _remainingTime < 5 ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Time: $_remainingTime',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        // Question
        Card(
          elevation: 4,
          margin: EdgeInsets.all(10),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 10),
                Text(
                  question['question'] ?? 'No question text',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Answer options
                if (options.isEmpty)
                  Text('No options available',
                      style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ...options.map((option) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: (_isAnswered || !_quizActive)
                            ? null
                            : () => _submitAnswer(option),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(option, style: TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                if (_isAnswered)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
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

  Widget _buildQuizFinishedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Final Standings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildPlayerList(),
          SizedBox(height: 30),
          if (widget.isHost)
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Exit Quiz'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHostControls() {
    if (!widget.isHost) return SizedBox();

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (!_quizActive && !_quizFinished)
            ElevatedButton(
              onPressed: _startQuiz,
              child: Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),
          if (_quizActive)
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text('Skip to Next Question'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.orange,
              ),
            ),
          if (_quizActive)
            ElevatedButton(
              onPressed: _endQuiz,
              child: Text('End Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLobbyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Waiting for quiz to start...',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          'Quiz ID: ${widget.quizId}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 30),
        Text(
          'Players in Lobby:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        _buildPlayerList(),
        SizedBox(height: 20),
        if (widget.isHost) _buildHostControls(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Error',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              _loadQuizData();
            },
            child: Text('Retry'),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Quiz'),
        automaticallyImplyLeading: !_quizActive,
        actions: [
          if (!widget.isHost && !_quizActive)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading quiz...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? _buildErrorView()
                : _quizFinished
                    ? _buildQuizFinishedView()
                    : (_quizActive
                        ? Column(
                            children: [
                              Expanded(child: _buildQuestionCard()),
                              if (widget.isHost) _buildHostControls(),
                            ],
                          )
                        : _buildLobbyView()),
      ),
    );
  }
}
