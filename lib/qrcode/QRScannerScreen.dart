import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:quiz_app/Player/QuizLobbyScreen.dart';
/*
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
*/
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quiz_app/Player/QuizLobbyScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode], // Focus only on QR codes
  );
  bool isScanning = true;
  bool isProcessing = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    // You might want to add camera permission checking here
    // For example using the permission_handler package
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _joinQuiz(String quizId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first!')),
      );
      return;
    }

    // Basic validation
    if (quizId.isEmpty || quizId.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code!')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
      isScanning = false;
    });

    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final snapshot = await databaseRef.child('quizzes').child(quizId).get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz not found!')),
        );
        return;
      }

      // Check if quiz has started
      final quizData = snapshot.value as Map<dynamic, dynamic>?;
      if (quizData?['status'] == 'started') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz has already started!')),
        );
        return;
      }

      // Add/update player in quiz
      await databaseRef
          .child('quizzes')
          .child(quizId)
          .child('players')
          .child(user.uid)
          .update({
        'joinedAt': ServerValue.timestamp,
        'status': 'waiting',
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizLobbyScreen(quizId: quizId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
          isScanning = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onScannerStarted: (arguments) {
              setState(() => _isCameraInitialized = true);
            },
            onDetect: (capture) {
              if (!isScanning || isProcessing) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final code = barcodes.first.rawValue;
              if (code == null || code.isEmpty) return;

              _joinQuiz(code.trim());
            },
          ),
          if (!_isCameraInitialized)
            const Center(child: CircularProgressIndicator()),
          if (isProcessing) const Center(child: CircularProgressIndicator()),
          CustomPaint(
            painter: ScannerOverlay(
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Align the QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: const [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanning will happen automatically',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    shadows: const [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final double cutOutSize;

  ScannerOverlay({required this.cutOutSize});

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
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(cutOutRect, borderPaint);

    // Draw corner lines
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Top left
    canvas.drawLine(
      cutOutRect.topLeft,
      cutOutRect.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.topLeft,
      cutOutRect.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Top right
    canvas.drawLine(
      cutOutRect.topRight,
      cutOutRect.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.topRight,
      cutOutRect.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom left
    canvas.drawLine(
      cutOutRect.bottomLeft,
      cutOutRect.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.bottomLeft,
      cutOutRect.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    // Bottom right
    canvas.drawLine(
      cutOutRect.bottomRight,
      cutOutRect.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      cutOutRect.bottomRight,
      cutOutRect.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
