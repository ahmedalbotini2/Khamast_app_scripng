import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/services/notification.dart';
import 'package:khmsat_services/services/services_scrept.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تهيئة الخدمة الخلفية (تُستدعى مرة واحدة من main)
Future<void> initializeServiceBackground() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      //foregroundServiceTypes: [AndroidForegroundType.dataSync],
      autoStart: true, // تبدأ مرة واحدة عند التشغيل
      initialNotificationTitle: 'التطبيق يعمل في الخلفية',
      initialNotificationContent: 'يتم عرض الإشعارات...',
    ),
    iosConfiguration: IosConfiguration(onForeground: onStart),
  );

  debugPrint("✅ Background Service configured");
}
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. ضمان الربط مع النظام الأساسي (ضروري جداً لمنع الكراش)
  DartPluginRegistrant.ensureInitialized();

  // 2. إذا كنت تستخدم أندرويد، يجب ضبط الإشعار الدائم
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // تهيئة الأدوات داخل الـ Isolate
  final WebScrepingServices scraper = WebScrepingServices();
  
  // ملاحظة: SharedPreferences.getInstance() قد يفشل أحياناً إذا استدعي فوراً
  // سنقوم بوضعه داخل التايمر لضمان استقرار التشغيل
  
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // 1. استخراج البيانات
      List<DataList> items = await scraper.extractData();

      if (items.isNotEmpty) {
        final latestItem = items.first;
        String currentOrderId = latestItem.name; 

        String? lastNotifiedId = prefs.getString('last_notified_order');

        if (currentOrderId != lastNotifiedId) {
          // 4. إرسال الإشعار (تأكد من إحاطتها بـ try-catch داخلية)
          try {
            await NotificationService.showAlertWithImage(
              title:  "${latestItem.name}",
              body: latestItem.description,
              imageUrl: latestItem.image.startsWith('http')
                  ? latestItem.image
                  : "https:${latestItem.image}",
            );
            
            // تحديث التخزين فقط بعد نجاح إرسال الإشعار
            await prefs.setString('last_notified_order', currentOrderId);
          } catch (e) {
            print("Notification Error: $e");
          }
        }
      }
    } catch (e) {
      print("Scraping Background Error: $e");
    }
  });
}