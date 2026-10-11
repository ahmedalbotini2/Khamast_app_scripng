

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String? avatar;
  const ProfileCard({super.key, required this.name, this.avatar});

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
              Skeleton.leaf(
                child: CircleAvatar(
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
                    Skeleton.leaf(
                      child: Text(
                        'بائع في خمسات',
                        style: GoogleFonts.tajawal(
                          fontSize: 13.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
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