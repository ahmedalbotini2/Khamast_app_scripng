import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(role: _MessageRole.ai, text: 'gemini.', time: '09:14'),
    const _ChatMessage(
      role: _MessageRole.user,
      text: 'chat gpt ',
      time: '09:16',
    ),
    const _ChatMessage(role: _MessageRole.ai, text: 'deepseek', time: '09:16'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _MessageRole.user,
          text: text,
          time: _formatTime(TimeOfDay.now()),
        ),
      );
      _controller.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '�' : '�';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: Column(
              children: [
                _ChatHeader(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(message: message, theme: theme);
                    },
                  ),
                ),
                const _SuggestionStrip(),
                _Composer(controller: _controller, onSend: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4D6), Color(0xFFF7F3EA), Color(0xFFFFFFFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _SoftCircle(
              size: 220,
              colors: [Color(0xFFFFE7A3), Color(0xFFFFF4D6)],
            ),
          ),
          Positioned(
            top: 180,
            left: -60,
            child: _SoftCircle(
              size: 180,
              colors: [Color(0xFFE7E2D4), Color(0xFFFFFFFF)],
            ),
          ),
          Positioned(
            bottom: -90,
            right: -30,
            child: _SoftCircle(
              size: 210,
              colors: [Color(0xFFD4AF37), Color(0xFFFFE7A3)],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
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
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: const Color(0xFF111111),
            ),
            const SizedBox(width: 4),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ahmed',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ali',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.theme});

  final _ChatMessage message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _MessageRole.user;

    final bubbleColor =
        isUser ? const Color(0xFF111111) : Colors.white.withValues(alpha: 0.9);
    final textColor = isUser ? Colors.white : const Color(0xFF111111);
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight:
                  isUser ? const Radius.circular(4) : const Radius.circular(18),
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
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  height: 1.5,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: isUser ? TextAlign.right : TextAlign.left,
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

class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip();

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

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.black54,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'ارسال ملاجظات...',
                  hintStyle: GoogleFonts.tajawal(
                    fontSize: 13.5,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
                iconSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MessageRole { user, ai }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    required this.time,
  });

  final _MessageRole role;
  final String text;
  final String time;
}
