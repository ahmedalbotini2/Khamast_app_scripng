import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/core/services/internet_connection_service.dart';
import 'package:khmsat_services/screens/order/model/data.dart';
import 'package:khmsat_services/core/services/resources.dart';
import 'package:khmsat_services/screens/web/view/web_screen.dart';
import 'package:khmsat_services/screens/order/controller/order_scrept.dart';
import 'package:khmsat_services/core/widgets/custome_widghit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class OrderScreen extends StatefulWidget {
  final String orderId;
  const OrderScreen({super.key, required this.orderId});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late WebScrepingOrder scraper;
  late Future<List<DataList>> ordersFuture;

  @override
  void initState() {
    super.initState();
    scraper = WebScrepingOrder(orderId: widget.orderId);
    ordersFuture = _fetchWithConnectionCheck();
  }

  /// يتحقق من الإنترنت أولاً؛ إن لم يوجد اتصال يرمي خطأ فتظهر حالة الخطأ
  Future<List<DataList>> _fetchWithConnectionCheck() async {
    final connected = await InternetConnectivityService.hasInternet;
    if (!connected) {
      throw Exception(InternetConnectivityService.noInternetMessage);
    }
    return scraper.extractData();
  }

  void _retry() {
    setState(() {
      ordersFuture = _fetchWithConnectionCheck();
    });
  }

  /// يفتح صفحة الطلب في موقع خمسات نفسه للتقديم عليه
  Future<void> _openApplyPage() async {
    if (!await InternetConnectivityService.checkAndNotify(context)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebScreen(initialUrl: scraper.url)),
    );
  }

  /// يعرض العنوان والوصف كاملين في نافذة سفلية قابلة للتمرير
  void _showFullDescription(String title, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF4D6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    description,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // أبعاد كتلة الطلب (يمكن تعديلها)
    const double titleH = 64; // منطقة العنوان الثابتة
    const double descH = 90; // منطقة الوصف (تختفي عند التمرير)

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplyPage,
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.open_in_new_rounded),
        label: Text(
          'التقديم على الطلب',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<DataList>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;

          if (snapshot.hasError) {
            final noInternet = snapshot.error.toString().contains(
              InternetConnectivityService.noInternetMessage,
            );
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        noInternet
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                        color: Colors.black38,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        noInternet
                            ? InternetConnectivityService.noInternetMessage
                            : 'حدث خطأ أثناء جلب بيانات الطلب',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        child: Text(
                          'إعادة المحاولة',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // العناصر هنا هي التعليقات فقط
          final List<DataList> comments =
              isLoading
                  ? List.generate(
                    8,
                    (index) =>
                        DataList(name: '...', description: '...', image: ''),
                  )
                  : (snapshot.data ?? []);

          // بيانات الطلب
          final String headerName =
              isLoading ? 'جاري التحميل...' : scraper.orderTitle;
          final String headerDescription =
              isLoading ? '...' : scraper.orderDescription;

          return Skeletonizer(
            enabled: isLoading,
            child: CustomScrollView(
              slivers: [
                // 1) الشريط العلوي: الشعار فقط، بدون حواف، ثابت
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  backgroundColor: const Color(0xFFD4AF37),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  // Skeleton.keep: يبقي الشعار كما هو بدون تأثير الشيمر
                  title: Skeleton.keep(
                    child: Image.asset(ImageApp.logo, width: 50, height: 50),
                  ),
                  centerTitle: true,
                ),

                // 2) كتلة الطلب: ملاصقة للشريط من الأسفل
                //    العنوان ثابت، والوصف يختفي عند التمرير للأسفل
                SliverAppBar(
                  primary: false, // الشريط الأول تكفّل بمساحة شريط الحالة
                  automaticallyImplyLeading: false,
                  pinned: true,
                  toolbarHeight: titleH,
                  expandedHeight: titleH + descH,
                  backgroundColor: const Color(0xFFFFF4D6),
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.black.withOpacity(0.35),
                  elevation: 0,
                  // يظهر الظل فقط عندما تمر التعليقات تحت الكتلة
                  scrolledUnderElevation: 4,
                  titleSpacing: 20,
                  centerTitle: true,
                  title: Text(
                    headerName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.none,
                    background: Padding(
                      padding: const EdgeInsets.only(
                        top: titleH,
                        left: 20,
                        right: 20,
                        bottom: 14,
                      ),
                      // الضغط على الوصف يفتح الوصف كاملاً
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            (isLoading || headerDescription.trim().isEmpty)
                                ? null
                                : () => _showFullDescription(
                                  headerName,
                                  headerDescription,
                                ),
                        child: Text(
                          headerDescription,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) عناصر القائمة: التعليقات
                SliverPadding(
                  // حشوة سفلية كبيرة حتى لا يغطي الزر العائم آخر تعليق
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return CustomeWidghit(
                        name: comments[index].name,
                        descrption: comments[index].description,
                        image: comments[index].image,
                        isLoding: isLoading,
                      );
                    }, childCount: comments.length),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}