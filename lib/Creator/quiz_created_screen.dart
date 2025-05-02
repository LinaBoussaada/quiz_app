import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'QuizAdminDashboard.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../Player/QuizScreen.dart'; // Make sure to import your QuizScreen
/*
class QuizCreatedScreen extends StatefulWidget {
  final String quizId;

  const QuizCreatedScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizCreatedScreenState createState() => _QuizCreatedScreenState();
}

class _QuizCreatedScreenState extends State<QuizCreatedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Created')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Votre quiz a été créé avec succès!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'ID du Quiz: widget.quizId',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // QR Code contenant l'ID du quiz
            QrImageView(
              data: widget.quizId,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Scannez ce QR Code pour partager le quiz',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  // Dans _QuizCreatedScreenState
  Future<void> _startQuiz() async {
    try {
      // Activer le quiz dans Firebase
      await FirebaseDatabase.instance.ref('quizzes/${widget.quizId}').update({
        'isActive': true,
        'currentQuestionIndex': 0,
      });

      // Rediriger vers le DASHBOARD ADMIN - PAS l'écran participant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizAdminDashboard(quizId: widget.quizId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
}
*/
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'QuizAdminDashboard.dart';

class QuizCreatedScreen extends StatefulWidget {
  final String quizId;

  const QuizCreatedScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizCreatedScreenState createState() => _QuizCreatedScreenState();
}

class _QuizCreatedScreenState extends State<QuizCreatedScreen> {
  String? qrCodeData;
  bool isLoading = true;
  String? quizTitle;

  @override  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('quizzes/${widget.quizId}')
          .once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        setState(() {
          qrCodeData = data['qrCodeData'] ?? widget.quizId;
          quizTitle = data['title'] ?? 'Untitled Quiz';
          isLoading = false;
        });
      } else {
        setState(() {
          qrCodeData = widget.quizId;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading quiz data: $e');
      setState(() {
        qrCodeData = widget.quizId;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Created'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareQuiz,
            tooltip: 'Share Quiz',
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Quiz: $quizTitle',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your quiz has been created successfully!',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quiz ID: ${widget.quizId}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  // QR Code
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          QrImageView(
                            data: qrCodeData ?? widget.quizId,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Scan this QR code to join the quiz',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _startQuiz,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Start Quiz Now'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _shareQuiz() async {
    // Implémentez le partage ici (package flutter_share par exemple)
    // Pour l'instant, nous allons juste copier l'ID dans le presse-papiers
    await Clipboard.setData(ClipboardData(text: widget.quizId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quiz ID copied to clipboard!')),
    );
  }

  Future<void> _startQuiz() async {
    try {
      // Activer le quiz dans Firebase
      await FirebaseDatabase.instance.ref('quizzes/${widget.quizId}').update({
        'isActive': true,
        'currentQuestionIndex': 0,
        'players': {}, // Réinitialiser la liste des joueurs
      });

      // Rediriger vers le dashboard admin
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizAdminDashboard(quizId: widget.quizId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
