import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:khmsat_services/widgets/data.dart';

class WebScrepingPortfolio {
  // استقبال البيانات من الشاشة السابقة
  final String username;
  final String cookies;

  WebScrepingPortfolio({required this.username, required this.cookies});

  // بناء الرابط بناءً على اسم المستخدم المستلم
  String get url => 'https://khamsat.com/user/$username';

  // متغيرات لتخزين بيانات البروفايل
  String? displayName;
  String? avatarUrl;
  String? bio;

  Future<List<DataList>> extractData() async {
    final List<DataList> servicesList = [];
    
    try {
      // إرسال الطلب مع الكوكيز في الـ headers
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: {
          'Cookie': cookies, // تمرير "مفتاح الدخول" هنا
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // 1. استخراج بيانات البروفايل
        displayName = document.querySelector('h1')?.text.trim() ?? "بدون اسم";
        avatarUrl = document.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";
        
        // محاولة جلب النبذة الشخصية بأكثر من Selector لضمان الدقة
        bio = document.querySelector('.user-bio')?.text.trim() ?? 
              document.querySelector('.profile-description')?.text.trim() ?? 
              "لا توجد نبذة شخصية";

        // 2. استخراج الخدمات
        final serviceElements = document.querySelectorAll('.service-tile');

        for (final element in serviceElements) {
          try {
            final title = element.querySelector('h3 a')?.text.trim() ?? 'بدون عنوان';
            
            final serviceImage = element.querySelector('.service-image img')?.attributes['src'] ?? 
                                 element.querySelector('.thumbnail img')?.attributes['src'] ?? '';
            
            final details = element.querySelector('.service-details')?.text.trim() ?? 
                            element.querySelector('.service-meta')?.text.trim() ?? '';

            servicesList.add(DataList(
              name: title, 
              image: serviceImage, 
              description: details
            ));
          } catch (e) {
            print('خطأ في تحليل خدمة معينة: $e');
          }
        }
      } else {
        print('فشل الوصول للصفحة: ${response.statusCode}');
      }
    } catch (e) {
      print('خطأ في الاتصال: $e');
    }
    
    return servicesList;
  }
}