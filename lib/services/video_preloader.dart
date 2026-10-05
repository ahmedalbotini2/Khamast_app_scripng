import 'package:flutter/foundation.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:video_player/video_player.dart';

class VideoPreloader {
  VideoPreloader._();

  static VideoPlayerController? _controller;
  static Future<void>? _preloadFuture;
  static bool _consumed = false;

  /// يبدأ تحميل الفيديو إن لم يكن بدأ فعلاً. آمن لاستدعائه أكثر من مرة.
  static Future<void> preload() {
    _preloadFuture ??= _load();
    return _preloadFuture!;
  }

  static Future<void> _load() async {
    try {
      final controller = VideoPlayerController.asset(VideoApp.backgrond);
      _controller = controller;
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0);
  
      await controller.play();
      await controller.pause();
      await controller.seekTo(Duration.zero);
    } catch (e) {
      debugPrint('فشل التحميل المسبق لفيديو الربط: $e');
    }
  }

  /// تُستدعى من LinkedScreen. تُرجع الكونترولر الجاهز إن وُجد،
  /// وتُعلّمه كـ "مُستهلَك" حتى لا يُحرَّر بالخطأ من disposeIfUnused لاحقاً.
  static VideoPlayerController? takeController() {
    _consumed = true;
    return _controller;
  }


  static void disposeIfUnused() {
    if (!_consumed) {
      _controller?.dispose();
      _controller = null;
      _preloadFuture = null;
    }
  }
}
