import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:khmsat_services/screens/main_screen.dart';
import 'package:khmsat_services/screens/web_screen.dart';
import 'package:khmsat_services/services/video_preloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class LinkedScreen extends StatefulWidget {
  const LinkedScreen({super.key});

  /// مفتاح يُحفظ عند تخطي الترحيب، ويقرؤه SplachScreen حتى لا تظهر الصفحة مجدداً
  static const String welcomeSeenKey = 'welcome_seen';

  @override
  State<LinkedScreen> createState() => _LinkedScreenState();
}

class _LinkedScreenState extends State<LinkedScreen> {
  late VideoPlayerController controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    final preloaded = VideoPreloader.takeController();
    if (preloaded != null && preloaded.value.isInitialized) {
      controller = preloaded;
      controller.play();
      return;
    }

    preloaded?.dispose();
    controller = VideoPlayerController.asset(VideoApp.backgrond);
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {
            controller.setLooping(true);
            controller.setVolume(0.0);
            controller.play();
          });
        })
        .catchError((e) {
          debugPrint('فشل تحميل فيديو الخلفية: $e');
          if (!mounted) return;
          setState(() => _hasError = true);
        });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _goToWebScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WebScreen()),
    );
  }

  Future<void> _skip() async {
    // نسجّل أن المستخدم تخطّى الترحيب، فلا تظهر له هذه الصفحة بعد الآن
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(LinkedScreen.welcomeSeenKey, true);
    } catch (e) {
      debugPrint('تعذّر حفظ حالة تخطي الترحيب: $e');
    }

    if (!mounted) return;

    // pushReplacement: لا يمكن الرجوع لهذه الصفحة بزر الرجوع
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          // طبقة الفيديو بالخلفية
          SizedBox.expand(
            child:
                controller.value.isInitialized
                    ? AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          child: VideoPlayer(controller),
                          height: controller.value.size.height,
                        ),
                      ),
                    )
                    : Center(
                      child:
                          _hasError
                              ? const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white24,
                                size: 40,
                              )
                              : const CircularProgressIndicator(
                                color: Color(0xFFD4AF37),
                              ),
                    ),
          ),

          // تغميق خفيف فوق الفيديو لتحسين وضوح اللوجو والنص والأزرار
          // (تقدر تشيله لو ما تبيه، بس يحافظ على تباين ثابت بغض النظر عن محتوى الفيديو)
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x33000000)),
            ),
          ),

          // اللوجو + الوصف في منتصف الشاشة
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(ImageApp.wellcomeIcon, width: 110, height: 110),
                  const SizedBox(height: 20),
                  Text(
                    'خمسات هو أكبر سوق عربي للخدمات الرقمية، يربط المستقلين المبدعين بروّاد الأعمال والشركات لتوفير حلول سريعة تلبي احتياجاتهم بجودة عالية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // الأزرار بالأسفل: زر الربط الرئيسي + زر التخطي
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: InkWell(
                        onTap: _goToWebScreen,
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            // نفس الشفافية الأصلية، مع حدّ أوضح وظل خفيف يعطي تبايناً
                            // واضحاً بغض النظر عن لون الفيديو خلفه
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.55),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            "ربط حسابك الموجود في موقع خمسات",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                BoxShadow(
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
                  const SizedBox(height: 10),
                  MaterialButton(
                    onPressed: _skip,
                    color: Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      "تخطي الى الصفحة الرئيسية",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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