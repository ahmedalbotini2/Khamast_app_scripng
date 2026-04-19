import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:khmsat_services/resources/data.dart';



// --- الكود الأول: منطق السكرابينج المعدل قليلًا ---
class WebScrepingPortfolio {
  final String username;
  final String cookies;

  WebScrepingPortfolio({required this.username, required this.cookies});

  String get url => 'https://khamsat.com/user/$username';

  String? displayName;
  String? avatarUrl;
  String? bio;

  Future<List<DataList>> extractData() async {
    final List<DataList> servicesList = [];
    try {
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookies,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        displayName = document.querySelector('h1')?.text.trim() ?? "بدون اسم";
        avatarUrl =
            document
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            "";
        bio =
            document.querySelector('.user-bio')?.text.trim() ??
            document.querySelector('.profile-description')?.text.trim() ??
            "لا توجد نبذة شخصية";

        final serviceElements = document.querySelectorAll('.service-tile');
        for (final element in serviceElements) {
          final title =
              element.querySelector('h3 a')?.text.trim() ?? 'بدون عنوان';
          final serviceImage =
              element.querySelector('.service-image img')?.attributes['src'] ??
              '';
          final details =
              element.querySelector('.service-details')?.text.trim() ?? '';

          servicesList.add(
            DataList(name: title, image: serviceImage, description: details),
          );
        }
      }
    } catch (e) {
      debugPrint('خطأ في الاتصال: $e');
    }
    return servicesList;
  }
}
