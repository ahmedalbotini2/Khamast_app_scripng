import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static bool _initialized = false;
  // توحيد المعرف في متغير واحد لضمان عدم الخطأ
  static const String _channelId = 'khamsat_orders_urgent';

  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId, // المعرف الموحد
      'new_notification',
      description: 'تنبيهات فورية عند نشر طلبات جديدة في مجتمع خمسat',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  static Future<void> showAlertWithImage({
    required String title,
    required String body,
    required String imageUrl,
  }) async {
    await init();

    // تعديل بسيط: استخدام ID الطلب في اسم الملف لتجنب تداخل الصور
    final String fileName = 'avatar_${DateTime.now().millisecond}';
    final String imagePath = await _downloadAndSaveFile(imageUrl, fileName);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          'new_notification',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: FilePathAndroidBitmap(imagePath), // الصورة الجانبية
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
          icon: '@mipmap/ic_launcher',
        );

    int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<String> _downloadAndSaveFile(
    String url,
    String fileName,
  ) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
