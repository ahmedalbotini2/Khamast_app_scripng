import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/services/services_scrept.dart';
import 'dart:async';

class WebScrepingOrder {
  String orderId = WebScrepingServices.orderId;
  String get url => 'https://khamsat.com/community/requests/$orderId';
  static String descriptionOrder = '';

  // دالة الاستخراج الجديدة باستخدام HeadlessWebView
  Future<List<DataList>> extractData() async {
    final List<DataList> servicesList = [];
    final Completer<List<DataList>> completer = Completer();

    debugPrint('Starting Headless WebView for: $url');

    // إعداد المتصفح الخفي
    HeadlessInAppWebView? headlessWebView;

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        userAgent:
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
        useShouldInterceptRequest: true,
      ),
      onLoadStop: (controller, url) async {
        debugPrint('Page Loaded, waiting 2 seconds for security challenges...');

     
        await Future.delayed(const Duration(seconds: 3));

        // سحب كود HTML من المتصفح بعد التحميل التام
        String? html = await controller.getHtml();

        if (html != null && html.isNotEmpty) {
          final document = parser.parse(html);

          // 1. استخراج وصف الطلب
          final ownerDescription =
              document.querySelector('article.replace_urls')?.text.trim() ?? "";
          descriptionOrder = ownerDescription;
          debugPrint('Description Found: ${ownerDescription.isNotEmpty}');

          // 2. استخراج التعليقات
          final commentElements = document.querySelectorAll(
            '.discussion-item.comment',
          );

          for (final element in commentElements) {
            // 1. اسم المعلق (الوصول عبر الكلاس meta--user)
            final commenterName =
                element.querySelector('.meta--user a')?.text.trim() ??
                'مستخدم مجهول';

         
            final commenterImage =
                element.querySelector('.meta--avatar img')?.attributes['src'] ??
                '';

            // 3. نص التعليق
            final commentText =
                element.querySelector('article.reply_content')?.text.trim() ??
                '';

            // نصيحة إضافية: التأكد من بروتوكول الرابط
            String finalImageUrl = commenterImage;
            if (finalImageUrl.startsWith('//')) {
              finalImageUrl = 'https:$finalImageUrl';
            }

            servicesList.add(
              DataList(
                name: commenterName,
                image: finalImageUrl,
                description: commentText,
              ),
            );

            servicesList.add(
              DataList(
                name: commenterName,
                image: commenterImage,
                description: commentText,
              ),
            );
          }
        }

        debugPrint('Total items scraped: ${servicesList.length}');

        // إنهاء العمل وتحرير الموارد
        completer.complete(servicesList);
        headlessWebView?.dispose();
      },
      onLoadError: (controller, url, code, message) {
        debugPrint('WebView Error: $message');
        if (!completer.isCompleted) completer.complete([]);
        headlessWebView?.dispose();
      },
    );

    // تشغيل المتصفح الخفي
    await headlessWebView.run();

    return completer.future;
  }
}
