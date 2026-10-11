import 'dart:async';
import 'dart:convert';
import 'package:khmsat_services/screens/ai/controller/ai_client_service.dart';
import 'package:khmsat_services/screens/ai/model/chat_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;

  /// عدد محاولات توليد العنوان (حدّها 2 لتوفير التوكنز)
  int titleAttempts;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    this.title = ChatTitleGenerator.fallback,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.titleAttempts = 0,
    List<ChatMessage>? messages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messages = messages ?? [];

  bool get hasTitle => title != ChatTitleGenerator.fallback;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created': createdAt.millisecondsSinceEpoch,
        'updated': updatedAt.millisecondsSinceEpoch,
        'attempts': titleAttempts,
        'messages': [
          for (final m in messages)
            {
              'r': m.role == MessageRole.user ? 'u' : 'a',
              't': m.text,
              'tm': m.time,
            },
        ],
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String,
        title: (json['title'] ?? ChatTitleGenerator.fallback) as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['created'] ?? 0) as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['updated'] ?? 0) as int,
        ),
        titleAttempts: (json['attempts'] ?? 0) as int,
        messages: [
          for (final m in (json['messages'] as List? ?? const []))
            ChatMessage(
              role: (m as Map)['r'] == 'u' ? MessageRole.user : MessageRole.ai,
              text: (m['t'] ?? '') as String,
              time: (m['tm'] ?? '') as String,
            ),
        ],
      );
}

class ChatHistoryStore {
  static const String _key = 'chat_sessions_v1';
  static const int maxSessions = 50;

  // تسلسل عمليات القراءة/الكتابة حتى لا تتداخل (مثلاً حفظ رد + حفظ عنوان)
  static Future<void> _tail = Future.value();

  Future<T> _run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<List<ChatSession>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<ChatSession> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(list.map((s) => s.toJson()).toList()),
    );
  }

  /// كل المحادثات، الأحدث أولاً
  Future<List<ChatSession>> loadAll() => _run(_read);

  /// إضافة محادثة أو تحديثها، وإرجاع القائمة الجديدة
  Future<List<ChatSession>> upsert(ChatSession session) => _run(() async {
        final list = await _read();
        final i = list.indexWhere((e) => e.id == session.id);
        if (i >= 0) {
          list[i] = session;
        } else {
          list.add(session);
        }
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final trimmed = list.take(maxSessions).toList();
        await _write(trimmed);
        return trimmed;
      });

  Future<List<ChatSession>> delete(String id) => _run(() async {
        final list = await _read();
        list.removeWhere((e) => e.id == id);
        await _write(list);
        return list;
      });
}

class ChatTitleGenerator {
  static const String fallback = 'محادثة جديدة';

  static const String _prompt =
      'اكتب عنواناً قصيراً من 3 إلى 5 كلمات بالعربية يلخص موضوع المحادثة '
      'التالية. أعد العنوان فقط بدون علامات تنصيص أو نقطة أو أي شرح.';

  static String _cut(String s, int n) => s.length > n ? s.substring(0, n) : s;

  /// يرجع العنوان المولّد، أو "محادثة جديدة" إذا فشل الاستخراج
  static Future<String> generate(
    AiModelConfig config, {
    required String userText,
    required String aiText,
  }) async {
    try {
      // نسخة بدون MCP: العنوان لا يحتاج أدوات الخادم
      final plain = AiModelConfig(
        provider: config.provider,
        model: config.model,
        endpoint: config.endpoint,
        apiKey: config.apiKey,
      );
      final raw = await AiClientFactory.create(plain).send(
        systemPrompt: _prompt,
        history: [
          AiTurn(
            isUser: true,
            text: 'رسالة المستخدم:\n${_cut(userText, 300)}\n\n'
                'رد المساعد:\n${_cut(aiText, 300)}',
          ),
        ],
        temperature: 0.2,
      );
      return _clean(raw);
    } catch (_) {
      return fallback;
    }
  }

  static String _clean(String raw) {
    var t = raw.trim().split('\n').first.trim();
    t = t.replaceAll(RegExp(r'''^[\s"'“”«»*#\-]+|[\s"'“”«»*.]+$'''), '');
    if (t.isEmpty) return fallback;
    if (t.length > 40) t = t.substring(0, 40).trim();
    return t;
  }
}
