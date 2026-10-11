
import 'package:flutter/material.dart';
import 'package:khmsat_services/screens/ai/model/chat_circle.dart';

class BackgroundDecor extends StatelessWidget {
  const BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4D6), Color(0xFFF7F3EA), Color(0xFFFFFFFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: SoftCircle(
              size: 220,
              colors: [Color(0xFFFFE7A3), Color(0xFFFFF4D6)],
            ),
          ),
          Positioned(
            top: 180,
            left: -60,
            child: SoftCircle(
              size: 180,
              colors: [Color(0xFFE7E2D4), Color(0xFFFFFFFF)],
            ),
          ),
          Positioned(
            bottom: -90,
            right: -30,
            child: SoftCircle(
              size: 210,
              colors: [Color(0xFFD4AF37), Color(0xFFFFE7A3)],
            ),
          ),
        ],
      ),
    );
  }
}
