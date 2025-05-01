import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/Creator/QuizAdminDashboard.dart';
import 'package:quiz_app/Shared/loginScreen.dart';
import 'dart:math';
import 'package:quiz_app/Player/quiz_created_screen.dart';

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
          backgroundColor: Colors.green.shade700,
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
          backgroundColor: Colors.red.shade700,
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
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    String quizId = _generateQuizId();
    await databaseRef.child('quizzes').child(quizId).set({
      'quizId': quizId,
      'title': _titleController.text,
      'questions': _questions,
      'creatorId': user.uid,
      'players': {},
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Fermer l'indicateur de chargement
    Navigator.pop(context);

    // Recharger la liste des quiz
    _loadQuizzes();

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => QuizCreatedScreen(quizId: quizId)),
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

  //hedhy zedtha tw
  void _restartQuiz(String quizId) async {
    // Get reference to the quiz
    final quizRef = databaseRef.child('quizzes').child(quizId);

    await quizRef.update({
      'isActive': false,
      'currentQuestionIndex': 0,
      'quizEnded': false, // Set to false when restarting
    });

    setState(() {
      _quizFinished = false;
      _timeExpired = false;
      _currentQuestionIndex = 0;
    });

    // Show a message that quiz is ready to be started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quiz ready to start. Players can now join.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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

//she doesnt  use the startquiz
  void _startQuiz(String quizId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizAdminDashboard(quizId: quizId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Créer un Quiz"),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadQuizzes,
            tooltip: "Rafraîchir la liste",
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar avec la liste des quiz
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.deepPurple.shade100,
                  width: double.infinity,
                  child: Text(
                    "Mes Quiz",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _quizList.isEmpty
                          ? Center(
                              child: Text(
                                "Aucun quiz créé",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _quizList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    _quizList[index]['title'] ?? 'Sans titre',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  leading: Icon(Icons.quiz,
                                      color: Colors.deepPurple),
                                  subtitle: Text(
                                    "Questions: ${_quizList[index]['questions']?.length ?? 0}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onTap: () =>
                                      _loadQuiz(_quizList[index]['quizId']),
                                  trailing: IconButton(
                                    icon: Icon(Icons.play_arrow,
                                        color: Colors.green),
                                    tooltip: "Lancer ce quiz",
                                    //onPressed: () =>
                                    //  _startQuiz(_quizList[index]['quizId']),
                                    onPressed: () => _restartQuiz(
                                        _quizList[index]['quizId']),
                                  ),
                                );
                              },
                            ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text("Nouveau Quiz"),
                  leading: Icon(Icons.add_circle, color: Colors.green),
                  onTap: () {
                    setState(() {
                      _titleController.clear();
                      _questions.clear();
                      _resetQuestionForm();
                    });
                  },
                ),
              ],
            ),
          ),
          // Ligne verticale de séparation
          VerticalDivider(width: 1, thickness: 1),
          // Formulaire principal de création de quiz
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: "Titre du Quiz",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.title),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                                ),
                              ),
                              Chip(
                                label: Text(
                                  "${_questions.length} question(s)",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.deepPurple,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Container(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: _questions.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        "Aucune question ajoutée",
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _questions.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        elevation: 1,
                                        margin:
                                            EdgeInsets.symmetric(vertical: 5),
                                        child: ListTile(
                                          title: Text(
                                              _questions[index]['question']),
                                          subtitle: Text(
                                            "Réponse correcte: ${_questions[index]['answer']} | Temps: ${_questions[index]['time']}s",
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
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
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _questionController,
                            decoration: InputDecoration(
                              labelText: "Question",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Options de réponse",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[0] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 1",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[1] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 2",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[2] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 3",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[3] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 4",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Bonne réponse",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon:
                                        Icon(Icons.check_circle_outline),
                                  ),
                                  hint: Text("Choisissez la bonne réponse"),
                                  value: _correctAnswer,
                                  items: _options
                                      .where((option) => option.isNotEmpty)
                                      .map((option) {
                                    return DropdownMenuItem(
                                        value: option, child: Text(option));
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _correctAnswer = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _timeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Temps (en secondes)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.timer),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _resetQuestionForm,
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                ),
                                label: Text("Reset",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addQuestion,
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: Text("Add Question",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveQuiz,
                      icon: Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      label: Text("Save Quiz",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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
/*

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quiz_app/Creator/QuizAdminDashboard.dart';
import 'package:quiz_app/Shared/loginScreen.dart';
import 'dart:math';
import 'package:quiz_app/Player/quiz_created_screen.dart';

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

  List<Map<String, dynamic>> _quizList = [];
  bool _isLoading = true;

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
        _resetQuestionForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Question ajoutée avec succès!"),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
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
          backgroundColor: Colors.red.shade700,
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
          backgroundColor: Colors.orange.shade700,
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
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    String quizId = _generateQuizId();
    await databaseRef.child('quizzes').child(quizId).set({
      'quizId': quizId,
      'title': _titleController.text,
      'questions': _questions,
      'creatorId': user.uid,
      'players': {},
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    Navigator.pop(context);
    _loadQuizzes();

    await _showQuizCreatedDialog(quizId);

    _titleController.clear();
    setState(() {
      _questions.clear();
    });
  }

  Future<void> _showQuizCreatedDialog(String quizId) async {
    final qrData = 'QUIZAPP:${quizId}';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz Créé!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Code du quiz: $quizId',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.deepPurple,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Scanner ce QR code pour rejoindre le quiz',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizCreatedScreen(quizId: quizId),
                ),
              );
            },
            child: Text('Détails'),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareQuizCode(quizId),
            tooltip: "Partager le code",
          ),
        ],
      ),
    );
  }

  Future<void> _shareQuizCode(String quizId) async {
    final text = 'Rejoignez mon quiz! Code: $quizId\n'
        'Scanner ce QR code ou entrer le code dans l\'app';

    await Share.share(text, subject: 'Invitation à un quiz');
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

  void _startQuiz(String quizId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizAdminDashboard(quizId: quizId),
      ),
    );
  }

  void _showQuizQrDialog(String quizId) {
    final qrData = 'QUIZAPP:${quizId}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Code du quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$quizId',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareQuizCode(quizId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Créer un Quiz"),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 2,
        actions: [
          if (_questions.isNotEmpty && _titleController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.qr_code),
              onPressed: () => _showPreviewQrDialog(),
              tooltip: "Prévisualiser QR code",
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadQuizzes,
            tooltip: "Rafraîchir la liste",
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.deepPurple.shade100,
                  width: double.infinity,
                  child: Text(
                    "Mes Quiz",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _quizList.isEmpty
                          ? Center(
                              child: Text(
                                "Aucun quiz créé",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _quizList.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    _quizList[index]['title'] ?? 'Sans titre',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  leading: Icon(Icons.quiz,
                                      color: Colors.deepPurple),
                                  subtitle: Text(
                                    "Questions: ${_quizList[index]['questions']?.length ?? 0}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onTap: () =>
                                      _loadQuiz(_quizList[index]['quizId']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.qr_code,
                                            color: Colors.blue),
                                        onPressed: () => _showQuizQrDialog(
                                            _quizList[index]['quizId']),
                                        tooltip: "Afficher QR code",
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.play_arrow,
                                            color: Colors.green),
                                        tooltip: "Lancer ce quiz",
                                        onPressed: () => _startQuiz(
                                            _quizList[index]['quizId']),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text("Nouveau Quiz"),
                  leading: Icon(Icons.add_circle, color: Colors.green),
                  onTap: () {
                    setState(() {
                      _titleController.clear();
                      _questions.clear();
                      _resetQuestionForm();
                    });
                  },
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: "Titre du Quiz",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.title),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                                ),
                              ),
                              Chip(
                                label: Text(
                                  "${_questions.length} question(s)",
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.deepPurple,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Container(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: _questions.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        "Aucune question ajoutée",
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _questions.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        elevation: 1,
                                        margin:
                                            EdgeInsets.symmetric(vertical: 5),
                                        child: ListTile(
                                          title: Text(
                                              _questions[index]['question']),
                                          subtitle: Text(
                                            "Réponse correcte: ${_questions[index]['answer']} | Temps: ${_questions[index]['time']}s",
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
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
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _questionController,
                            decoration: InputDecoration(
                              labelText: "Question",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Options de réponse",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[0] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 1",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[1] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 2",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[2] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 3",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _options[3] = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Option 4",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Bonne réponse",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon:
                                        Icon(Icons.check_circle_outline),
                                  ),
                                  hint: Text("Choisissez la bonne réponse"),
                                  value: _correctAnswer,
                                  items: _options
                                      .where((option) => option.isNotEmpty)
                                      .map((option) {
                                    return DropdownMenuItem(
                                        value: option, child: Text(option));
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _correctAnswer = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _timeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Temps (en secondes)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.timer),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _resetQuestionForm,
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                ),
                                label: Text("Reset",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addQuestion,
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: Text("Add Question",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveQuiz,
                      icon: Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      label: Text("Save Quiz",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewQrDialog() {
    final quizId = _generateQuizId();
    final qrData = 'QUIZAPP:${quizId}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Prévisualisation QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Ceci est une prévisualisation. Le QR code final sera généré après la sauvegarde.'),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(10),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
*/