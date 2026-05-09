// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:html/parser.dart' as parser;
// import 'package:khmsat_services/resources/data.dart';
// import 'package:khmsat_services/services/services_scrept.dart';
// import 'dart:async';

// class WebScrepingOrder {
//   String orderId = WebScrepingServices.orderId;
//   String get url => 'https://khamsat.com/community/requests/$orderId';

//   static String timeOrder ='' ;
//   // دالة الاستخراج الجديدة باستخدام HeadlessWebView
//   Future<List<DataList>> extractData() async {
//     final List<DataList> servicesList = [];
//     final Completer<List<DataList>> completer = Completer();

//     debugPrint('Starting Headless WebView for: $url');

//     // إعداد المتصفح الخفي
//     HeadlessInAppWebView? headlessWebView;

//     headlessWebView = HeadlessInAppWebView(
//       initialUrlRequest: URLRequest(url: WebUri(url)),
//       initialSettings: InAppWebViewSettings(
//         userAgent:
//             "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
//         useShouldInterceptRequest: true,
//       ),
//       onLoadStop: (controller, url) async {
//         debugPrint('Page Loaded, waiting 2 seconds for security challenges...');

//         await Future.delayed(const Duration(seconds: 3));

//         // سحب كود HTML من المتصفح بعد التحميل التام
//         String? html = await controller.getHtml();

//         if (html != null && html.isNotEmpty) {
//           final document = parser.parse(html);

//           // 1. استخراج بيانات الطلب
//           // final ownerDescription =
//           //     document.querySelector('article.replace_urls')?.text.trim() ?? "";
//           // descriptionOrder = ownerDescription;
//           // debugPrint('Description Found: ${ownerDescription.isNotEmpty}');

//           // final orderTitle = document.querySelector('h1')?.text.trim() ?? "";
//           // nameOrder = orderTitle;
//           // debugPrint('Description Found: ${orderTitle.isNotEmpty}');

//           // final imageElement =
//           //     document.querySelector('img.u-circle')?.attributes['src']?.trim() ?? "";
//           // imageOrder = imageElement;
//           // debugPrint('Description Found: ${imageElement!.isNotEmpty}');


//           final timeAgo = document.querySelector('.col-6 span')?.text.trim() ??"";
//           timeOrder = timeAgo;
//           // 2. استخراج التعليقات
//           final commentElements = document.querySelectorAll(
//             '.discussion-item.comment',
//           );

//           for (final element in commentElements) {
//             final commenterName =
//                 element.querySelector('.meta--user a')?.text.trim() ??
//                 'مستخدم مجهول';

//             final commenterImage =
//                 element.querySelector('.meta--avatar img')?.attributes['src'] ??
//                 '';

//             final commentText =
//                 element.querySelector('article.reply_content')?.text.trim() ??
//                 '';

//             String finalImageUrl = commenterImage;
//             if (finalImageUrl.startsWith('//')) {
//               finalImageUrl = 'https:$finalImageUrl';
//             }

//             servicesList.add(
//               DataList(
//                 name: commenterName,
//                 image: finalImageUrl,
//                 description: commentText,
//               ),
//             );

//             servicesList.add(
//               DataList(
//                 name: commenterName,
//                 image: commenterImage,
//                 description: commentText,
//               ),
//             );
//           }
//         }

//         debugPrint('Total items scraped: ${servicesList.length}');

//         // إنهاء العمل وتحرير الموارد
//         completer.complete(servicesList);
//         headlessWebView?.dispose();
//       },
//       onLoadError: (controller, url, code, message) {
//         debugPrint('WebView Error: $message');
//         if (!completer.isCompleted) completer.complete([]);
//         headlessWebView?.dispose();
//       },
//     );

//     // تشغيل المتصفح الخفي
//     await headlessWebView.run();

//     return completer.future;
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;
import 'package:khmsat_services/resources/data.dart';
import 'dart:async';

class WebScrepingOrder {
  final String orderId;
  WebScrepingOrder({required this.orderId});

  String get url => 'https://khamsat.com/community/requests/$orderId';

  // متغيرات لتخزين بيانات صاحب الطلب (ليست static لضمان التجديد)
  String timeOrder = '';
  String orderTitle = '';
  String orderDescription = '';
  String orderOwnerImage = '';

  Future<List<DataList>> extractData() async {
    final List<DataList> servicesList = [];
    final Completer<List<DataList>> completer = Completer();

    debugPrint('البدء بجلب بيانات الطلب رقم: $orderId');

    HeadlessInAppWebView? headlessWebView;

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
        clearCache: true, // مسح الكاش لضمان بيانات جديدة
      ),
      onLoadStop: (controller, url) async {
        // انتظر قليلاً لضمان تحميل الـ JavaScript وتخطي الحماية
        await Future.delayed(const Duration(seconds: 3));

        String? html = await controller.getHtml();

        if (html != null && html.isNotEmpty) {
          final document = parser.parse(html);

          // 1. استخراج بيانات "الطلب الرئيسي" (التي ستظهر في الـ SliverAppBar)
          
          // العنوان
          orderTitle = document.querySelector('h1')?.text.trim() ?? "بدون عنوان";
          
          // وصف الطلب
          orderDescription = document.querySelector('article.replace_urls')?.text.trim() ?? "";
          
          // صورة صاحب الطلب
          final imgElement = document.querySelector('img.u-circle');
          orderOwnerImage = imgElement?.attributes['src'] ?? "";
          if (orderOwnerImage.startsWith('//')) orderOwnerImage = 'https:$orderOwnerImage';

          // وقت النشر
          timeOrder = document.querySelector('.col-6 span')?.text.trim() ?? "";

          debugPrint('تم استخراج بيانات الطلب الرئيسي: $orderTitle');

          // 2. استخراج "التعليقات" (التي ستظهر في القائمة)
          final commentElements = document.querySelectorAll('.discussion-item.comment');

          for (final element in commentElements) {
            final commenterName = element.querySelector('.meta--user a')?.text.trim() ?? 'مستخدم مجهول';
            
            final commenterImage = element.querySelector('.meta--avatar img')?.attributes['src'] ?? '';
            String finalImageUrl = commenterImage.startsWith('//') ? 'https:$commenterImage' : commenterImage;

            final commentText = element.querySelector('article.reply_content')?.text.trim() ?? '';

            if (commentText.isNotEmpty) {
              servicesList.add(
                DataList(
                  name: commenterName,
                  image: finalImageUrl,
                  description: commentText,
                ),
              );
            }
          }
        }

        debugPrint('إجمالي التعليقات المستخرجة: ${servicesList.length}');
        
        if (!completer.isCompleted) completer.complete(servicesList);
        await headlessWebView?.dispose();
      },
      onLoadError: (controller, url, code, message) {
        debugPrint('حدث خطأ أثناء التحميل: $message');
        if (!completer.isCompleted) completer.complete([]);
        headlessWebView?.dispose();
      },
    );

    await headlessWebView.run();
    return completer.future;
  }
}