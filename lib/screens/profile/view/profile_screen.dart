import 'package:flutter/material.dart';
import 'package:khmsat_services/core/services/internet_connection_service.dart';
import 'package:khmsat_services/screens/ai/controller/bio_ai_service.dart';
import 'package:khmsat_services/screens/order/model/data.dart';
import 'package:khmsat_services/core/services/resources.dart';
import 'package:khmsat_services/screens/profile/model/about_section.dart';
import 'package:khmsat_services/screens/profile/model/link_account_prompt.dart';
import 'package:khmsat_services/screens/profile/model/porfolio_background.dart';
import 'package:khmsat_services/screens/profile/model/portfolio_header.dart';
import 'package:khmsat_services/screens/profile/model/profile_card.dart';
import 'package:khmsat_services/screens/profile/model/profile_error.dart';
import 'package:khmsat_services/screens/profile/model/protfolio_section.dart';
import 'package:khmsat_services/screens/web/view/web_screen.dart';
import 'package:khmsat_services/screens/profile/controller/profile_scrept.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String cookies;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.cookies,
  });

  @override
  State<ProfileScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<ProfileScreen> {
  late WebScrepingPortfolio scraper;
  List<DataList>? services;
  bool isLoading = true;
  bool isAiAnalyzing = false;

  /// الحساب مربوط إذا وُجد اسم المستخدم والكوكيز (MainScreen يمرر نصاً فارغاً عند عدمهما)
  bool get _isLinked => widget.username.isNotEmpty && widget.cookies.isNotEmpty;

  @override
  void initState() {
    super.initState();
    scraper = WebScrepingPortfolio(
      username: widget.username,
      cookies: widget.cookies,
    );
    if (_isLinked) {
      _loadData();
    } else {
      // لا حاجة لجلب بيانات من خمسات بدون حساب مربوط
      isLoading = false;
    }
    // التحقق من الإنترنت عند فتح التبويب
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) InternetConnectivityService.checkAndNotify(context);
    });
  }

  Future<void> _loadData({bool showSkeleton = true}) async {
    // التحقق من الإنترنت قبل الجلب
    final connected = await InternetConnectivityService.hasInternet;
    if (!mounted) return;
    if (!connected) {
      setState(() => isLoading = false);
      _showSnackBar(InternetConnectivityService.noInternetMessage);
      return;
    }

    if (showSkeleton && !isLoading) {
      setState(() => isLoading = true);
    }
    final data = await scraper.extractData();
    if (!mounted) return;

    final refreshFailed =
        !showSkeleton && data.isEmpty && (services?.isNotEmpty ?? false);
    setState(() {
      if (!refreshFailed) services = data;
      isLoading = false;
    });
    if (refreshFailed) _showSnackBar('تعذّر التحديث، حاول مرة أخرى');
  }

  /// يفتح صفحة تسجيل الدخول في خمسات لربط الحساب
  Future<void> _openLinkAccount() async {
    if (!await InternetConnectivityService.checkAndNotify(context)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WebScreen()),
    );
  }

  final BioAiService _bioService = BioAiService();

  Future<void> _handleAiAnalysis() async {
    if (services == null) {
      _showSnackBar("البيانات لم تُجلب بعد، يرجى الانتظار");
      return;
    }
    if (services!.isEmpty) {
      _showSnackBar("لا توجد خدمات مسجلة لتحليلها");
      return;
    }

    // التحقق من الإنترنت قبل إرسال البيانات للذكاء الاصطناعي
    if (!await InternetConnectivityService.checkAndNotify(context)) return;

    setState(() => isAiAnalyzing = true);
    try {
      final result = await _bioService.generate(
        services!.map((e) => e.name).toList(),
      );
      if (!mounted) return;
      if (result.ok) {
        _showAiResultSheet(result.text!);
      } else {
        _showSnackBar(result.message!);
      }
    } finally {
      if (mounted) setState(() => isAiAnalyzing = false);
    }
  }

  void _showAiResultSheet(String result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "النتيجة:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SelectableText(result),
              ],
            ),
          ),
        );
      },
    );
  }

  // دالة مساعدة لإظهار رسائل سريعة
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static const _fakeName = 'اسم المستخدم الكامل هنا';
  static const _fakeBio =
      'نبذة شخصية تجريبية تظهر أثناء التحميل فقط لتعطي شكل النص الحقيقي '
      'وطوله، وتمتد على عدة أسطر كما تظهر النبذة الفعلية للبائع في خمسات '
      'حتى يكون الشكل قبل التحميل وبعده متطابقًا قدر الإمكان.';
  static final _fakeServices = List.generate(
    3,
    (_) => DataList(
      name: 'عنوان خدمة تجريبي بطول مناسب',
      image: '',
      description:
          'وصف الخدمة التجريبي يظهر هنا ويمتد على سطرين كاملين كما في '
          'الحقيقي حتى يتطابق الشكل تمامًا مع البيانات.',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        floatingActionButton:
            _isLinked
                ? Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: FloatingActionButton(
                    onPressed: isAiAnalyzing ? null : _handleAiAnalysis,
                    child:
                        isAiAnalyzing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Image.asset(
                              ImageApp.aiIcon,
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                  ),
                )
                : null,
        body: Stack(
          children: [
            const PortfolioBackground(),
            SafeArea(
              child: Column(
                children: [
                  PortfolioHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                    showLogout: _isLinked,
                  ),
                  Expanded(
                    child:
                        !_isLinked
                            ? LinkAccountPrompt(onLink: _openLinkAccount)
                            : (!isLoading && scraper.displayName == null)
                            ? ProfileLoadError(onRetry: _loadData)
                            : RefreshIndicator(
                              color: const Color(0xFFD4AF37),
                              onRefresh: () => _loadData(showSkeleton: false),
                              child: Skeletonizer(
                                enabled: isLoading,
                                ignoreContainers: true,
                                effect: const ShimmerEffect(
                                  baseColor: Color(0xFFEDE3C4),
                                  highlightColor: Color(0xFFFFF8E1),
                                ),
                                child: ListView(
                                  physics:
                                      isLoading
                                          ? const NeverScrollableScrollPhysics()
                                          : const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    24,
                                  ),
                                  children: [
                                    ProfileCard(
                                      name:
                                          isLoading
                                              ? _fakeName
                                              : scraper.displayName!,
                                      avatar:
                                          isLoading ? null : scraper.avatarUrl,
                                    ),
                                    const SizedBox(height: 16),
                                    AboutSection(
                                      bio: isLoading ? _fakeBio : scraper.bio,
                                    ),
                                    const SizedBox(height: 16),
                                    PortfolioSection(
                                      items:
                                          isLoading
                                              ? _fakeServices
                                              : (services ?? []),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
