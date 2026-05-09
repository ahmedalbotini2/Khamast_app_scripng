import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khmsat_services/resources/resources.dart';

import 'package:khmsat_services/screens/linked_screen.dart';
import 'package:khmsat_services/screens/main_screen.dart';

class SplachScreen extends StatefulWidget {
  const SplachScreen({super.key});

  @override
  State<SplachScreen> createState() => _SplachScreenState();
}

class _SplachScreenState extends State<SplachScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  late Future<Widget> _nextScreenFuture;

  @override
  void initState() {
    super.initState();
   
    _nextScreenFuture = checkLogin();
  }

  Future<Widget> checkLogin() async {
   
    try {
      String? storedName = await storage.read(key: 'saved_username');
      String? storedCookies = await storage.read(key: 'session_cookies');
      if (storedName != null && storedCookies != null) {
        return MainScreen();
      } else {
        return LinkedScreen();
      }
    } catch (e) {
      debugPrint("Error for in chacked key:$e");
      return LinkedScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _nextScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF111111),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return AnimatedSplashScreen(
          splash: Center(
            child: Image.asset(ImageApp.logo, width: 150, height: 150),
          ),
          splashTransition: SplashTransition.fadeTransition,
          nextScreen: snapshot.data!,
          backgroundColor: const Color(0xFF111111),
        );
      },
    );
  }
}
