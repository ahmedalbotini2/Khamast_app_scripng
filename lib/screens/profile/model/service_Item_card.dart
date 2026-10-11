import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/screens/order/model/data.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ServiceItemCard extends StatelessWidget {
  final DataList item;
  const ServiceItemCard({super.key, required this.item});

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
