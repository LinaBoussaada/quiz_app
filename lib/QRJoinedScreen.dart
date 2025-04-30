import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:quiz_app/QuizLobbyScreen.dart';

class QRJoinScreen extends StatefulWidget {
  @override
  _QRJoinScreenState createState() => _QRJoinScreenState();
}

class _QRJoinScreenState extends State<QRJoinScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrController;
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanning || _isProcessing) return;

      setState(() => _isProcessing = true);

      final quizId = scanData.code;
      if (quizId == null || quizId.isEmpty) {
        _showError("QR Code invalide ou vide");
        return;
      }

      // Vérification dans Firebase
      try {
        final quizRef = FirebaseDatabase.instance.ref('quizzes').child(quizId);
        final snapshot = await quizRef.get();

        if (!snapshot.exists) {
          _showError("Quiz introuvable");
          return;
        }

        // Redirection avec vérification de l'état du quiz
        final quizData = snapshot.value as Map<dynamic, dynamic>;
        if (quizData['status'] == 'started') {
          _showError("Le quiz a déjà commencé");
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizLobbyScreen(quizId: quizId),
          ),
        );
      } catch (e) {
        _showError("Erreur: ${e.toString()}");
      } finally {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {
      _isScanning = true;
      _isProcessing = false;
    });

    _qrController?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scanner le Quiz"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
          if (_isProcessing)
            Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              'Scannez le QR Code du quiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
