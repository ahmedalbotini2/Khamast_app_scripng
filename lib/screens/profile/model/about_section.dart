import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/screens/profile/model/section_card.dart';

class AboutSection extends StatelessWidget {
  final String? bio;
  const AboutSection({super.key, this.bio});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'النبذة الشخصية',
      child: Text(
        bio ?? "لا توجد تفاصيل متوفرة حالياً.",
        style: GoogleFonts.tajawal(
          fontSize: 13.5,
          height: 1.6,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}
