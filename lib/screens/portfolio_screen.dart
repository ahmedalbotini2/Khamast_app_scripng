import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

// تأكد من استيراد ملف موديل البيانات الخاص بك
// import 'package:khmsat_services/widgets/data.dart'; 

// ملاحظة: قمت بوضع الموديل هنا للتأكد من عمل الكود
class DataList {
  final String name;
  final String image;
  final String description;
  DataList({required this.name, required this.image, required this.description});
}

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
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        displayName = document.querySelector('h1')?.text.trim() ?? "بدون اسم";
        avatarUrl = document.querySelector('meta[property="og:image"]')?.attributes['content'] ?? "";
        bio = document.querySelector('.user-bio')?.text.trim() ?? 
              document.querySelector('.profile-description')?.text.trim() ?? 
              "لا توجد نبذة شخصية";

        final serviceElements = document.querySelectorAll('.service-tile');
        for (final element in serviceElements) {
          final title = element.querySelector('h3 a')?.text.trim() ?? 'بدون عنوان';
          final serviceImage = element.querySelector('.service-image img')?.attributes['src'] ?? '';
          final details = element.querySelector('.service-details')?.text.trim() ?? '';

          servicesList.add(DataList(
            name: title, 
            image: serviceImage, 
            description: details
          ));
        }
      }
    } catch (e) {
      debugPrint('خطأ في الاتصال: $e');
    }
    return servicesList;
  }
}

// --- الكود الثاني: الشاشة بعد الربط ---
class PortfolioScreen extends StatefulWidget {
  final String username;
  final String cookies;

  const PortfolioScreen({super.key, required this.username, required this.cookies});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late WebScrepingPortfolio scraper;
  List<DataList>? services;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    scraper = WebScrepingPortfolio(username: widget.username, cookies: widget.cookies);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
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
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFD4AF37),
                backgroundImage: avatar != null && avatar!.isNotEmpty ? NetworkImage(avatar!) : null,
                child: avatar == null || avatar!.isEmpty ? const Icon(Icons.person, color: Colors.black, size: 34) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بائع في خمسات',
                      style: GoogleFonts.tajawal(fontSize: 13.5, color: Colors.black54, fontWeight: FontWeight.w500),
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
        style: GoogleFonts.tajawal(fontSize: 13.5, height: 1.6, color: Colors.black87, fontWeight: FontWeight.w500),
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
      child: items.isEmpty 
        ? const Text("لا توجد خدمات لعرضها")
        : Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceItemCard(item: item),
            )).toList(),
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
            child: item.image.isNotEmpty 
              ? Image.network(item.image, width: 54, height: 54, fit: BoxFit.cover)
              : Container(width: 54, height: 54, color: Colors.grey[200], child: const Icon(Icons.image)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.tajawal(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.description,
                  style: GoogleFonts.tajawal(fontSize: 12.5, color: Colors.black54),
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
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: const Color(0xFF111111),
            ),
            const SizedBox(width: 6),
            Text(
              'معرض الأعمال',
              style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

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
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.tajawal(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111111)),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

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
            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text("تواصل معي", style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        ),
      ],
    );
  }
}