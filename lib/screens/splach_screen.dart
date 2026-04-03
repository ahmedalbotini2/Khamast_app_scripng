import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:khmsat_services/main.dart';

class SplachScreen extends StatelessWidget {
  const SplachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sailing_outlined,
              color: Colors.black,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ø®Ù…Ø³Ø§Øª',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ÇáãØæÑ: ALBASHA',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
      splashTransition: SplashTransition.fadeTransition,
      nextScreen: MainPage(),
      backgroundColor: const Color(0xFF111111),
    );
  }
}
