import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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
  String _selectedAvatar = 'avatar1'; // Default avatar
  String? _errorMessage;
  
  final List<Map<String, dynamic>> _avatars = [
    {'id': 'camion', 'color': Colors.blue, 'imagePath': 'assets/images/avatars/camion.jpeg', 'name': 'Camion'},
    {'id': 'cat', 'color': Colors.red, 'imagePath': 'assets/images/avatars/cat.jpeg', 'name': 'Cat'},
    {'id': 'girly', 'color': Colors.green, 'imagePath': 'assets/images/avatars/girly.jpeg', 'name': 'Girly'},
    {'id': 'temseh', 'color': Colors.orange, 'imagePath': 'assets/images/avatars/temseh.jpeg', 'name': 'Temseh'},
    {'id': 'aqroub', 'color': Colors.purple, 'imagePath': 'assets/images/avatars/aqroub.jpeg', 'name': 'Aqroub'},
    {'id': 'black_cat', 'color': Colors.black, 'imagePath': 'assets/images/avatars/black_cat.jpeg', 'name': 'Black Cat'},
    {'id': 'couchon', 'color': Colors.pink, 'imagePath': 'assets/images/avatars/couchon.jpeg', 'name': 'Couchon'},
    {'id': 'dabdoub', 'color': Colors.teal, 'imagePath': 'assets/images/avatars/dabdoub.jpeg', 'name': 'Dabdoub'},
    {'id': 'dhib', 'color': Colors.brown, 'imagePath': 'assets/images/avatars/dhib.jpeg', 'name': 'Dhib'},
    {'id': 'fil', 'color': Colors.indigo, 'imagePath': 'assets/images/avatars/fil.jpeg', 'name': 'Fil'},
    {'id': 'nahla', 'color': Colors.amber, 'imagePath': 'assets/images/avatars/nahla.jpeg', 'name': 'Nahla'},
    {'id': 'mafjouu', 'color': Colors.cyan, 'imagePath': 'assets/images/avatars/mafjouu.jpeg', 'name': 'Mafjouu'},
    {'id': 'far', 'color': Colors.deepOrange, 'imagePath': 'assets/images/avatars/far.jpeg', 'name': 'Far'},
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
      DataSnapshot snapshot = await databaseRef.child('quizzes').child(quizId).get();
      
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
        await databaseRef.child('quizzes').child(quizId).child('players').child(userId).set({
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
          _errorMessage = "Quiz not found. Please check the code and try again.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join a Quiz"),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Joining quiz...", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    "Join a Live Quiz",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your details below to participate",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Quiz code field
                  TextField(
                    controller: _quizCodeController,
                    decoration: const InputDecoration(
                      labelText: "Quiz Code",
                      hintText: "Enter the quiz code",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: widget.initialQuizCode != null, 
                  ),
                  const SizedBox(height: 20),
                  
                  // Player name field
                  TextField(
                    controller: _playerNameController,
                    decoration: const InputDecoration(
                      labelText: "Your Name",
                      hintText: "Enter your display name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 30),
                  
                  // Avatar selection
                  const Text(
                    "Choose your avatar:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildAvatarSelector(),
                  const SizedBox(height: 30),
                  
                  // Error message display
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                  
                  // Join button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _joinQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Join Quiz",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
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
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  
  @override
  void dispose() {
    _quizCodeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }
}