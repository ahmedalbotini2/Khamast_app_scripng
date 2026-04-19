// ... الاستيرادات كما هي ...

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/screens/order_screen.dart';
import 'package:khmsat_services/services/services_scrept.dart';
import 'package:khmsat_services/widgets/custome_widghit.dart';
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
    _dataFuture = webScreping.extractData();
  }

  Future<void> _refreshData() async {
    setState(() {
      // إعادة جلب البيانات عند السحب للأسفل
      _dataFuture = webScreping.extractData();
    });
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4AF37),
        title: Text(
          'خمسات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<DataList>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          // هنا نحدد حالة التحميل بناءً على الـ snapshot
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ ما: ${snapshot.error}'));
          }

          // حتى لو كان قيد التحميل، سنعرض القائمة ولكن بداخل Skeletonizer
          // وإذا انتهى التحميل، سنعرض البيانات الحقيقية

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
            return const Center(child: Text('لا توجد بيانات'));
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Skeletonizer(
              enabled:
                  isLoading, // يعمل الـ Skeleton فقط عندما يكون الـ Future قيد الانتظار
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  return CustomeWidghit(
                    isLoding: isLoading,
                    name: displayList[index].name,
                    descrption: displayList[index].description,
                    image: displayList[index].image,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderScreen(),
                          ),
                        ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
