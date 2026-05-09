import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:khmsat_services/screens/main_screen.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key, this.initialUrl = 'https://khamsat.com'});

  final String initialUrl;

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  InAppWebViewController? _controller; // تم تغييرها لتقبل null لتجنب أخطاء late
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _cookieStorageKey = 'session_cookies'; // توحيد المفتاح

  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _controllerReady = false;

  // تعريف مدير الكوكيز كمتغير ثابت
  late CookieManager _cookieManager = CookieManager.instance();

  @override
  void initState() {
    super.initState();
  }

  /// الطريقة الاحترافية لجلب كافة الكوكيز (بما فيها المحمية HttpOnly)
  Future<void> _captureAllCookiesNative() async {
    try {
      // 1. جلب الكوكيز من "جذور" النظام وليس الجافا سكريبت
      List<Cookie> cookies = await _cookieManager.getCookies(
        url: WebUri("https://khamsat.com"),
      );

      if (cookies.isNotEmpty) {
        // 2. تحويل قائمة الكوكيز لنص بصيغة (key=value; key2=value2)
        String cookieString = cookies
            .map((c) => "${c.name}=${c.value}")
            .join("; ");

        // 3. التحقق من وجود جلسة الدخول rack.session
        bool hasSession = cookies.any((c) => c.name == 'rack.session');

        // 4. التخزين الآمن
        await _secureStorage.write(key: _cookieStorageKey, value: cookieString);

        if (hasSession) {
          debugPrint('✅ تم بنجاح اصطياد جلسة الدخول rack.session وكل الكوكيز');
        } else {
          debugPrint(
            '⚠️ تم حفظ الكوكيز ولكن لم يتم العثور على rack.session بعد',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ فشل جلب الكوكيز من المستوى الأصلي: $e');
    }
  }

  Future<void> _updateNavState() async {
    if (_controller == null) return;
    final back = await _controller!.canGoBack();
    final forward = await _controller!.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // زر عائم لعرض الكوكيز المخزنة (للتأكد)
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     final String? cookieRead = await _secureStorage.read(
      //       key: _cookieStorageKey,
      //     );
      //     debugPrint('🔍 الكوكيز في الخزنة الآن: ${cookieRead ?? "فارغة"}');
      //     // Navigator.pop(context); // يمكنك تفعيلها إذا أردت إغلاق الصفحة
      //   },
      //   backgroundColor: const Color(0xFFD4AF37),
      //   child: const Icon(Icons.bug_report, color: Colors.black),
      // ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 0,
        title: Text(
          'خمسات',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),

        actions: [
          IconButton(
            onPressed: _controllerReady ? () => _controller?.reload() : null,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          ),
        ],
        bottom:
            _progress < 100
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.black12,
                    color: const Color(0xFF00B232), // لون خمسات الأخضر
                    minHeight: 3,
                  ),
                )
                : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          // تفعيل تخزين البيانات محلياً لضمان بقاء الجلسة
          domStorageEnabled: true,
          databaseEnabled: true,
          // البصمة التي تجعل التطبيق يتبع سياسة Google Chrome
          userAgent:
              "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
          thirdPartyCookiesEnabled: true,
          allowFileAccessFromFileURLs: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          setState(() => _controllerReady = true);
        },
        onProgressChanged: (controller, progress) {
          setState(() => _progress = progress);
        },
        onLoadStop: (controller, url) async {
          String urlString = url.toString();

          await _captureAllCookiesNative();

          // 2. التحقق إذا وصل المستخدم لصفحة البروفايل
          if (urlString.contains("khamsat.com/user/")) {
            Uri uri = Uri.parse(urlString);
            String username = uri.pathSegments.last;

            await _secureStorage.write(key: 'saved_username', value: username);
            // final String? savedCookies = await _secureStorage.read(
            //   key: 'session_cookies',
            // );

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
                (route) =>
                    false, // هذا يمنع المستخدم من العودة للخلف لصفحة الويب
              );
            }
          }

          _updateNavState();
        },
      ),
    );
  }
}
