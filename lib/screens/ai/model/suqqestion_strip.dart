
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionStrip extends StatelessWidget {
  const SuggestionStrip();

  @override
  Widget build(BuildContext context) {
    final suggestions = ['one', 'two', 'trey'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1A000000)),
            ),
            child: Text(
              suggestions[index],
              style: GoogleFonts.tajawal(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
          );
        },
      ),
    );
  }
}

