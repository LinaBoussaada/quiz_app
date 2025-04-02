import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_app/createQuizScreen.dart';
import 'package:quiz_app/joinQuizScreen.dart';
import 'package:quiz_app/loginScreen.dart'; // Import de l'écran de connexion

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quiz App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  // 🔹 Si l'utilisateur n'est PAS connecté → Aller au login
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } else {
                  // 🔹 Si l'utilisateur est connecté → Aller directement à CreateQuiz
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateQuizScreen()),
                  );
                }
              },
              child: Text("Create a Quiz"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 🔹 Joindre un quiz sans connexion
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JoinQuizScreen()),
                );
              },
              child: Text("Join a Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}
