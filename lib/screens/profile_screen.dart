import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:khmsat_services/screens/web_screen.dart';
import 'package:khmsat_services/services/Ai_service.dart';
import 'package:khmsat_services/services/profile_scrept.dart';

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

  @override
  void initState() {
    super.initState();
    scraper = WebScrepingPortfolio(
      username: widget.username,
      cookies: widget.cookies,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await scraper.extractData();
    if (mounted) {
      setState(() {
        services = data;
        isLoading = false;
      });
    }
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
      debugPrint('خطأ: قائمة الخدمات فارغة [] (لم يتم العثور على خدمات)$services');
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

  @override
  build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
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
                : Image.asset(ImageApp.aiIcon, width: 24, height: 24),
      ),
      body: Stack(
        children: [
          const _PortfolioBackground(),
          SafeArea(
            child: Column(
              children: [
                _PortfolioHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD4AF37),
                            ),
                          )
                          : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            children: [
                              _ProfileCard(
                                name: scraper.displayName ?? "جاري التحميل...",
                                avatar: scraper.avatarUrl,
                              ),
                              const SizedBox(height: 16),
                              _AboutSection(bio: scraper.bio),
                              const SizedBox(height: 16),
                              _PortfolioSection(items: services ?? []),
                              const SizedBox(height: 16),
                              const _ContactSection(),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- الودجت الفرعية مع تحديث استلام البيانات ---

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
              CircleAvatar(
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
                    Text(
                      'بائع في خمسات',
                      style: GoogleFonts.tajawal(
                        fontSize: 13.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
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
          ClipRRect(
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
  const _PortfolioHeader({required this.onBack});

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
            IconButton(
              onPressed: () => _logout(context),
              icon: Icon(Icons.devices_fold_outlined),
            ),

            const Spacer(),
            Text(
              'الملف الشخصي',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
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
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
            textAlign: TextAlign.right,
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
