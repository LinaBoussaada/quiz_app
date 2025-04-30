import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:quiz_app/QuizLobbyScreen.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning) {
        isScanning = false;
        _joinQuiz(scanData.code!);
      }
    });
  }

  Future<void> _joinQuiz(String quizId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle not logged in case
      return;
    }

    // Check if quiz exists
    final databaseRef = FirebaseDatabase.instance.ref();
    final snapshot = await databaseRef.child('quizzes').child(quizId).get();

    if (snapshot.exists) {
      // Add player to quiz
      await databaseRef
          .child('quizzes')
          .child(quizId)
          .child('players')
          .child(user.uid)
          .set({
        'joinedAt': ServerValue.timestamp,
        'score': 0,
        'status': 'waiting',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizLobbyScreen(quizId: quizId),
        ),
      );
    } else {
      setState(() {
        isScanning = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz not found!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Align the QR code within the frame to scan',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
