import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/core/services/internet_connection_service.dart';
import 'package:khmsat_services/screens/order/model/data.dart';
import 'package:khmsat_services/core/services/resources.dart';
import 'package:khmsat_services/screens/order/view/order_screen.dart';
import 'package:khmsat_services/screens/service/controller/services_scrept.dart';
import 'package:khmsat_services/core/widgets/custome_widghit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DataServices extends StatefulWidget {
  const DataServices({super.key});

  @override
  State<DataServices> createState() => _DataServicesState();
}

class _DataServicesState extends State<DataServices> {
  final WebScrepingServices webScreping = WebScrepingServices();
  late Future<List<DataList>> _dataFuture;

  @override
  void initState() {
    super.initState();
    // نقوم بتهيئة الـ Future مرة واحدة فقط هنا
    _dataFuture = _fetchWithConnectionCheck();
  }

  /// يتحقق من الإنترنت أولاً؛ إن لم يوجد اتصال يرمي خطأ فتظهر حالة الخطأ
  Future<List<DataList>> _fetchWithConnectionCheck() async {
    final connected = await InternetConnectivityService.hasInternet;
    if (!connected) {
      throw Exception(InternetConnectivityService.noInternetMessage);
    }
    return webScreping.extractData();
  }

  Future<void> _refreshData() async {
    setState(() {
      // إعادة جلب البيانات عند السحب للأسفل أو زر إعادة المحاولة
      _dataFuture = _fetchWithConnectionCheck();
    });
    try {
      await _dataFuture;
    } catch (_) {
      // الخطأ يُعرض داخل FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        centerTitle: true,
        title: Image.asset(ImageApp.logo, width: 44, height: 44),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            color: Colors.black87,
          ),
        ],
      ),
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: FutureBuilder<List<DataList>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                final bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                if (snapshot.hasError) {
                  final noInternet = snapshot.error.toString().contains(
                    InternetConnectivityService.noInternetMessage,
                  );
                  return _ServicesStateMessage(
                    icon:
                        noInternet
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                    message:
                        noInternet
                            ? InternetConnectivityService.noInternetMessage
                            : 'حدث خطأ أثناء جلب البيانات',
                    actionLabel: 'إعادة المحاولة',
                    onAction: _refreshData,
                  );
                }

                // نجهز قائمة وهمية ليستخدمها الـ Skeletonizer أثناء التحميل
                final List<DataList> displayList =
                    isLoading
                        ? List.generate(
                          6,
                          (index) => DataList(
                            name: 'جاري التحميل...',
                            description: 'وصف تجريبي طويل جداً ليظهر الهيكل',
                            image:
                                'https://www.pexels.com/photo/aerial-view-of-vietnamese-flower-market-36838200/',
                          ),
                        )
                        : (snapshot.data ?? []);

                if (!isLoading && displayList.isEmpty) {
                  return _ServicesStateMessage(
                    icon: Icons.inbox_outlined,
                    message: 'لا توجد طلبات حالياً',
                    actionLabel: 'تحديث',
                    onAction: _refreshData,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  color: const Color(0xFFD4AF37),
                  backgroundColor: Colors.white,
                  child: Skeletonizer(
                    enabled:
                        isLoading, // يعمل الـ Skeleton فقط عندما يكون الـ Future قيد الانتظار
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // نلف كل عنصر بحاوية لإضافة ظل خفيف بدون
                        // تعديل ملف custome_widghit.dart نفسه
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomeWidghit(
                              isLoding: isLoading,
                              name: displayList[index].name,
                              descrption: displayList[index].description,
                              image: displayList[index].image,
                              onTap: () async {
                                // التحقق من أننا لا نضغط أثناء التحميل
                                if (isLoading) return;
                                // التحقق من الإنترنت قبل فتح تفاصيل الطلب
                                final ok =
                                    await InternetConnectivityService
                                        .checkAndNotify(context);
                                if (!ok || !context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    // نمرر الـ ID المستخرج من هذا العنصر تحديداً
                                    builder:
                                        (context) => OrderScreen(
                                          orderId: displayList[index].id ?? '',
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

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
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _SoftCircle(
              size: 220,
              colors: [Color(0xFFFFE7A3), Color(0xFFFFF4D6)],
            ),
          ),
          Positioned(
            top: 180,
            left: -60,
            child: _SoftCircle(
              size: 180,
              colors: [Color(0xFFE7E2D4), Color(0xFFFFFFFF)],
            ),
          ),
          Positioned(
            bottom: -90,
            right: -30,
            child: _SoftCircle(
              size: 210,
              colors: [Color(0xFFD4AF37), Color(0xFFFFE7A3)],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

/// حالة موحّدة لعرض الخطأ أو "لا توجد بيانات"، بدل نص عادي بلا تنسيق
class _ServicesStateMessage extends StatelessWidget {
  const _ServicesStateMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black38, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}