import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/screens/order/view/order_screen.dart'; // ⚠️ تأكد من المسار

enum MessageRole { user, ai }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.time,
  });

  final MessageRole role;
  final String text;
  final String time;
}

/// صيغة رابط الطلب داخل نص الرسالة: [العنوان](order:ID)
final RegExp orderLinkPattern = RegExp(r'\[([^\]]+)\]\(order:([^)\s]+)\)');

/// تتبع الاتجاه (start/end) بدل left/right، فتعمل بشكل صحيح تحت RTL:
/// رسائل المستخدم عند البداية (اليمين) ورسائل الوكيل عند النهاية (اليسار).
class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.theme});

  final ChatMessage message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    final bubbleColor =
        isUser ? const Color(0xFF111111) : Colors.white.withValues(alpha: 0.9);
    final textColor = isUser ? Colors.white : const Color(0xFF111111);
    final align =
        isUser
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            // الزاوية الصغيرة (ذيل الفقاعة) عند الطرف السفلي القريب من حافة الشاشة
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(18),
              topEnd: const Radius.circular(18),
              bottomStart:
                  isUser ? const Radius.circular(4) : const Radius.circular(18),
              bottomEnd:
                  isUser ? const Radius.circular(18) : const Radius.circular(4),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinkedText(
                text: message.text,
                style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  height: 1.5,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 6),
              Text(
                message.time,
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  color: isUser ? Colors.white70 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نص يعرض روابط الطلبات زرقاء تحتها خط، والضغط عليها يفتح OrderScreen
class _LinkedText extends StatefulWidget {
  const _LinkedText({
    required this.text,
    required this.style,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  State<_LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<_LinkedText> {
  static const Color _linkColor = Color(0xFF1A73E8);
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  List<InlineSpan> _spans(BuildContext context) {
    final text = widget.text;
    final spans = <InlineSpan>[];
    var last = 0;

    for (final m in orderLinkPattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final title = m.group(1)!;
      final id = m.group(2)!;
      final tap =
          TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OrderScreen(orderId: id)),
              );
            };
      _recognizers.add(tap);
      spans.add(
        TextSpan(
          text: title,
          recognizer: tap,
          style: widget.style.copyWith(
            color: _linkColor,
            decoration: TextDecoration.underline,
            decorationColor: _linkColor,
          ),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    return Text.rich(
      TextSpan(style: widget.style, children: _spans(context)),
      textAlign: widget.textAlign,
    );
  }
}
