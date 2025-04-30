import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Creator/QuizAdminDashboard.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'QuizScreen.dart'; // Make sure to import your QuizScreen

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
          /*children: [
            Text(
              'Your Quiz Code:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.quizId,
              style: TextStyle(
                  fontSize: 30,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startQuiz,
              child: const Text('Start Quiz'),
            ),
          ],*/
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
/*
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../Creator/QuizAdminDashboard.dart';

class QuizCreatedScreen extends StatefulWidget {
  final String quizId;

  const QuizCreatedScreen({Key? key, required this.quizId}) : super(key: key);

  @override
  _QuizCreatedScreenState createState() => _QuizCreatedScreenState();
}

class _QuizCreatedScreenState extends State<QuizCreatedScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // URL ou données à encoder dans le QR code
    final qrData = 'https://votredomaine.com/quiz/join?code=${widget.quizId}';
    // ou simplement l'ID du quiz: qrData = widget.quizId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Created'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareQuiz,
            tooltip: "Partager le quiz",
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Votre code de quiz:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                widget.quizId,
                style: TextStyle(
                    fontSize: 30,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),

              // QR Code Widget
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Scanner pour rejoindre',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Ou partagez le code ci-dessus',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _startQuiz,
                  icon: Icon(Icons.play_arrow),
                  label: const Text('Start Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareQuiz() async {
    // Implémentez la logique de partage ici
    // Vous pouvez utiliser le package share_plus
    final qrData = 'https://votredomaine.com/quiz/join?code=${widget.quizId}';
    final text = 'Rejoignez mon quiz! Code: ${widget.quizId}\n$qrData';

    // Si vous avez ajouté share_plus dans pubspec.yaml
    // await Share.share(text);

    // Solution temporaire sans package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copié dans le presse-papier: $text'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _startQuiz() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Activer le quiz dans Firebase
      await FirebaseDatabase.instance.ref('quizzes/${widget.quizId}').update({
        'isActive': true,
        'currentQuestionIndex': 0,
      });

      // Rediriger vers le dashboard admin
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizAdminDashboard(quizId: widget.quizId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
*/