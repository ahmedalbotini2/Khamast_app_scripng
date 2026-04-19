import 'package:flutter/material.dart';
import 'package:khmsat_services/resources/data.dart';
import 'package:khmsat_services/services/order_scrept.dart';
import 'package:khmsat_services/services/services_scrept.dart';
import 'package:khmsat_services/widgets/custome_widghit.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late WebScrepingOrder screper = WebScrepingOrder();
  bool isLoding = false;
  String? descrip;
  late Future<List<DataList>> orders;
  @override
  void initState() {
    super.initState();
    debugPrint('الـ ID الذي سيتم البحث عنه: ${WebScrepingServices.orderId}');
    orders = screper.extractData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: orders,
        builder: (context, snapshot) {
          debugPrint('ُError number 2:$screper');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("خطأ: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Error num 2"));
          }
          debugPrint('Error is here=> ${snapshot.data}');
          final item = snapshot.data!;
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                color: const Color(0xFBC8B8A6),
                child: Text(
                  WebScrepingOrder.descriptionOrder,
                  style: TextStyle(color: Colors.black),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: item.length,
                  itemBuilder:
                      (context, index) => CustomeWidghit(
                        name: item[index].name,
                        descrption: item[index].description,
                        image: item[index].image,
                        // 'https://www.pexels.com/photo/aerial-view-of-vietnamese-flower-market-36838200/',
                        isLoding: isLoding,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
