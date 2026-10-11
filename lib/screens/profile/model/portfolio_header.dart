import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PortfolioHeader extends StatelessWidget {
  final VoidCallback onBack;

  /// إظهار زر تسجيل الخروج (يُخفى عندما لا يكون الحساب مربوطاً)
  final bool showLogout;
  const PortfolioHeader({super.key, required this.onBack, this.showLogout = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(216),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'الملف الشخصي',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
