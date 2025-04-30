import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:quiz_app/Player/QuizScreen.dart';

class JoinQuizScreen extends StatefulWidget {
  @override
  _JoinQuizScreenState createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final TextEditingController _quizCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final databaseRef = FirebaseDatabase.instance.ref();
  bool _isScanning = false;
  QRViewController? _qrController;

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  Future<void> _joinQuiz({String? quizId}) async {
    String actualQuizId = quizId ?? _quizCodeController.text.trim();
    String playerName = _playerNameController.text.trim();

    if ((quizId == null && actualQuizId.isEmpty) || playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please enter both quiz code and your name."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(actualQuizId).get();

      if (snapshot.exists) {
        String userId = DateTime.now().millisecondsSinceEpoch.toString();
        await _addPlayerToQuiz(actualQuizId, userId, playerName);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Joined the quiz successfully!"),
          backgroundColor: Colors.green,
        ));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(quizId: actualQuizId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Quiz not found."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error joining quiz: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _addPlayerToQuiz(
      String quizId, String userId, String playerName) async {
    await databaseRef.child('quizzes/$quizId/players').child(userId).set({
      'name': playerName,
      'score': 0,
      'joinedAt': ServerValue.timestamp,
    });
  }

  void _startQRScan() {
    setState(() {
      _isScanning = true;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isScanning) return;

      setState(() {
        _isScanning = false;
      });

      _qrController?.pauseCamera();
      _quizCodeController.text = scanData.code ?? '';

      // Optionally auto-submit if player name is already entered
      if (_playerNameController.text.isNotEmpty) {
        _joinQuiz(quizId: scanData.code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Scan QR Code"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _isScanning = false);
              _qrController?.dispose();
            },
          ),
        ),
        body: QRView(
          key: GlobalKey(debugLabel: 'QR'),
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.blue,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: MediaQuery.of(context).size.width * 0.8,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Join a Quiz")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _quizCodeController,
              decoration: InputDecoration(
                labelText: "Enter Quiz Code",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: _startQRScan,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _playerNameController,
              decoration: InputDecoration(
                labelText: "Enter Your Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinQuiz,
              child: Text("Join Quiz"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _startQRScan,
                icon: Icon(Icons.qr_code_scanner),
                label: Text("Scan QR Code Instead"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
