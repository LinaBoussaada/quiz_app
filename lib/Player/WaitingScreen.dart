import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'QuizScreen.dart';
import 'dart:async';

class WaitingScreen extends StatefulWidget {
  final String quizId;
  final String playerName;
  final String playerAvatar;
  final String playerId;

  const WaitingScreen({
    Key? key,
    required this.quizId,
    required this.playerName,
    required this.playerAvatar,
    required this.playerId,
  }) : super(key: key);

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  late DatabaseReference _quizRef;
  late StreamSubscription _quizSubscription;

  @override
  void initState() {
    super.initState();
    _quizRef = FirebaseDatabase.instance.ref('quizzes/${widget.quizId}');
    _setupQuizListener();
  }

  void _setupQuizListener() {
    _quizSubscription = _quizRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null || !mounted) return;

      final isActive = data['isActive'] as bool? ?? false;
      final currentQuestionIndex = data['currentQuestionIndex'] as int? ?? 0;
      final questions = data['questions'] as List? ?? [];

      // Si le quiz est actif OU si on a déjà commencé les questions
      if ((isActive || currentQuestionIndex > 0) && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              quizId: widget.quizId,
              isHost: false,
              playerName: widget.playerName,
              playerAvatar: widget.playerAvatar,
              playerId: widget.playerId,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _quizSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Waiting for host to start the quiz...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            Text(
              'Quiz ID: ${widget.quizId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(
                  'assets/images/avatars/${widget.playerAvatar}.jpeg'),
            ),
            const SizedBox(height: 10),
            Text(
              'Hello, ${widget.playerName}!',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
