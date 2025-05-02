import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/Creator/QuizAdminDashboard.dart';
import 'package:quiz_app/Shared/loginScreen.dart';
import 'dart:math';
import 'package:quiz_app/Creator/quiz_created_screen.dart';

class CreateQuizScreen extends StatefulWidget {
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final List<Map<String, dynamic>> _questions = [];
  List<String> _options = ["", "", "", ""];
  String? _correctAnswer;

  // Pour la sidebar: liste des quiz
  List<Map<String, dynamic>> _quizList = [];
  bool _isLoading = true;

  // Variables for quiz control
  bool _quizFinished = false;
  bool _timeExpired = false;
  int _currentQuestionIndex = 0;
  
  // Mobile responsive
  bool _isMobileView = false;
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('quizzes')
          .orderByChild('creatorId')
          .equalTo(user.uid)
          .once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> quizzes = [];

        data.forEach((key, value) {
          if (value is Map) {
            quizzes.add(Map<String, dynamic>.from(value));
          }
        });

        setState(() {
          _quizList = quizzes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _quizList = [];
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateQuizId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  void _resetQuestionForm() {
    setState(() {
      _questionController.clear();
      _timeController.clear();
      _options = ["", "", "", ""];
      _correctAnswer = null;
    });
  }

  void _addQuestion() {
    if (_questionController.text.isNotEmpty &&
        _correctAnswer != null &&
        _timeController.text.isNotEmpty &&
        int.tryParse(_timeController.text) != null) {
      setState(() {
        _questions.add({
          'question': _questionController.text,
          'options': List.from(_options),
          'answer': _correctAnswer,
          'time': int.parse(_timeController.text),
        });
        // Réinitialiser le formulaire après ajout
        _resetQuestionForm();
      });

      // Amélioration du SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Question ajoutée avec succès!"),
            ],
          ),
          backgroundColor: Color(0xFF5B9BD5), // Bleu Mentimeter
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // SnackBar d'erreur amélioré
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Veuillez remplir tous les champs et définir un temps valide.",
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFE57373), // Rouge plus clair
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  final databaseRef = FirebaseDatabase.instance.ref();

  void _saveQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }

