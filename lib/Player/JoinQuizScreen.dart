import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/Player/QuizScreen.dart';
/*

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
  String _selectedAvatar = 'avatar1'; // Default avatar
  String? _errorMessage;
  bool _isScanning = false;
  QRViewController? _qrController;

  @override
  void dispose() {
    _quizCodeController.dispose();
    _playerNameController.dispose();
    _qrController?.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _avatars = [
    {
      'id': 'camion',
      'color': Colors.blue,
      'imagePath': 'assets/images/avatars/camion.jpeg',
      'name': 'Camion'
    },
    {
      'id': 'cat',
      'color': Colors.red,
      'imagePath': 'assets/images/avatars/cat.jpeg',
      'name': 'Cat'
    },
    {
      'id': 'girly',
      'color': Colors.green,
      'imagePath': 'assets/images/avatars/girly.jpeg',
      'name': 'Girly'
    },
    {
      'id': 'temseh',
      'color': Colors.orange,
      'imagePath': 'assets/images/avatars/temseh.jpeg',
      'name': 'Temseh'
    },
    {
      'id': 'aqroub',
      'color': Colors.purple,
      'imagePath': 'assets/images/avatars/aqroub.jpeg',
      'name': 'Aqroub'
    },
    {
      'id': 'black_cat',
      'color': Colors.black,
      'imagePath': 'assets/images/avatars/black_cat.jpeg',
      'name': 'Black Cat'
    },
    {
      'id': 'couchon',
      'color': Colors.pink,
      'imagePath': 'assets/images/avatars/couchon.jpeg',
      'name': 'Couchon'
    },
    {
      'id': 'dabdoub',
      'color': Colors.teal,
      'imagePath': 'assets/images/avatars/dabdoub.jpeg',
      'name': 'Dabdoub'
    },
    {
      'id': 'dhib',
      'color': Colors.brown,
      'imagePath': 'assets/images/avatars/dhib.jpeg',
      'name': 'Dhib'
    },
    {
      'id': 'fil',
      'color': Colors.indigo,
      'imagePath': 'assets/images/avatars/fil.jpeg',
      'name': 'Fil'
    },
    {
      'id': 'nahla',
      'color': Colors.amber,
      'imagePath': 'assets/images/avatars/nahla.jpeg',
      'name': 'Nahla'
    },
    {
      'id': 'mafjouu',
      'color': Colors.cyan,
      'imagePath': 'assets/images/avatars/mafjouu.jpeg',
      'name': 'Mafjouu'
    },
    {
      'id': 'far',
      'color': Colors.deepOrange,
      'imagePath': 'assets/images/avatars/far.jpeg',
      'name': 'Far'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial quiz code if provided
    if (widget.initialQuizCode != null) {
      _quizCodeController.text = widget.initialQuizCode!;
    }
  }

  Future<void> _joinQuiz() async {
    // Clear previous error messages
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    String quizId = _quizCodeController.text.trim();
    String playerName = _playerNameController.text.trim();
    String userId = DateTime.now().millisecondsSinceEpoch.toString();

    // Validate inputs
    if (quizId.isEmpty || playerName.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both quiz code and your name.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Check if quiz exists (redundant if coming from HomeScreen but good to keep)
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(quizId).get();

      if (snapshot.exists) {
        // Get quiz data to check if it's active or finished
        Map<String, dynamic> quizData =
            (snapshot.value as Map<Object?, Object?>).cast<String, dynamic>();

        bool isActive = quizData['isActive'] ?? false;
        int currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
        List<dynamic> questions = quizData['questions'] ?? [];

        // Check if quiz is finished
        if (!isActive && currentQuestionIndex >= questions.length - 1) {
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
            builder: (context) => QuizScreen(
              quizId: quizId,
              isHost: false,
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
        _joinQuiz();
      }
    });
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
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatar = _avatars[index];
          final isSelected = avatar['id'] == _selectedAvatar;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAvatar = avatar['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
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
                      color:
                          isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
*/
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quiz_app/Player/QuizScreen.dart';

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

  @override
  void dispose() {
    _quizCodeController.dispose();
    _playerNameController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _avatars = [
    // ... keep your existing avatars list ...
  ];

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
        Map<String, dynamic> quizData =
            (snapshot.value as Map<Object?, Object?>).cast<String, dynamic>();

        bool isActive = quizData['isActive'] ?? false;
        int currentQuestionIndex = quizData['currentQuestionIndex'] ?? 0;
        List<dynamic> questions = quizData['questions'] ?? [];

        if (!isActive && currentQuestionIndex >= questions.length - 1) {
          if (!mounted) return;
          setState(() {
            _errorMessage = "This quiz has already ended.";
            _isLoading = false;
          });
          return;
        }

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Joined the quiz successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              quizId: quizId,
              isHost: false,
              playerName: playerName,
              playerAvatar: _selectedAvatar,
              playerId: userId,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              "Quiz not found. Please check the code and try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
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
        const Text(
          "Select your avatar:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatar = _avatars[index];
              final isSelected = avatar['id'] == _selectedAvatar;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar['id'];
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
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
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
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
