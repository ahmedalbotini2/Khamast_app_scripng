import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key, this.initialUrl = 'https://khamsat.com'});

  final String initialUrl;

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  final cookieManger = WebViewCookieManager();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _cookieStorageKey = 'webview_cookies';
  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFF8F5EF))
          ..setUserAgent(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
          ) //تعيين User-Agent لمحاكاة متصفح حقيقي، مما يساعد في تجاوز بعض قيود المواقع التي قد تمنع الوصول من WebView الافتراضي.
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (value) {
                setState(() => _progress = value);
              },
              onPageFinished: (String url) async {
                await _captureCookies();
                _updateNavState();
                // داخل الـ NavigationDelegate

                // جلب الكوكيز التي يمكن للـ JS الوصول إليها
                final String cookies =
                    await _controller.runJavaScriptReturningResult(
                          'document.cookie',
                        )
                        as String;

                // تنظيف النص (لأن الـ JS أحياناً يرجعه محاطاً بعلامات تنصيص إضافية)
                String cleanedCookies = cookies.replaceAll('"', '');

                if (cleanedCookies.isNotEmpty && cleanedCookies != "null") {
                  // حفظها في الخزنة الآمنة
                  await _secureStorage.write(
                    key: 'session_cookies',
                    value: cleanedCookies,
                  );
                  print("✅ تم حفظ الكوكيز بنجاح");
                }
              },
              onNavigationRequest: (request) {
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.initialUrl));
  }

  /*
final cookieManager = WebViewCookieManager();

Future<void> syncAndVerifyCookies() async {
  // جلب كافة الكوكيز للنطاق
  final List<WebViewCookie> cookies = await cookieManager.getCookies(
    Uri.parse('https://khamsat.com'),
  );

  // البحث عن كوكي الجلسة تحديداً
  bool hasSession = cookies.any((c) => c.name == 'rack.session');
  
  if (hasSession) {
    print("✅ تم العثور على جلسة الدخول (rack.session) بنجاح!");
    
    // تحويلها لنص وحفظها في التخزين الآمن
    String fullCookiePath = cookies.map((c) => "${c.name}=${c.value}").join("; ");
    await _ٍ.write(key: 'session_cookies', value: fullCookiePath);
  } else {
    print("⚠️ الجلسة غير موجودة في القائمة، تأكد من انتهاء تحميل الصفحة.");
  }
}
*/
  Future<void> _updateNavState() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  Future<void> _captureCookies() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      final cookieString = _normalizeJsString(
        result,
      ); //جلب الكوكيز من الويبفيو وتحويلها إلى نص عادي.
      if (cookieString.isEmpty) return;
      await _secureStorage.write(key: _cookieStorageKey, value: cookieString);
      debugPrint('تم تخزين الكوكيز بأمان: $cookieString');
    } catch (_) {
      debugPrint('فشل جلب أو تخزين الكوكيز، سيتم تجاهل هذا الخطأ.');
      //الخطأ في جلب الكوكيز من الويبفيو أو تخزينها بأمان يتم تجاهله، حيث لا يؤثر على تجربة المستخدم بشكل كبير.
    }
  }

  String _normalizeJsString(Object? result) {
    if (result == null) return '';
    var value = result.toString();
    if (value == 'null') return '';
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
    return value.trim();
  } //التحويل نتيجة جافا سكريبت إلى نص عادي بدون علامات اقتباس زائدة أو محارف هروب.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String coockieRead =
              await _secureStorage.read(key: _cookieStorageKey) ?? '';
          debugPrint('الكوكيز المخزنة حالياً: $coockieRead');
          Navigator.pop(context);
        },
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.close_rounded, color: Colors.black),
      ),
      appBar: AppBar(
        title: Text(
          'خمسات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _canGoBack ? _controller.goBack : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          IconButton(
            onPressed: _canGoForward ? _controller.goForward : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom:
            _progress < 100
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.black12,
                    color: const Color(0xFF111111),
                    minHeight: 3,
                  ),
                )
                : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
