import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:khmsat_services/screens/web_screen.dart';
import 'package:video_player/video_player.dart';

class LinkedScreen extends StatefulWidget {
  const LinkedScreen({super.key});

  @override
  State<LinkedScreen> createState() => _LinkedScreenState();
}

class _LinkedScreenState extends State<LinkedScreen> {
  late VideoPlayerController controller;
  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset(VideoApp.backgrond)
      ..initialize().then((_) {
        setState(() {
          controller.setLooping(true);
          controller.setVolume(0.0);
          controller.play();
        });
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child:
                controller.value.isInitialized
                    ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        child: VideoPlayer(controller),
                        height: controller.value.size.height,
                      ),
                    )
                    : Center(child: Text('Loading...')),
          ),
          const IgnorePointer(),
          Positioned(
            bottom: 100, // المسافة من أسفل الشاشة (غير الرقم ليرتفع أو ينزل)
            left: 0,
            right: 0,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: InkWell(
                      onTap:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebScreen(),
                            ),
                          ),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 30,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "ربط حسابك الموجود في موقع خمسات",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Hollow world',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
