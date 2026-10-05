import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:khmsat_services/screens/web_screen.dart';
import 'package:khmsat_services/services/Ai_service.dart';
import 'package:khmsat_services/services/profile_scrept.dart';

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
  }

  Future<void> _loadData({bool showSkeleton = true}) async {
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
  void _openLinkAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WebScreen()),
    );
  }

  final aiService = GeminiAiService();
  Future<void> _handleAiAnalysis() async {
    debugPrint('1. بدأت العملية');

    // تشخيص حالة البيانات
    if (services == null) {
      debugPrint('خطأ: قائمة الخدمات null تماماً (لم يتم تهيئتها)');
      _showSnackBar("البيانات لم تُجلب بعد، يرجى الانتظار");
      return;
    }

    if (services!.isEmpty) {
      debugPrint(
        'خطأ: قائمة الخدمات فارغة [] (لم يتم العثور على خدمات)$services',
      );
      _showSnackBar("لا توجد خدمات مسجلة لتحليلها");
      return;
    }

    // إذا وصل الكود هنا، فهذا يعني أن هناك بيانات فعلاً
    setState(() => isAiAnalyzing = true);
    debugPrint('2. جاري إرسال البيانات.. عدد الخدمات: ${services!.length}');

    try {
      String userSkills = services!.map((e) => e.name).join(", ");
      await aiService.analyze(
        prompt: "Write a compelling bio in Arabic based on my skills...",
        value: userSkills,
      );

      debugPrint('3. انتهى التحليل بنجاح');
      if (mounted) _showAiResultSheet();
    } catch (e) {
      debugPrint('فشل في تحليل الذكاء الاصطناعي: $e');
    } finally {
      if (mounted) setState(() => isAiAnalyzing = false);
    }
  }

  // دالة مساعدة لإظهار رسائل سريعة
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAiResultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // مهم جداً
      builder: (context) {
        String result = aiService.getOutput();
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "النتيجة:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // إذا كان النص فارغاً، سيعرض رسالة تنبيه
              Text(
                result.isEmpty
                    ? "لم يتم استلام نص من الذكاء الاصطناعي"
                    : result,
              ),
            ],
          ),
        );
      },
    );
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
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        floatingActionButton:
            _isLinked
                ? FloatingActionButton(
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
                )
                : null,
        body: Stack(
          children: [
            const _PortfolioBackground(),
            SafeArea(
              child: Column(
                children: [
                  _PortfolioHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                    showLogout: _isLinked,
                  ),
                  Expanded(
                    child:
                        !_isLinked
                            ? _LinkAccountPrompt(onLink: _openLinkAccount)
                            : (!isLoading && scraper.displayName == null)
                            ? _ProfileLoadError(onRetry: _loadData)
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
                                    _ProfileCard(
                                      name:
                                          isLoading
                                              ? _fakeName
                                              : scraper.displayName!,
                                      avatar:
                                          isLoading ? null : scraper.avatarUrl,
                                    ),
                                    const SizedBox(height: 16),
                                    _AboutSection(
                                      bio: isLoading ? _fakeBio : scraper.bio,
                                    ),
                                    const SizedBox(height: 16),
                                    _PortfolioSection(
                                      items:
                                          isLoading
                                              ? _fakeServices
                                              : (services ?? []),
                                    ),
                                    const SizedBox(height: 16),
                                    const Skeleton.keep(
                                      child: _ContactSection(),
                                    ),
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

// --- الودجت الفرعية مع تحديث استلام البيانات ---

/// تظهر عندما لا يكون الحساب مربوطاً: نص توضيحي + زر ربط الحساب
class _LinkAccountPrompt extends StatelessWidget {
  final VoidCallback onLink;
  const _LinkAccountPrompt({required this.onLink});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'قم بربط حسابك للاستفادة من ميزة الذكاء الاصطناعي '
                'ومجموعة من الميزات التي يوفرها التطبيق',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onLink,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(
                    'ربط الحساب',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ProfileLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.black45,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذّر جلب بيانات الملف الشخصي',
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String? avatar;
  const _ProfileCard({required this.name, this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Skeleton.leaf(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFD4AF37),
                  backgroundImage:
                      avatar != null && avatar!.isNotEmpty
                          ? NetworkImage(avatar!)
                          : null,
                  child:
                      avatar == null || avatar!.isEmpty
                          ? const Icon(
                            Icons.person,
                            color: Colors.black,
                            size: 34,
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Skeleton.leaf(
                      child: Text(
                        'بائع في خمسات',
                        style: GoogleFonts.tajawal(
                          fontSize: 13.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String? bio;
  const _AboutSection({this.bio});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'النبذة الشخصية',
      child: Text(
        bio ?? "لا توجد تفاصيل متوفرة حالياً.",
        style: GoogleFonts.tajawal(
          fontSize: 13.5,
          height: 1.6,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  final List<DataList> items;
  const _PortfolioSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'الخدمات المتاحة',
      child:
          items.isEmpty
              ? const Text("لا توجد خدمات لعرضها")
              : Column(
                children:
                    items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ServiceItemCard(item: item),
                          ),
                        )
                        .toList(),
              ),
    );
  }
}

class _ServiceItemCard extends StatelessWidget {
  final DataList item;
  const _ServiceItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Row(
        children: [
          Skeleton.leaf(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  item.image.isNotEmpty
                      ? Image.network(
                        item.image,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 54,
                        height: 54,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.tajawal(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.description,
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- باقي الودجت الجمالية (Background, Header, SectionCard) تظل كما هي مع تصحيح النصوص العربية ---

class _PortfolioHeader extends StatelessWidget {
  final VoidCallback onBack;

  /// إظهار زر تسجيل الخروج (يُخفى عندما لا يكون الحساب مربوطاً)
  final bool showLogout;
  const _PortfolioHeader({required this.onBack, this.showLogout = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(216),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'الملف الشخصي',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const Spacer(),
            if (showLogout)
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded),
                color: const Color(0xFF111111),
              )
            else
              const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // دالة تسجيل الخروج
  Future<void> _logout(BuildContext context) async {
    final storage = const FlutterSecureStorage();

    // 1. مسح البيانات من الخزنة
    await storage.delete(key: 'session_cookies');
    await storage.delete(key: 'saved_username');

    // 2. مسح كوكيز المتصفح لضمان عدم الدخول التلقائي مرة أخرى
    await CookieManager.instance().deleteAllCookies();

    // 3. العودة لصفحة الويب فيو (تسجيل الدخول)
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WebScreen()),
        (route) => false,
      );
    }
  }
} // --- باقي الودجت الجمالية (Background, ContactSection) تظل كما هي مع تصحيح النصوص العربية ---

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.keep(
            child: Text(
              title,
              style: GoogleFonts.tajawal(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
} //

class _PortfolioBackground extends StatelessWidget {
  const _PortfolioBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4D6), Color(0xFFF7F3EA), Color(0xFFFFFFFF)],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "تواصل معي",
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} //
