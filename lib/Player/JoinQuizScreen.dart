import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/Player/QuizScreen.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quiz_app/Player/QuizScreen.dart';
import 'package:quiz_app/Player/WaitingScreen.dart';

class JoinQuizScreen extends StatefulWidget {
  final String? initialQuizCode;

  const JoinQuizScreen({Key? key, this.initialQuizCode}) : super(key: key);

  @override
  _JoinQuizScreenState createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final TextEditingController _quizCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final databaseRef = FirebaseDatabase.instance.ref();
  bool _isLoading = false;
  String _selectedAvatar = 'avatar1';
  String? _errorMessage;
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  final List<Map<String, dynamic>> _avatars = [
    {
      'id': 'camion',
      'color': Color(0xFF90CAF9),
      'imagePath': 'assets/images/avatars/camion.jpeg',
      'name': 'Camion'
    },
    {
      'id': 'cat',
      'color': Color(0xFFEF9A9A),
      'imagePath': 'assets/images/avatars/cat.jpeg',
      'name': 'Cat'
    },
    {
      'id': 'girly',
      'color': Color(0xFFA5D6A7),
      'imagePath': 'assets/images/avatars/girly.jpeg',
      'name': 'Girly'
    },
    {
      'id': 'temseh',
      'color': Color(0xFFFFCC80),
      'imagePath': 'assets/images/avatars/temseh.jpeg',
      'name': 'Temseh'
    },
    {
      'id': 'aqroub',
      'color': Color(0xFFCE93D8),
      'imagePath': 'assets/images/avatars/aqroub.jpeg',
      'name': 'Aqroub'
    },
    {
      'id': 'black_cat',
      'color': Color(0xFF9E9E9E),
      'imagePath': 'assets/images/avatars/black_cat.jpeg',
      'name': 'Black Cat'
    },
    {
      'id': 'couchon',
      'color': Color(0xFFF48FB1),
      'imagePath': 'assets/images/avatars/couchon.jpeg',
      'name': 'Couchon'
    },
    {
      'id': 'dabdoub',
      'color': Color(0xFF80CBC4),
      'imagePath': 'assets/images/avatars/dabdoub.jpeg',
      'name': 'Dabdoub'
    },
    {
      'id': 'dhib',
      'color': Color(0xFFBCAAA4),
      'imagePath': 'assets/images/avatars/dhib.jpeg',
      'name': 'Dhib'
    },
    {
      'id': 'fil',
      'color': Color(0xFF9FA8DA),
      'imagePath': 'assets/images/avatars/fil.jpeg',
      'name': 'Fil'
    },
    {
      'id': 'nahla',
      'color': Color(0xFFFFE082),
      'imagePath': 'assets/images/avatars/nahla.jpeg',
      'name': 'Nahla'
    },
    {
      'id': 'mafjouu',
      'color': Color(0xFF80DEEA),
      'imagePath': 'assets/images/avatars/mafjouu.jpeg',
      'name': 'Mafjouu'
    },
    {
      'id': 'far',
      'color': Color(0xFFFFAB91),
      'imagePath': 'assets/images/avatars/far.jpeg',
      'name': 'Far'
    },
  ];

  @override
  void dispose() {
    _quizCodeController.dispose();
    _playerNameController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuizCode != null) {
      _quizCodeController.text = widget.initialQuizCode!;
    }
  }


  Future<void> _joinQuiz() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    String quizId = _quizCodeController.text.trim();
    String playerName = _playerNameController.text.trim();
    String userId = DateTime.now().millisecondsSinceEpoch.toString();

    if (quizId.isEmpty || playerName.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both quiz code and your name.";
        _isLoading = false;
      });
      return;
    }

    try {
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(quizId).get();

      if (snapshot.exists) {
        // Get quiz data to check if it's active
        Map<String, dynamic> quizData =
            (snapshot.value as Map<Object?, Object?>).cast<String, dynamic>();

        bool isActive = quizData['isActive'] ?? false;

        // Check for quizEnded flag instead of checking question indexes
        bool quizEnded = quizData['quizEnded'] ?? false;

        if (quizEnded && !isActive) {
          if (!mounted) return;
          setState(() {
            _errorMessage = "This quiz has already ended.";
            _isLoading = false;
          });
          return;
        }

        // Add player to the quiz
        await databaseRef
            .child('quizzes')
            .child(quizId)
            .child('players')
            .child(userId)
            .set({
          'name': playerName,
          'score': 0,
          'avatar': _selectedAvatar,
          'joinedAt': ServerValue.timestamp,
        });

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Joined the quiz successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to quiz screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingScreen(
              quizId: quizId,
              //*builder: (context) => QuizScreen(

              //quizId: quizId,
              //isHost: false,
              playerName: playerName,
              playerAvatar: _selectedAvatar,
              playerId: userId,
            ),
          ),
        );
      } else {
        // Quiz not found
        setState(() {
          _errorMessage =
              "Quiz not found. Please check the code and try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _errorMessage = "Error joining quiz: $e";
        _isLoading = false;
      });
    }
  }

  void _startQRScan() {
    setState(() {
      _isScanning = true;
    });
  }

  void _onQRDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    setState(() {
      _isScanning = false;
    });

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _quizCodeController.text = code;
    _scannerController?.stop();

    if (_playerNameController.text.isNotEmpty) {
      _joinQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Scan QR Code"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _isScanning = false);
              _scannerController?.dispose();
            },
          ),
          actions: [
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _scannerController?.torchState ??
                    ValueNotifier(TorchState.off),
                builder: (context, state, child) {
                  return Icon(
                    state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                    color: Colors.white,
                  );
                },
              ),
              onPressed: () => _scannerController?.toggleTorch(),
            ),
          ],
        ),
        body: MobileScanner(
          controller: _scannerController ??= MobileScannerController(),
          onDetect: _onQRDetect,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Join a Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _quizCodeController,
              decoration: InputDecoration(
                labelText: "Enter Quiz Code",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _startQRScan,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(
                labelText: "Enter Your Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _buildAvatarSelector(),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinQuiz,
              child: const Text("Join Quiz"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _startQRScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan QR Code Instead"),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildAvatarSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
        child: Text(
          "Choose your avatar:",
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      SizedBox(
        height: 140, // Increased height for the cards
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _avatars.length,
          itemBuilder: (context, index) {
            final avatar = _avatars[index];
            final isSelected = avatar['id'] == _selectedAvatar;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar['id'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 90,
                  decoration: BoxDecoration(
                    color: avatar['color'].withOpacity(isSelected ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? avatar['color'] : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: avatar['color'].withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatar['color'].withOpacity(0.2),
                          border: Border.all(
                            color: avatar['color'],
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatar['imagePath'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        avatar['name'],
                        style: TextStyle(
                          color: isSelected ? avatar['color'] : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: avatar['color'],
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
}
