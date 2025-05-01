import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/Player/JoinQuizScreen.dart';
import 'package:quiz_app/Player/QuizScreen.dart';
import 'package:quiz_app/Creator/createQuizScreen.dart';
import 'package:quiz_app/Shared/loginScreen.dart';
/*
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showJoinBar = true;
  final TextEditingController _quizCodeController = TextEditingController();
  bool _isVerifying = false;
  final databaseRef = FirebaseDatabase.instance.ref();

  Future<void> _verifyAndJoinQuiz() async {
    final quizCode = _quizCodeController.text.trim();

    //if (quizCode.isEmpty) {
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    // content: Text("Please enter a quiz code"),
    //backgroundColor: Colors.red,
//      ));
    // return;
//    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify if quiz exists
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(quizCode).get();

      setState(() {
        _isVerifying = false;
      });

      if (snapshot.exists) {
        // Quiz exists, navigate to JoinQuizScreen with the code
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JoinQuizScreen(initialQuizCode: quizCode),
          ),
        );
      } else {
        // Quiz does not exist
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid quiz code. Please check and try again."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error verifying quiz: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/icon.jpeg',
                  height: 30,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Mentimeter",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                _NavItem(text: "Business"),
                _NavItem(text: "Education"),
                _NavItem(text: "Enterprise"),
                _NavItem(text: "Learn"),
                _NavItem(text: "Pricing"),
                _NavItem(text: "Talk to sales"),
                const SizedBox(width: 10),

                // Show different buttons based on login status
                if (isLoggedIn)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateQuizScreen()),
                      );
                    },
                    child: const Text(
                      "Go To Home",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (showJoinBar)
            Container(
              color: const Color(0xFFE3E4FD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    "Enter code to join a live Menti",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    height: 35,
                    child: TextField(
                      controller: _quizCodeController,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        hintText: "1234 5678",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // filled: true,
                        // fillColor: Colors.white,
                      ),
                      // keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _isVerifying
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _verifyAndJoinQuiz,
                          child: const Text("Join"),
                        ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        showJoinBar = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 60),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "What will you ask your audience?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Turn presentations into conversations with interactive polls\nthat engage meetings and classrooms.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CreateQuizScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        }
                      },
                      child: Text(
                        isLoggedIn
                            ? "Go to my presentation"
                            : "Get started, it's free",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "No credit card needed",
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quizCodeController.dispose();
    super.dispose();
  }
}

class _NavItem extends StatelessWidget {
  final String text;
  const _NavItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () {},
        child: Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/Player/JoinQuizScreen.dart';
import 'package:quiz_app/Creator/createQuizScreen.dart';
import 'package:quiz_app/Shared/loginScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showJoinBar = true;
  final TextEditingController _quizCodeController = TextEditingController();
  bool _isVerifying = false;
  final databaseRef = FirebaseDatabase.instance.ref();
  bool isMobile = false;

  Future<void> _verifyAndJoinQuiz() async {
    final quizCode = _quizCodeController.text.trim();

    setState(() {
      _isVerifying = true;
    });

    try {
      DataSnapshot snapshot =
          await databaseRef.child('quizzes').child(quizCode).get();

      setState(() {
        _isVerifying = false;
      });

      if (snapshot.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JoinQuizScreen(initialQuizCode: quizCode),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Code de quiz invalide. Veuillez vérifier et réessayer."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erreur de vérification: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;
    isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMobile
          ? _buildMobileAppBar(context)
          : _buildDesktopAppBar(context, isLoggedIn),
      drawer: isMobile ? _buildMobileDrawer(isLoggedIn) : null,
      body: Column(
        children: [
          if (showJoinBar) _buildJoinBar(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 800,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Que voulez-vous demander à votre audience ?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Transformez les présentations en conversations avec des sondages interactifs qui engagent les réunions et les salles de classe.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          if (isLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreateQuizScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          }
                        },
                        child: Text(
                          isLoggedIn
                              ? "Accéder à mes présentations"
                              : "Commencer, c'est gratuit",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Aucune carte de crédit nécessaire",
                        style: TextStyle(color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/icon.jpeg',
            height: 30,
          ),
          const SizedBox(width: 8),
          const Text(
            "Mentimeter",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ],
    );
  }

  Widget _buildMobileDrawer(bool isLoggedIn) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/icon.jpeg',
                  height: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Mentimeter",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Business'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Education'),
            onTap: () {},
          ),
          // Ajoutez d'autres éléments de menu ici...
          const Divider(),
          if (isLoggedIn)
            ListTile(
              title: const Text('Go To Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateQuizScreen()),
                );
              },
            )
          else ...[
            ListTile(
              title: const Text('Log in'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Sign up'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(
      BuildContext context, bool isLoggedIn) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                'assets/images/icon.jpeg',
                height: 30,
              ),
              const SizedBox(width: 8),
              const Text(
                "Mentimeter",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              _NavItem(text: "Business"),
              _NavItem(text: "Education"),
              _NavItem(text: "Enterprise"),
              _NavItem(text: "Learn"),
              _NavItem(text: "Pricing"),
              _NavItem(text: "Talk to sales"),
              const SizedBox(width: 10),
              if (isLoggedIn)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateQuizScreen()),
                    );
                  },
                  child: const Text(
                    "Go To Home",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Log in",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Sign up",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinBar() {
    return Container(
      color: const Color(0xFFE3E4FD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: isMobile
          ? Column(
              children: [
                const Text(
                  "Entrez le code pour rejoindre un Menti en direct",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: TextField(
                          controller: _quizCodeController,
                          decoration: InputDecoration(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            hintText: "1234 5678",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _isVerifying
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _verifyAndJoinQuiz,
                            child: const Text("Join"),
                          ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                const Text(
                  "Enter code to join a live Menti",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  height: 35,
                  child: TextField(
                    controller: _quizCodeController,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      hintText: "1234 5678",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _isVerifying
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _verifyAndJoinQuiz,
                        child: const Text("Join"),
                      ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      showJoinBar = false;
                    });
                  },
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _quizCodeController.dispose();
    super.dispose();
  }
}

class _NavItem extends StatelessWidget {
  final String text;
  const _NavItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () {},
        child: Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
