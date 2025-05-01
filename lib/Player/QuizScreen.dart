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
/*
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
*/

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
                      'En attente du début du quiz',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Code du quiz : ${widget.quizId}',
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
                            'Prêt(e), ${widget.playerName}!',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    const Text(
                      'Joueurs en attente :',
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
                                'Aucun joueur pour le moment',
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
                                  title: Text(player['name'] ?? 'Joueur'),
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
                      'Quiz Terminé!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Classement final',
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
                          'Aucun participant',
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
                              ? 'Retour au tableau de bord'
                              : 'Quitter le quiz',
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
                'Démarrer le Quiz',
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
                    'Question Suivante',
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
                    'Terminer le Quiz',
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
              'Oups!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Une erreur inconnue est survenue',
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
              child: const Text('Réessayer'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

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
              tooltip: 'Quitter',
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Chargement du quiz...',
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
        // Header avec timer et score
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
              // Timer
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
                      '$_remainingTime',
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

              // Question counter
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              // Score
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

        // Carte de question
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

                        // Options de réponse
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
                              'Réponse enregistrée. En attente de la prochaine question...',
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

                // Classement partiel
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
                            'Classement actuel',
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
}
