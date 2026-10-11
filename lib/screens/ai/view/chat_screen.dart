import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:khmsat_services/core/services/internet_connection_service.dart';
import 'package:khmsat_services/screens/ai/controller/ai_client_service.dart';
import 'package:khmsat_services/screens/ai/controller/app_data_reader.dart';
import 'package:khmsat_services/screens/ai/controller/chat_history_store.dart';
import 'package:khmsat_services/screens/ai/controller/khamsat_agent.dart';
import 'package:khmsat_services/screens/ai/model/history_sheet.dart'; // ⚠️ تأكد من مسار ملف HistorySheet
import 'package:khmsat_services/screens/ai/model/background_decor.dart';
import 'package:khmsat_services/screens/ai/model/chat_bubble.dart';
import 'package:khmsat_services/screens/ai/model/chat_header.dart';
import 'package:khmsat_services/screens/ai/model/composer.dart';
import 'package:khmsat_services/screens/ai/view/ai_link_page.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiSettingsStore _store = AiSettingsStore();
  final ChatHistoryStore _history = ChatHistoryStore();

  bool _loading = true;
  AiModelConfig? _config;
  KhamsatAgent? _agent;
  bool _isSending = false;

  /// المحادثة الحالية (null = محادثة جديدة لم تبدأ بعد، ولا تُحفظ وهي فارغة)
  ChatSession? _session;
  List<ChatSession> _sessions = [];

  List<ChatMessage> get _messages => _session?.messages ?? const [];

  @override
  void initState() {
    super.initState();
    // التحقق من الإنترنت عند فتح التبويب
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) InternetConnectivityService.checkAndNotify(context);
    });
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final config = await _store.load();
    final sessions = await _history.loadAll();
    if (!mounted) return;
    setState(() {
      _config = config;
      _agent = config == null ? null : _makeAgent(config);
      _sessions = sessions;
      _loading = false;
    });
  }

  /// الوكيل مع أدوات قراءة بيانات التطبيق (للقراءة فقط)
  KhamsatAgent _makeAgent(AiModelConfig config) => KhamsatAgent(
        AiClientFactory.create(config),
        reader: AppDataReader(),
      );

  void _showSnackBar(String message) {
    if (kDebugMode) debugPrint('SNACKBAR: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// بعد الربط أو إلغائه (السجل يبقى محفوظاً)
  void _applyConfig(AiModelConfig? config) {
    setState(() {
      _config = config;
      _agent = config == null ? null : _makeAgent(config);
      _session = null;
    });
  }

  Future<void> _unlink() async {
    await _store.clear();
    if (!mounted) return;
    _applyConfig(null);
  }

  // ───────────── السجل ─────────────

  void _newChat() {
    final config = _config;
    if (config == null) return;
    setState(() {
      _session = null;
      _agent = _makeAgent(config); // وكيل جديد = سياق جديد
      _controller.clear();
    });
  }

  void _openSession(ChatSession session) {
    final config = _config;
    if (config == null) return;

    // استعادة سياق الوكيل من رسائل المحادثة المحفوظة
    // (نزيل صيغة روابط الطلبات ونُبقي العناوين فقط)
    final turns = <AiTurn>[
      for (final m in session.messages)
        if (m.text.trim().isNotEmpty && m.text != '...')
          AiTurn(
            isUser: m.role == MessageRole.user,
            text: m.text.replaceAllMapped(orderLinkPattern, (x) => x[1]!),
          ),
    ];
    final agent = _makeAgent(config)..restoreHistory(turns);

    setState(() {
      _session = session;
      _agent = agent;
      _controller.clear();
    });
    _scrollToBottom();
  }

  Future<List<ChatSession>> _deleteSession(String id) async {
    final updated = await _history.delete(id);
    if (!mounted) return updated;
    setState(() {
      _sessions = updated;
      if (_session?.id == id) {
        _session = null;
        if (_config != null) _agent = _makeAgent(_config!);
      }
    });
    return updated;
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // النافذة تُبنى فوق الـ Navigator فلا ترث الاتجاه، لذا نحدده صراحة
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: HistorySheet(
          sessions: List.of(_sessions),
          currentId: _session?.id,
          onOpen: _openSession,
          onNew: _newChat,
          onDelete: _deleteSession,
        ),
      ),
    );
  }

  // ───────────── الإرسال ─────────────

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final agent = _agent;
    final config = _config;
    if (text.isEmpty || _isSending || agent == null || config == null) return;

    final session = _session ??
        ChatSession(id: DateTime.now().microsecondsSinceEpoch.toString());

    setState(() {
      _session = session;
      _isSending = true;
      session.messages
        ..add(
          ChatMessage(
            role: MessageRole.user,
            text: text,
            time: _formatTime(TimeOfDay.now()),
          ),
        )
        ..add(const ChatMessage(role: MessageRole.ai, text: '...', time: ''));
      _controller.clear();
    });
    _scrollToBottom();

    final placeholderIndex = session.messages.length - 1;
    String reply = '';
    String? errorText;
    bool answered = false;

    try {
      final result = await agent.handle(
        text,
        // يعرض حالة القراءة مكان "..." أثناء تنفيذ أدوات التطبيق
        onStatus: (status) {
          if (!mounted || placeholderIndex >= session.messages.length) return;
          setState(() {
            session.messages[placeholderIndex] = ChatMessage(
              role: MessageRole.ai,
              text: status,
              time: '',
            );
          });
        },
      );
      reply = result.text;
      if (result.services.isNotEmpty) {
        final list = result.services.map((s) => '• $s').join('\n');
        reply = reply.isEmpty ? list : '$reply\n\n$list';
      }
      // الطلبات تُحفظ بصيغة [العنوان](order:ID) ويعرضها ChatBubble كروابط
      if (result.requests.isNotEmpty) {
        final links = result.requests.map((r) {
          final title = r.title.replaceAll(RegExp(r'[\[\]\n]'), ' ').trim();
          return '[$title](order:${r.id})';
        }).join('\n');
        reply = reply.isEmpty ? links : '$reply\n\n$links';
      }
      answered = result.intent != AgentIntent.refuse;
    } on AiClientException catch (e) {
      errorText = e.message;
    } catch (e) {
      errorText = 'حدث خطأ غير متوقع: $e';
    }

    // فشل الطلب: نحذف الرسالة والمؤشر من المحادثة ونعيد النص لخانة الكتابة
    if (errorText != null) {
      session.messages.removeRange(placeholderIndex - 1, placeholderIndex + 1);
      if (session.messages.isEmpty && identical(_session, session)) {
        _session = null;
      }
      if (!mounted) return;
      setState(() {
        _isSending = false;
        if (_controller.text.isEmpty) _controller.text = text;
      });
      _showSnackBar(errorText);
      return;
    }

    session.messages[placeholderIndex] = ChatMessage(
      role: MessageRole.ai,
      text: reply,
      time: _formatTime(TimeOfDay.now()),
    );
    session.updatedAt = DateTime.now();
    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();

    _sessions = await _history.upsert(session);

    // توليد العنوان بعد أول تبادل ناجح (ضمن نطاق التطبيق)
    if (answered && !session.hasTitle && session.titleAttempts < 2) {
      final plainReply =
          reply.replaceAllMapped(orderLinkPattern, (x) => x[1]!);
      unawaited(_generateTitle(session, config, text, plainReply));
    }
  }

  Future<void> _generateTitle(
    ChatSession session,
    AiModelConfig config,
    String userText,
    String aiText,
  ) async {
    session.titleAttempts++;
    // عند الفشل يرجع "محادثة جديدة"
    session.title = await ChatTitleGenerator.generate(
      config,
      userText: userText,
      aiText: aiText,
    );
    _sessions = await _history.upsert(session);
    if (mounted) setState(() {});
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
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  // الصفحة كلها RTL (تشمل صفحة الربط لأنها تُعرض من داخلها)
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(context),
      );

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // غير مربوط: صفحة الربط (MCP / API)
    if (_config == null) {
      return AiLinkPage(onLinked: _applyConfig);
    }

    final theme = Theme.of(context);
    final config = _config!;
    final messages = _messages;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecor(),
          SafeArea(
            child: Column(
              children: [
                ChatHeader(
                  title: _session?.title ?? ChatTitleGenerator.fallback,
                  subtitle: '${config.provider.label} • ${config.model}'
                      '${config.hasMcp ? ' • MCP' : ''}',
                  onBack: () => Navigator.of(context).maybePop(),
                  onHistory: _openHistory,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextButton.icon(
                      onPressed: _unlink,
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('إلغاء الربط'),
                    ),
                  ),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'الصق نص أي طلب لأستخرج الخدمات المطلوبة أو '
                              'أكتب لك رداً مناسباً عليه.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return ChatBubble(
                              message: messages[index],
                              theme: theme,
                            );
                          },
                        ),
                ),
                Composer(controller: _controller, onSend: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}