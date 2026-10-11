import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:khmsat_services/screens/order/controller/order_scrept.dart';
import 'package:khmsat_services/screens/order/model/data.dart';
import 'package:khmsat_services/screens/profile/controller/profile_scrept.dart'; // ⚠️ المسار
import 'package:khmsat_services/screens/service/controller/services_scrept.dart';


/// مرجع طلب قرأه الوكيل: المعرّف الكامل (للرابط) وعنوانه الحقيقي
class RequestRef {
  final String id;
  final String title;
  const RequestRef(this.id, this.title);
}

class AppDataReader {
  static const Set<String> toolNames = {
    'get_my_profile',
    'list_open_requests',
    'get_request_details',
  };

  static const int _maxResultChars = 3500;

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// الطلبات التي قرأها الوكيل فعلاً. المفتاح = الرقم القصير الذي يراه
  /// النموذج، والقيمة = المرجع الكامل. تُستخدم للتحقق من أي رابط يقترحه
  /// النموذج، فلا يظهر رابط لطلب مخترع.
  final Map<String, RequestRef> seenRequests = {};

  /// 798537-%D8%AA... → 798537
  String _shortRef(String id) =>
      RegExp(r'^\d+').firstMatch(id)?.group(0) ?? id;

  /// نص الحالة الذي يظهر في المحادثة أثناء تنفيذ الأداة
  static String statusFor(String tool) => switch (tool) {
        'get_my_profile' => 'جاري قراءة ملفك الشخصي...',
        'list_open_requests' => 'جاري قراءة الطلبات المعروضة...',
        'get_request_details' => 'جاري قراءة تفاصيل الطلب...',
        _ => 'جاري قراءة بيانات التطبيق...',
      };

  /// يرجع النتيجة كنص JSON (أو JSON فيه حقل error عند الفشل)
  Future<String> run(String tool, Map<String, dynamic> args) async {
    if (!toolNames.contains(tool)) {
      return jsonEncode({'error': 'أداة غير معروفة'});
    }
    try {
      final Map<String, dynamic> data = switch (tool) {
        'get_my_profile' => await _profile(),
        'list_open_requests' => await _requests(args),
        _ => await _requestDetails(args),
      };
      final out = jsonEncode(data);
      return out.length > _maxResultChars
          ? out.substring(0, _maxResultChars)
          : out;
    } catch (_) {
      return jsonEncode({'error': 'تعذّر قراءة البيانات حالياً'});
    }
  }

  String _cut(String? s, int n) {
    final t = (s ?? '').trim();
    return t.length > n ? '${t.substring(0, n)}…' : t;
  }

  Future<Map<String, dynamic>> _profile() async {
    final username = await _secure.read(key: 'saved_username') ?? '';
    final cookies = await _secure.read(key: 'session_cookies') ?? '';
    if (username.isEmpty || cookies.isEmpty) {
      return {'error': 'الحساب غير مربوط'};
    }

    final scraper = WebScrepingPortfolio(username: username, cookies: cookies);
    final services = await scraper.extractData();
    if (scraper.displayName == null) {
      return {'error': 'تعذّر جلب الملف الشخصي'};
    }
    return {
      'display_name': scraper.displayName,
      'bio': _cut(scraper.bio, 600),
      'services': [
        for (final DataList s in services.take(15))
          {'name': s.name, 'description': _cut(s.description, 160)},
      ],
    };
  }

  Future<Map<String, dynamic>> _requests(Map<String, dynamic> args) async {
    final asked = (args['limit'] as num?)?.toInt() ?? 10;
    final limit = math.min(20, math.max(1, asked));

    final list = await WebScrepingServices().extractData(); // ⚠️
    final items = <Map<String, dynamic>>[];
    var size = 0;
    for (final DataList r in list.take(limit)) {
      final full = r.id ?? '';
      if (full.isEmpty) continue;
      final ref = _shortRef(full);
      final item = {
        'id': ref,
        'title': r.name,
        'description': _cut(r.description, 80),
      };
      size += jsonEncode(item).length;
      if (size > 3000) break;
      items.add(item);
      seenRequests[ref] = RequestRef(full, r.name);
    }
    return {'requests': items};
  }

  Future<Map<String, dynamic>> _requestDetails(
    Map<String, dynamic> args,
  ) async {
    final asked = (args['id'] ?? '').toString().trim();
    final id = seenRequests[asked]?.id ?? asked; // الرقم القصير → الكامل
    // يمنع المسارات والروابط فقط (شكل الـ id الحقيقي: رقم-slug مُرمَّز)
    if (!RegExp(r'^[^\s/?#]{1,200}$').hasMatch(id)) {
      return {'error': 'رقم الطلب غير صالح'};
    }

    final order = WebScrepingOrder(orderId: id);
    final comments = await order.extractData();

    // عند فشل التحميل يبقى العنوان فارغاً، وعند حجب الصفحة يرجع "بدون عنوان"
    final title = order.orderTitle.trim();
    if (title.isEmpty || title == 'بدون عنوان') {
      return {'error': 'تعذّر جلب تفاصيل الطلب'};
    }
    seenRequests[_shortRef(id)] = RequestRef(id, title);

    return {
      'id': _shortRef(id),
      'title': title,
      'description': _cut(order.orderDescription, 1200),
      'comments': [
        for (final DataList c in comments.take(8))
          {'author': c.name, 'text': _cut(c.description, 200)},
      ],
    };
  }
}