import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'QuizScreen.dart';
import 'dart:async';

class WaitingScreen extends StatefulWidget {
  final String quizId;

  const WaitingScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  late DatabaseReference _quizRef;
  late StreamSubscription _quizStatusSubscription;

  @override
  void initState() {
    super.initState();
    _quizRef = FirebaseDatabase.instance
        .ref('quizzes/${widget.quizId}'); // ✅ Correct initialization
    _setupQuizListener();
  }

  void _setupQuizListener() {
    _quizStatusSubscription =
        _quizRef.child('isActive').onValue.listen((event) {
      final isActive = event.snapshot.value as bool? ?? false;
      if (isActive && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(quizId: widget.quizId),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _quizStatusSubscription.cancel();
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
              'Quiz ID: ${widget.quizId}', // ✅ Safe to use `widget` here
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
