import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String _taskName = 'khmsat_check_latest';
const String _prefKeyLastTitle = 'last_item_title';
const String _prefKeyLastImage = 'last_item_image';
const String _khamsatUrl = 'https://khamsat.com/community/requests';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

class NotificationWorker {
  static Future<void> initialize() async {
    await _initNotifications();
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _taskName) {
      await _initNotifications();
      await _checkAndNotifyLatest();
    }
    return Future.value(true);
  });
}

Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings =
      InitializationSettings(android: androidInit);
  await _notifications.initialize(settings);

  final androidPlugin =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
}

Future<void> _checkAndNotifyLatest() async {
  try {
    final latest = await _fetchLatestItem();
    if (latest == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastTitle = prefs.getString(_prefKeyLastTitle) ?? '';
    final lastImage = prefs.getString(_prefKeyLastImage) ?? '';

    if (latest.title == lastTitle && latest.imageUrl == lastImage) {
      return;
    }

    await prefs.setString(_prefKeyLastTitle, latest.title);
    await prefs.setString(_prefKeyLastImage, latest.imageUrl);

    await _showNotification(latest.title, latest.imageUrl);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Background check failed: $e');
    }
  }
}

Future<_LatestItem?> _fetchLatestItem() async {
  final response = await http.get(Uri.parse(_khamsatUrl));
  if (response.statusCode != 200) {
    return null;
  }

  final document = parser.parse(response.body);
  final firstPost = document.querySelector('#forums_table tr.forum_post');
  if (firstPost == null) {
    return null;
  }

  final image = firstPost.querySelector('td.avatar-td img')?.attributes['src'] ?? '';
  final title =
      firstPost.querySelector('h3.details-head a')?.text.trim() ?? 'خمسات';

  return _LatestItem(title: title, imageUrl: image);
}

Future<void> _showNotification(String title, String imageUrl) async {
  final String? bigPicturePath = await _downloadImage(imageUrl);

  final AndroidNotificationDetails androidDetails;
  if (bigPicturePath != null) {
    androidDetails = AndroidNotificationDetails(
      'khmsat_latest_channel',
      'Khmsat Latest',
      channelDescription: 'Latest requests from Khmsat community',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        contentTitle: title,
        summaryText: 'أحدث طلب في القائمة',
      ),
    );
  } else {
    androidDetails = const AndroidNotificationDetails(
      'khmsat_latest_channel',
      'Khmsat Latest',
      channelDescription: 'Latest requests from Khmsat community',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  await _notifications.show(
    1001,
    title,
    'أحدث طلب في القائمة',
    NotificationDetails(android: androidDetails),
  );
}

Future<String?> _downloadImage(String url) async {
  if (url.isEmpty) return null;
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/khmsat_latest.jpg';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  } catch (_) {
    return null;
  }
}

class _LatestItem {
  final String title;
  final String imageUrl;

  _LatestItem({required this.title, required this.imageUrl});
}
