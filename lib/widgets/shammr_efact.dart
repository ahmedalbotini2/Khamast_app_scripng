// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';

// bool isLoding = true;

// Widget _buildShimmerEffect() {
//   return Shimmer.fromColors(
//     baseColor: Colors.white.withOpacity(0.3),
//     highlightColor: Colors.white.withOpacity(0.6),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         // Placeholder for Title
//         Container(
//           height: 35,
//           width: 200,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         const SizedBox(height: 30),
//         // Placeholders for ListTiles
//         ...List.generate(
//           3,
//           (index) => Padding(
//             padding: const EdgeInsets.symmetric(vertical: 7.5),
//             child: Container(
//               height: 70,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
