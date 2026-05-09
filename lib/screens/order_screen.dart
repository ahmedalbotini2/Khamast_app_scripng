// import 'package:flutter/material.dart';
// import 'package:khmsat_services/resources/data.dart';
// import 'package:khmsat_services/resources/resources.dart';
// import 'package:khmsat_services/services/order_scrept.dart';
// import 'package:khmsat_services/services/services_scrept.dart';
// import 'package:khmsat_services/widgets/custom_sliver.dart';
// import 'package:khmsat_services/widgets/custome_widghit.dart';
// import 'package:skeletonizer/skeletonizer.dart';

// class OrderScreen extends StatefulWidget {
//   const OrderScreen({super.key});

//   @override
//   State<OrderScreen> createState() => _OrderScreenState();
// }

// class _OrderScreenState extends State<OrderScreen> {
//   late WebScrepingOrder screper = WebScrepingOrder();
//   bool isLoading = false;
//   String? descrip;
//   late Future<List<DataList>> orders;
//   @override
//   void initState() {
//     super.initState();
//     debugPrint('الـ ID الذي سيتم البحث عنه: ${WebScrepingServices.orderId}');
//     orders = screper.extractData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<List<DataList>>(
//         future: orders,
//         builder: (context, snapshot) {
//           final bool isLoading =
//               snapshot.connectionState == ConnectionState.waiting;

//           // إنشاء القائمة الوهمية أو استخدام البيانات الحقيقية
//           final List<DataList> displayList =
//               isLoading
//                   ? List.generate(
//                     8,
//                     (index) => DataList(
//                       name: 'جاري تحميل العنوان...',
//                       description:
//                           'هذا الوصف يظهر بشكل مؤقت حتى يتم جلب البيانات من الموقع',
//                       image: '',
//                     ),
//                   )
//                   : (snapshot.data ?? []);

//           if (snapshot.hasError) {
//             return Center(
//               child: Text("خطأ في جلب البيانات: ${snapshot.error}"),
//             );
//           }

//           return Skeletonizer(
//             enabled: isLoading,
//             child: CustomScrollView(
//               slivers: [
//                 SliverAppBar(
//                   automaticallyImplyLeading: false,
//                   expandedHeight:
//                       150.0, // تمت زيادته قليلاً ليعطي مساحة للـ CustomSliver والظلال
//                   floating: true,
//                   pinned: true,
//                   backgroundColor: const Color(0xFFD4AF37),

//                   // 1. إضافة الحواف الدائرية والظل
//                   elevation: 10,
//                   shadowColor: Colors.black.withOpacity(0.4),
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.vertical(
//                       bottom: Radius.circular(20), // تدوير الحواف السفلية
//                     ),
//                   ),

//                   title: Image.asset(ImageApp.logo, width: 50, height: 50),
//                   centerTitle: true,

//                   flexibleSpace: FlexibleSpaceBar(
//                     // ضبط المسافات: العنوان (title) يتحرك بناءً على titlePadding
//                     titlePadding: const EdgeInsets.only(bottom: 10),

//                     background: Padding(
//                       // ضبط المسافة من الأعلى لضمان عدم تداخل CustomSliver مع الـ AppBar الصغير
//                       padding: const EdgeInsets.only(
//                         top: 40.0,
//                         left: 10,
//                         right: 10,
//                       ),
//                       child: CustomSliver(
//                         name: WebScrepingServices.nameOrder,
//                         descrption: WebScrepingServices.descriptionOrder,
//                         image: WebScrepingServices.imageOrder,
//                         time: WebScrepingOrder.timeOrder,
//                         compact: true,
//                       ),
//                     ),
//                   ),
//                 ),

//                 SliverPadding(
//                   padding: EdgeInsets.symmetric(vertical: 10),
//                   sliver: SliverList(
//                     delegate: SliverChildBuilderDelegate((context, index) {
//                       final item = displayList[index];
//                       return CustomeWidghit(
//                         name: item.name,
//                         descrption: item.description,
//                         image: item.image,
//                         isLoding: isLoading,
//                       );
//                     }, childCount: displayList.length),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/resources/resources.dart';
import 'package:khmsat_services/services/order_scrept.dart';
import 'package:khmsat_services/services/services_scrept.dart';
import 'package:khmsat_services/widgets/custom_sliver.dart';
import 'package:khmsat_services/widgets/custome_widghit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class OrderScreen extends StatefulWidget {
  final String orderId; // أضف هذا الحقل
  const OrderScreen({super.key, required this.orderId}); // تحديث المنشئ

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late WebScrepingOrder scraper; // تغيير الاسم ليكون أوضح
  late Future<List<DataList>> ordersFuture;

  @override
  void initState() {
    super.initState();
    // تمرير الـ ID المستلم من الـ Widget إلى كلاس المنطق
    scraper = WebScrepingOrder(orderId: widget.orderId);
    ordersFuture = scraper.extractData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: FutureBuilder<List<DataList>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          final bool isLoading =
              snapshot.connectionState == ConnectionState.waiting;
          final List<DataList> displayList =
              isLoading
                  ? List.generate(
                    8,
                    (index) =>
                        DataList(name: '...', description: '...', image: ''),
                  )
                  : (snapshot.data ?? []);

          return Skeletonizer(
            enabled: isLoading,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  expandedHeight:
                      150.0, // تمت زيادته قليلاً ليعطي مساحة للـ CustomSliver والظلال
                  floating: true,
                  pinned: true,
                  backgroundColor: const Color(0xFFD4AF37),

                  // 1. إضافة الحواف الدائرية والظل
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.4),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20), // تدوير الحواف السفلية
                    ),
                  ),

                  title: Image.asset(ImageApp.logo, width: 50, height: 50),
                  centerTitle: true,

                  flexibleSpace: FlexibleSpaceBar(
                    // ضبط المسافات: العنوان (title) يتحرك بناءً على titlePadding
                    titlePadding: const EdgeInsets.only(bottom: 10),

                    background: Padding(
              
                      padding: const EdgeInsets.only(
                        top: 40.0,
                        left: 10,
                        right: 10,
                      ),
                      child: CustomSliver(
                        name: WebScrepingServices.nameOrder,
                        descrption:
                            WebScrepingServices
                                .descriptionOrder, //التعديل على الوصف من كلاس  WebScrepingOrder
                        image: WebScrepingServices.imageOrder,

                        compact: true,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return CustomeWidghit(
                      name: displayList[index].name,
                      descrption: displayList[index].description,
                      image: displayList[index].image,
                      isLoding: isLoading,
                    );
                  }, childCount: displayList.length),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
