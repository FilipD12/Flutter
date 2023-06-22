import 'package:flutter/material.dart';
import 'package:my_polls/Providers/authentication_provider.dart';
import 'package:my_polls/Screens/main_activity_page.dart';
import 'package:my_polls/Utils/message.dart';
import 'package:my_polls/Utils/router.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background_image.jpg'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2855AE), Color(0xFF72A2FF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  "Questorium",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Polls creator app",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 150.0),
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isButtonPressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isButtonPressed = false;
                      });
                      AuthProvider().signInWithGoogle().then((value) {
                        if (value.user == null) {
                          error(context, message: "Please try again");
                        } else {
                          nextPageOnly(context, const MainActivityPage());
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 50,
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 270),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          // Add your desired box shadow here
                        ],
                        gradient: LinearGradient(
                          colors: _isButtonPressed
                              ? const [Color(0xFF72A2FF), Color(0xFF2855AE)]
                              : const [Color(0xFF2855AE), Color(0xFF72A2FF)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1.0),
                      child: Opacity(
                        opacity: 0.8,
                        child: Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Image.asset(
                      'images/googlelogo.png', // Replace with your actual image path
                      height: 30,
                      width: 30,
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
