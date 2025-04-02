import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/createQuizScreen.dart';
import 'package:quiz_app/homeScreen.dart';
import 'firebase_options.dart'; // Assure-toi d'importer ce fichier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ajout de cette ligne
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Creator',
      theme: ThemeData(primarySwatch: Colors.blue),
      //home: CreateQuizScreen(),
      home: HomeScreen(),
    );
  }
}
