import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';

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
  String _quizTitle = "";
  String _lastQuizSession = ""; // Track the current quiz session
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
        _quizTitle = data['title'] ?? "Quiz sans titre";

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
          _quizTitle = data['title'] ?? "Quiz sans titre";

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

/*
  Future<void> _startQuiz() async {
    await _quizRef.update({
      'isActive': true,
      'currentQuestionIndex': 0,
      'players': {}, // Réinitialise la liste des joueurs au démarrage du quiz
    });
    _startQuestionTimer();
  }*/

  Future<void> _startQuiz() async {
    // Generate a new session ID based on timestamp
    String newSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    await _quizRef.update({
      'isActive': true,
      'currentQuestionIndex': 0,
      'quizEnded': false,
      'sessionId': newSessionId,
    });

    setState(() {
      _lastQuizSession = newSessionId;
      _players = {}; // Clear local players list when starting a new quiz
      _quizFinished = false;
      _timeExpired = false;
    });

    _startQuestionTimer();
  }

  void _restartQuiz() async {
    // Generate a new session ID for the restarted quiz
    String newSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    await _quizRef.update({
      'isActive': false,
      'currentQuestionIndex': 0,
      'quizEnded': false,
      'sessionId': newSessionId,
      // We don't clear players in Firebase, we'll filter by sessionId
    });

    setState(() {
      _lastQuizSession = newSessionId;
      _players = {}; // Clear the local players list
      _quizFinished = false;
      _timeExpired = false;
      _currentQuestionIndex = 0;
    });

    // Show a message that the quiz is ready to start
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quiz ready to start. Players can now join.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Code QR du Quiz"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: widget.quizId,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "ID: ${widget.quizId}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer"),
          ),
        ],
      ),
    );
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

    // Ne pas sauvegarder l'historique

    await _quizRef.update({
      'isActive': false,
    });

    setState(() {
      _quizFinished = true;
    });
  }

  void _copyQuizIdToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.quizId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code du quiz copié dans le presse-papiers'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _quizFinished
          ? null
          : FloatingActionButton(
              onPressed: _restartQuiz,
              //onPressed: _quizActive ? null : _startQuiz,
              child: const Icon(Icons.play_arrow),
              tooltip: 'Démarrer le quiz',
              backgroundColor: _quizActive ? Colors.grey : Colors.green,
            ),
      /*  appBar: AppBar(
        title: Text("Quiz Admin: $_quizTitle"),
        actions: [
          if (_quizActive && !_quizFinished)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _endQuiz,
              tooltip: 'Terminer le quiz',
            ),
        ],
      ), */
      appBar: AppBar(
        title: Text("Quiz Admin: $_quizTitle"),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code),
            onPressed: _showQRDialog,
            tooltip: 'Afficher QR Code',
          ),
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
          // Section Code du Quiz
          /* Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.qr_code, size: 36, color: Colors.deepPurple),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Code du Quiz",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.quizId,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          "Les participants peuvent rejoindre avec ce code",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: _copyQuizIdToClipboard,
                    tooltip: "Copier le code",
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ), */
          // Section Code du Quiz
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 36, color: Colors.deepPurple),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Code du Quiz",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.quizId,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: _copyQuizIdToClipboard,
                            tooltip: "Copier le code",
                            color: Colors.blue,
                          ),
                          IconButton(
                            icon: Icon(Icons.qr_code),
                            onPressed: _showQRDialog,
                            tooltip: "Afficher QR Code",
                            color: Colors.deepPurple,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Mini QR Code preview
                  GestureDetector(
                    onTap: _showQRDialog,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: widget.quizId,
                        version: QrVersions.auto,
                        size: 80.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section État du Quiz
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16),
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
                            onPressed: _startQuiz, // on va tester ça
                            //onPressed: _restartQuiz,
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

          // Section Participants (uniquement les participants actuels)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    "Participants actuels (${_players.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Expanded(
                  child: _players.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48, color: Colors.grey.shade400),
                              SizedBox(height: 16),
                              Text(
                                "Aucun participant",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Partagez le code du quiz pour que les joueurs puissent rejoindre",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : _buildParticipantsList(_players),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(Map<String, dynamic> participants) {
  return ListView.builder(
    padding: EdgeInsets.all(8),
    itemCount: participants.length,
    itemBuilder: (context, index) {
      final entry = participants.entries.elementAt(index);
      final playerId = entry.key;
      final player = entry.value;
      final String avatarId = player['avatar'] ?? 'camion'; // Default to 'camion' if no avatar

      // Find the avatar color from the image ID (accessing the same avatars list from JoinQuizScreen)
      Color avatarColor = Colors.deepPurple;
      String avatarImagePath = 'assets/images/avatars/camion.jpeg'; // Default path
      
      // This should match your avatar list in JoinQuizScreen
      final Map<String, Map<String, dynamic>> avatarMap = {
        'camion': {'color': Color(0xFF90CAF9), 'path': 'assets/images/avatars/camion.jpeg'},
        'cat': {'color': Color(0xFFEF9A9A), 'path': 'assets/images/avatars/cat.jpeg'},
        'girly': {'color': Color(0xFFA5D6A7), 'path': 'assets/images/avatars/girly.jpeg'},
        'temseh': {'color': Color(0xFFFFCC80), 'path': 'assets/images/avatars/temseh.jpeg'},
        'aqroub': {'color': Color(0xFFCE93D8), 'path': 'assets/images/avatars/aqroub.jpeg'},
        'black_cat': {'color': Color(0xFF9E9E9E), 'path': 'assets/images/avatars/black_cat.jpeg'},
        'couchon': {'color': Color(0xFFF48FB1), 'path': 'assets/images/avatars/couchon.jpeg'},
        'dabdoub': {'color': Color(0xFF80CBC4), 'path': 'assets/images/avatars/dabdoub.jpeg'},
        'dhib': {'color': Color(0xFFBCAAA4), 'path': 'assets/images/avatars/dhib.jpeg'},
        'fil': {'color': Color(0xFF9FA8DA), 'path': 'assets/images/avatars/fil.jpeg'},
        'nahla': {'color': Color(0xFFFFE082), 'path': 'assets/images/avatars/nahla.jpeg'},
        'mafjouu': {'color': Color(0xFF80DEEA), 'path': 'assets/images/avatars/mafjouu.jpeg'},
        'far': {'color': Color(0xFFFFAB91), 'path': 'assets/images/avatars/far.jpeg'},
      };
      
      if (avatarMap.containsKey(avatarId)) {
        avatarColor = avatarMap[avatarId]!['color'] as Color;
        avatarImagePath = avatarMap[avatarId]!['path'] as String;
      }

      return Card(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: avatarColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withOpacity(0.2),
              border: Border.all(
                color: avatarColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                avatarImagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            player['name'] ?? 'Anonyme',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Score: ${player['score'] ?? 0}',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${player['score'] ?? 0} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              if (_quizActive)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    player['isCorrect'] == true
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: player['isCorrect'] == true
                        ? Colors.green
                        : Colors.grey,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
}