    if (_titleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text("Ajoutez un titre et au moins une question."),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 235, 181, 217), 
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5B9BD5),
        )
      ),
    );

    String quizId = _generateQuizId();

    // Sauvegarder le quiz avec les données du QR code
    await databaseRef.child('quizzes').child(quizId).set({
      'quizId': quizId,
      'title': _titleController.text,
      'questions': _questions,
      'creatorId': user.uid,
      'players': {},
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'qrCodeData': quizId, // Sauvegarder l'ID comme données du QR code
      'isActive': false, // Ajout pour l'état du quiz
      'currentQuestionIndex': 0, // Ajout pour la progression
    });

    Navigator.pop(context);
    _loadQuizzes();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizCreatedScreen(quizId: quizId),
      ),
    );

    _titleController.clear();
    setState(() {
      _questions.clear();
    });
  }

  void _loadQuiz(String quizId) async {
    setState(() {
      _isLoading = true;
    });

    final snapshot = await databaseRef.child('quizzes').child(quizId).once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map;

      setState(() {
        _titleController.text = data['title'] ?? '';
        _questions.clear();

        if (data['questions'] != null) {
          final questionData = data['questions'] as List;
          for (var question in questionData) {
            _questions.add(Map<String, dynamic>.from(question));
          }
        }

        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _restartQuiz(String quizId) async {
    // Get reference to the quiz
    final quizRef = databaseRef.child('quizzes').child(quizId);

    await quizRef.update({
      'isActive': false,
      'currentQuestionIndex': 0,
      'quizEnded': false, // Set to false when restarting
      //bsh nfaskh liste leqdima aamlt hedhy
      'players': {},
    });

    setState(() {
      _quizFinished = false;
      _timeExpired = false;
      _currentQuestionIndex = 0;
    });

    // Show a message that quiz is ready to be started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quiz prêt à démarrer. Les joueurs peuvent maintenant rejoindre.'),
        backgroundColor: Color(0xFF81C784), // Vert clair
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );

    // Navigate to quiz admin dashboard
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizAdminDashboard(quizId: quizId),
      ),
    );
  }

  // Widget pour afficher la sidebar
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white, 
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mes Quiz",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                _isMobileView ? IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showSidebar = false;
                    });
                  },
                ) : SizedBox(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    color: Color(0xFF5B9BD5), 
                  ))
                : _quizList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined, 
                              size: 48, 
                              color: Colors.grey.shade400
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Aucun quiz créé",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _quizList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            color: Colors.grey.shade100,
                            child: ListTile(
                              title: Text(
                                _quizList[index]['title'] ?? 'Sans titre',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              leading: Icon(
                                Icons.quiz_outlined,
                                color: Color(0xFF5B9BD5),
                              ),
                              subtitle: Text(
                                "Questions: ${_quizList[index]['questions']?.length ?? 0}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              onTap: () {
                                _loadQuiz(_quizList[index]['quizId']);
                                if (_isMobileView) {
                                  setState(() {
                                    _showSidebar = false;
                                  });
                                }
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF81C784), // Vert clair
                                ),
                                tooltip: "Lancer ce quiz",
                                onPressed: () => _restartQuiz(
                                    _quizList[index]['quizId']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Divider(height: 1),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  offset: Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                "Nouveau Quiz", 
                style: TextStyle(
                  color: Color(0xFF5B9BD5), // Bleu Mentimeter
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(
                Icons.add_circle, 
                color: Color(0xFF5B9BD5), // Bleu Mentimeter
              ),
              onTap: () {
                setState(() {
                  _titleController.clear();
                  _questions.clear();
                  _resetQuestionForm();
                  if (_isMobileView) {
                    _showSidebar = false;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la section principale
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          if (_isMobileView)
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Créer un Quiz",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B9BD5), // Bleu Mentimeter
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () {
                      setState(() {
                        _showSidebar = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Section informations du Quiz
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Informations du Quiz",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Titre du Quiz",
                      labelStyle: TextStyle(color: Color(0xFF5B9BD5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF5B9BD5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      prefixIcon: Icon(Icons.title, color: Color(0xFF5B9BD5)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Section questions ajoutées
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Questions ajoutées",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black                        ),
                      ),
                      Chip(
                        label: Text(
                          "${_questions.length} question(s)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Color(0xFF5B9BD5), // Bleu Mentimeter
                        padding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _questions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    size: 36,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Aucune question ajoutée",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 0,
                                margin: EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                color: Colors.white,
                                child: ListTile(
                                  title: Text(
                                    _questions[index]['question'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(
                                          "Réponse: ${_questions[index]['answer']}",
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: Colors.white
                                          ),
                                        ),
                                        backgroundColor: Color(0xFF81C784), // Vert clair
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        labelPadding: EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      Chip(
                                        label: Text(
                                          "${_questions[index]['time']}s",
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: Colors.white
                                          ),
                                        ),
                                        backgroundColor: Color(0xFF90CAF9), // Bleu très clair
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        labelPadding: EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFE57373), // Rouge clair
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _questions.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Section ajouter une nouvelle question
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ajouter une nouvelle question",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      labelText: "Question",
                      labelStyle: TextStyle(color: Color(0xFF5B9BD5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF5B9BD5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      prefixIcon: Icon(Icons.help_outline, color: Color(0xFF5B9BD5)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Options de réponse",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5B9BD5),
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Options de réponse (adaptatif pour mobile)
                  _isMobileView
                      ? Column(
                          children: [
                            _buildOptionField(0, "Option 1"),
                            SizedBox(height: 8),
                            _buildOptionField(1, "Option 2"),
                            SizedBox(height: 8),
                            _buildOptionField(2, "Option 3"),
                            SizedBox(height: 8),
                            _buildOptionField(3, "Option 4"),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildOptionField(0, "Option 1")),
                                SizedBox(width: 8),
                                Expanded(child: _buildOptionField(1, "Option 2")),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildOptionField(2, "Option 3")),
                                SizedBox(width: 8),
                                Expanded(child: _buildOptionField(3, "Option 4")),
                              ],
                            ),
                          ],
                        ),
                        
                  SizedBox(height: 16),
                  
                  // Bonne réponse et temps (adaptatif pour mobile)
                  _isMobileView
                      ? Column(
                          children: [
                            _buildCorrectAnswerDropdown(),
                            SizedBox(height: 8),
                            _buildTimeField(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildCorrectAnswerDropdown()),
                            SizedBox(width: 8),
                            Expanded(child: _buildTimeField()),
                          ],
                        ),
                  
                  SizedBox(height: 20),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetQuestionForm,
                        icon: Icon(Icons.clear),
                        label: Text("Reset"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: Icon(Icons.add),
                        label: Text("Ajouter question"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5B9BD5), // Bleu Mentimeter
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Bouton de sauvegarde
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveQuiz,
              icon: Icon(Icons.save),
              label: Text(
                "Enregistrer le Quiz",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF81C784), // Vert clair
                foregroundColor: Colors.white,
                elevation: 1,
                shadowColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 40), // Espace supplémentaire en bas pour le scroll
        ],
      ),
    );
  }

  // Champs pour les options
  Widget _buildOptionField(int index, String label) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _options[index] = value;
        });
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF5B9BD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  // Dropdown pour la bonne réponse
  Widget _buildCorrectAnswerDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Bonne réponse",
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF5B9BD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(Icons.check_circle_outline, color: Color(0xFF81C784)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: Text("Choisissez la bonne réponse"),
      value: _correctAnswer,
      items: _options
          .where((option) => option.isNotEmpty)
          .map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _correctAnswer = value;
        });
      },
    );
  }

  // Champ pour le temps
  Widget _buildTimeField() {
    return TextField(
      controller: _timeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: "Temps (en secondes)",
        labelStyle: TextStyle(color: Colors.grey.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF5B9BD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(Icons.timer, color: Color(0xFF90CAF9)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Détecter si on est en vue mobile ou tablette/desktop
    final screenWidth = MediaQuery.of(context).size.width;
    _isMobileView = screenWidth < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Nouveau Quiz",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFE3E4FD), // Bleu Mentimeter
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadQuizzes,
            tooltip: "Rafraîchir la liste",
          ),
        ],
        // Montrer menu pour mobile uniquement dans l'appbar
        leading: _isMobileView && !_showSidebar
            ? IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showSidebar = true;
                  });
                },
              )
            : null,
      ),
      body: _isMobileView
          ? Stack(
              children: [
                // Contenu principal toujours visible
                _buildMainContent(),
                
                // Sidebar conditionnelle en vue mobile
                if (_showSidebar)
                  Container(
                    color: Colors.black54, // Overlay semi-transparent
                    width: double.infinity,
                    height: double.infinity,
                    child: Row(
                      children: [
                        _buildSidebar(),
                        // Zone cliquable pour fermer le menu
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showSidebar = false;
                              });
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : Row(
              children: [
                // Sidebar toujours visible en mode desktop
                _buildSidebar(),
                
                // Ligne verticale de séparation
                VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                
                // Contenu principal
                Expanded(child: _buildMainContent()),
              ],
            ),
      
      // Bouton flottant pour mobile uniquement
      floatingActionButton: _isMobileView && !_showSidebar
          ? FloatingActionButton(
              onPressed: _saveQuiz,
              backgroundColor: Color(0xFF81C784), // Vert clair
              child: Icon(Icons.save, color: Colors.white),
              tooltip: "Enregistrer le Quiz",
            )
          : null,
    );
  }
}