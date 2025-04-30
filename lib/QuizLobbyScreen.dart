import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:quiz_app/Player/QuizScreen.dart';

class QuizLobbyScreen extends StatefulWidget {
  final String quizId;

  const QuizLobbyScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizLobbyScreenState createState() => _QuizLobbyScreenState();
}

class _QuizLobbyScreenState extends State<QuizLobbyScreen> {
  late DatabaseReference _quizRef;
  Map<dynamic, dynamic>? _quizData;
  bool _isLoading = true;
  String _playerName = '';
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quizRef = FirebaseDatabase.instance.ref('quizzes').child(widget.quizId);
    _setupListeners();
  }

  void _setupListeners() {
    _quizRef.onValue.listen((event) {
      if (!mounted) return;

      if (event.snapshot.exists) {
        setState(() {
          _quizData = event.snapshot.value as Map<dynamic, dynamic>;
          _isLoading = false;
        });

        // Si le quiz a commencé, rediriger vers QuizScreen
        if (_quizData?['status'] == 'started') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(quizId: widget.quizId),
            ),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ce quiz n\'existe plus')),
        );
      }
    });
  }

  Future<void> _joinQuiz() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer votre nom')),
      );
      return;
    }

    try {
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      await _quizRef.child('players').child(userId).set({
        'name': _nameController.text,
        'score': 0,
        'status': 'waiting',
        'joinedAt': ServerValue.timestamp,
      });

      setState(() {
        _playerName = _nameController.text;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isLoading ? 'Chargement...' : _quizData?['title'] ?? 'Quiz'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _playerName.isEmpty
              ? _buildNameInput()
              : _buildLobby(),
    );
  }

  Widget _buildNameInput() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Rejoindre le quiz:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Votre nom',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _joinQuiz,
            child: Text('Rejoindre'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobby() {
    final players = _quizData?['players'] as Map? ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'En attente du début du quiz...',
            style: TextStyle(fontSize: 18),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final playerId = players.keys.elementAt(index);
              final playerData = players[playerId];

              return ListTile(
                title: Text(playerData['name'] ?? 'Joueur ${index + 1}'),
                subtitle:
                    Text('Statut: ${playerData['status'] ?? 'en attente'}'),
                trailing: Text('Score: ${playerData['score'] ?? 0}'),
                tileColor: playerId == _playerName ? Colors.blue[50] : null,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Code du quiz: ${widget.quizId}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
