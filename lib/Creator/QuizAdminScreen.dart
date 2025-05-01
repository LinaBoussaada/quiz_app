import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:quiz_app/Creator/QuizAdminController.dart';
/*
class QuizAdminScreen extends StatefulWidget {
  final String quizId;

  const QuizAdminScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizAdminScreenState createState() => _QuizAdminScreenState();
}

class _QuizAdminScreenState extends State<QuizAdminScreen> {
  late QuizAdminController _controller; // ici corrigé

  @override
  void initState() {
    super.initState();
    _controller = QuizAdminController(quizId: widget.quizId); // ici corrigé
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel Admin')),
      body: ValueListenableBuilder(
        valueListenable: _controller.notifier,
        builder: (context, _, __) {
          return Column(
            children: [
              // Utilise _controller.questions, _controller.remainingTime, etc.
            ],
          );
        },
      ),
    );
  }
}
*/