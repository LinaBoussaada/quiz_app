import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quiz_app/qrcode/QuizLobbyScreen.dart';

class QRJoinScreen extends StatefulWidget {
  @override
  _QRJoinScreenState createState() => _QRJoinScreenState();
}

class _QRJoinScreenState extends State<QRJoinScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String? code) async {
    if (!_isScanning || _isProcessing || code == null || code.isEmpty) {
      _showError("QR Code invalide ou vide");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final quizRef = FirebaseDatabase.instance.ref('quizzes').child(code);
      final snapshot = await quizRef.get();

      if (!snapshot.exists) {
        _showError("Quiz introuvable");
        return;
      }

      final quizData = snapshot.value as Map<dynamic, dynamic>;
      if (quizData['status'] == 'started') {
        _showError("Le quiz a déjà commencé");
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizLobbyScreen(quizId: code),
        ),
      );
    } catch (e) {
      _showError("Erreur: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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

    _controller.start();
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
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return Icon(Icons.flash_off);
                  case TorchState.on:
                    return Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _processQRCode(barcodes.first.rawValue);
              }
            },
          ),
          CustomPaint(
            painter: _QRScannerOverlay(
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

class _QRScannerOverlay extends CustomPainter {
  final Color borderColor;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  _QRScannerOverlay({
    required this.borderColor,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final center = Offset(size.width / 2, size.height / 2);
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Clear the center area
    canvas.drawRect(
      cutOutRect,
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRect(cutOutRect, borderPaint);

    // Draw corner lines
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Top left
    canvas.drawLine(
      cutOutRect.topLeft,
      cutOutRect.topLeft + Offset(borderLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.topLeft,
      cutOutRect.topLeft + Offset(0, borderLength),
      cornerPaint,
    );

    // Top right
    canvas.drawLine(
      cutOutRect.topRight,
      cutOutRect.topRight + Offset(-borderLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.topRight,
      cutOutRect.topRight + Offset(0, borderLength),
      cornerPaint,
    );

    // Bottom left
    canvas.drawLine(
      cutOutRect.bottomLeft,
      cutOutRect.bottomLeft + Offset(borderLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.bottomLeft,
      cutOutRect.bottomLeft + Offset(0, -borderLength),
      cornerPaint,
    );

    // Bottom right
    canvas.drawLine(
      cutOutRect.bottomRight,
      cutOutRect.bottomRight + Offset(-borderLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.bottomRight,
      cutOutRect.bottomRight + Offset(0, -borderLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
