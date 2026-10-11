import 'package:flutter/material.dart';
import 'package:khmsat_services/screens/order/model/data.dart';
import 'package:khmsat_services/screens/profile/model/section_card.dart';
import 'package:khmsat_services/screens/profile/model/service_Item_card.dart';

class PortfolioSection extends StatelessWidget {
  final List<DataList> items;
  const PortfolioSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
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
                            child: ServiceItemCard(item: item),
                          ),
                        )
                        .toList(),
              ),
    );
  }
}
