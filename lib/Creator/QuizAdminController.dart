import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
/*
class QuizAdminController {
  final String quizId;
  late final DatabaseReference _quizRef;
  late StreamSubscription _quizSubscription;
  late Timer _questionTimer;

  List<dynamic> questions = [];
  Map<String, dynamic> players = {};
  int currentQuestionIndex = 0;
  bool quizActive = false;
  int remainingTime = 0;

  final ValueNotifier<void> notifier =
      ValueNotifier(null); // pour notifier l'UI

  QuizAdminController({required this.quizId}) {
    _quizRef = FirebaseDatabase.instance.ref('quizzes/$quizId');
    _loadQuizData();
    _setupRealTimeUpdates();
  }

  Future<void> _loadQuizData() async {
    final snapshot = await _quizRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
      players = Map<String, dynamic>.from(data['players'] ?? {});
      currentQuestionIndex = data['currentQuestionIndex'] ?? 0;
      quizActive = data['isActive'] ?? false;
      notifier.value = null;
    }
  }

  void _setupRealTimeUpdates() {
    _quizSubscription = _quizRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        players = Map<String, dynamic>.from(data['players'] ?? {});
        currentQuestionIndex = data['currentQuestionIndex'] ?? 0;
        quizActive = data['isActive'] ?? false;
        notifier.value = null;
      }
    });
  }

  Future<void> startQuiz() async {
    await _quizRef.update({
      'isActive': true,
      'currentQuestionIndex': 0,
      'startTime': ServerValue.timestamp,
    });
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    const questionDuration = 30;
    remainingTime = questionDuration;
    notifier.value = null;

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        remainingTime--;
        notifier.value = null;
      } else {
        timer.cancel();
        nextQuestion();
      }
    });
  }

  Future<void> nextQuestion() async {
    _questionTimer.cancel();
    if (currentQuestionIndex < questions.length - 1) {
      await _quizRef.update({
        'currentQuestionIndex': currentQuestionIndex + 1,
      });
      _startQuestionTimer();
    } else {
      await endQuiz();
    }
  }

  Future<void> endQuiz() async {
    _questionTimer.cancel();
    await _quizRef.update({
      'isActive': false,
    });
    quizActive = false;
    notifier.value = null;
  }

  void dispose() {
    _quizSubscription.cancel();
    _questionTimer.cancel();
  }
}
*/