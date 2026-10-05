import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:khmsat_services/services/video_preloader.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:khmsat_services/screens/linked_screen.dart';
import 'package:khmsat_services/screens/main_screen.dart';

class SplachScreen extends StatefulWidget {
  const SplachScreen({super.key});

  @override
  State<SplachScreen> createState() => _SplachScreenState();
}

class _SplachScreenState extends State<SplachScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<Widget> checkLogin() async {
    // نبدأ تحميل فيديو شاشة الربط فوراً وبالتوازي مع فحص تسجيل الدخول،
    // حتى لو تبيّن لاحقاً أن المستخدم مسجّل دخول ولن يحتاجه أصلاً.
    final videoPreloadFuture = VideoPreloader.preload();

    try {
      String? storedName = await storage.read(key: 'saved_username');
      String? storedCookies = await storage.read(key: 'session_cookies');

      if (storedName != null && storedCookies != null) {
        // المستخدم مسجّل دخول أصلاً، ما راح يمر بشاشة الفيديو
        VideoPreloader.disposeIfUnused();
        return const MainScreen();
      }

      // هل تخطّى المستخدم صفحة الترحيب سابقاً؟ إن كان كذلك لا تظهر له مرة أخرى
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool welcomeSeen =
          prefs.getBool(LinkedScreen.welcomeSeenKey) ?? false;

      if (welcomeSeen) {
        VideoPreloader.disposeIfUnused();
        return const MainScreen();
      }

      // أول دخول: ننتظر اكتمال تحميل الفيديو (إن لم يكن اكتمل) حتى تظهر شاشة
      // الترحيب والفيديو جاهز للتشغيل فوراً بدون أي لودنج أو شاشة سوداء
      await videoPreloadFuture;
      return const LinkedScreen();
    } catch (e) {
      debugPrint("Error for in chacked key:$e");
      await videoPreloadFuture;
      return const LinkedScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // يعرض اللوجو فوراً بلا أي شاشة تحميل قبله، وينفّذ checkLogin
    // بالخلفية أثناء عرض اللوجو، وينتقل تلقائياً بعد اكتمالها
    return AnimatedSplashScreen.withScreenFunction(
      splash: Image.asset(ImageApp.logo, width: 150, height: 150),
      screenFunction: checkLogin,
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: const Color(0xFF111111),
    );
  }
}