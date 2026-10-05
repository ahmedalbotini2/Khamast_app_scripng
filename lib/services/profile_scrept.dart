import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:khmsat_services/resources/data.dart';

class WebScrepingPortfolio {
  final String username;
  final String cookies;

  WebScrepingPortfolio({required this.username, required this.cookies});

  String get url => 'https://khamsat.com/user/$username';

  String? displayName;
  String? avatarUrl;
  String? bio;

  /// يجلب الـ HTML عبر WebView مخفي ويتجاوز تحدي AWS WAF
  Future<String?> _fetchHtml() async {
    final completer = Completer<String?>();
    String? lastHtml;
    HeadlessInAppWebView? headless;

    bool isChallengePage(String html) =>
        html.contains('challenge-container') ||
        html.contains('AwsWafIntegration') ||
        html.contains('awsWafCookieDomainList');

    headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
      onLoadStop: (controller, _) async {
        final html = await controller.evaluateJavascript(
          source: 'document.documentElement.outerHTML',
        );
        if (html is! String) return;
        lastHtml = html;
        final challenge = isChallengePage(html);
        debugPrint(
          'PROFILE onLoadStop length=${html.length} challenge=$challenge',
        );
        // نكتفي بالصفحة الحقيقية فقط (بعد أن يعيد التحدي تحميل الصفحة)
        if (!challenge && !completer.isCompleted) {
          completer.complete(html);
        }
      },
    );

    try {
      await headless.run();
      return await completer.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => lastHtml,
      );
    } finally {
      await headless.dispose();
    }
  }

  Future<List<DataList>> extractData() async {
    final List<DataList> servicesList = [];
    try {
      final html = await _fetchHtml();
      debugPrint('PROFILE html length=${html?.length}');
      if (html == null || html.isEmpty) return servicesList;

      final document = parser.parse(html);

      String clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

      // يجد البطاقة (.card) من نص عنوانها (h3 داخل card-header)
      dom.Element? cardByTitle(String title) {
        for (final card in document.querySelectorAll('.card')) {
          final h = card.querySelector('.card-header h3')?.text ?? '';
          if (clean(h) == title) return card;
        }
        return null;
      }

      // --- الاسم والصورة ---
      displayName = document.querySelector('h1')?.text.trim() ?? "بدون اسم";
      avatarUrl =
          document
              .querySelector('meta[property="og:image"]')
              ?.attributes['content'] ??
          "";

      // --- النبذة الشخصية ---
      String? aboutText;
      final aboutBody = cardByTitle('نبذة عني')?.querySelector('.card-body');
      if (aboutBody != null) {
        for (final br in aboutBody.querySelectorAll('br')) {
          br.replaceWith(dom.Text('\n'));
        }
        aboutText = aboutBody.text
            .split('\n')
            .map((l) => l.trim())
            .join('\n')
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();
      }
      bio = (aboutText == null || aboutText.isEmpty)
          ? "لا توجد نبذة شخصية"
          : aboutText;

      // --- الخدمات ---
      final servicesCard = cardByTitle('خدماتي');
      final serviceElements = servicesCard != null
          ? servicesCard.querySelectorAll('.service-card')
          : document.querySelectorAll('.service-card');

      debugPrint(
        'PROFILE about=${aboutBody != null} services=${serviceElements.length}',
      );

      for (final element in serviceElements) {
        final link = element.querySelector('.product-title a');
        final title = clean(link?.attributes['title'] ?? link?.text ?? '');

        final serviceImage =
            element.querySelector('.product-img')?.attributes['src'] ?? '';

        final category = element
            .querySelectorAll('.product-category a')
            .map((a) => clean(a.text))
            .where((t) => t.isNotEmpty)
            .join(' / ');
        final price = clean(
          element.querySelector('.product-price')?.text ?? '',
        );
        final details =
            [category, price].where((t) => t.isNotEmpty).join(' · ');

        servicesList.add(
          DataList(
            name: title.isEmpty ? 'بدون عنوان' : title,
            image: serviceImage,
            description: details,
          ),
        );
      }
    } catch (e) {
      debugPrint('خطأ في الاتصال: $e');
    }
    return servicesList;
  }
}