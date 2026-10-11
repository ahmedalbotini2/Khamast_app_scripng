
import 'package:khmsat_services/screens/ai/controller/ai_client_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BioResult {
  final String? text;
  final String? message;
  const BioResult.success(String this.text) : message = null;
  const BioResult.failure(String this.message) : text = null;

  bool get ok => text != null;
}

class BioAiService {
  // غيّر اسم النموذج إذا تغيّر أو توقف عند OpenRouter
  static const String _openRouterModel = 'meta-llama/llama-3.3-70b-instruct:free';
  static const String _openRouterEndpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _openRouterKey = String.fromEnvironment('OPENROUTER_KEY');

  static const String _quotaKey = 'bio_ai_free_last_used';

  final AiSettingsStore _store = AiSettingsStore();

  static const String _systemPrompt =
      'أنت مساعد داخل تطبيق خمسات. اكتب نبذة شخصية احترافية بالعربية '
      'من 3 إلى 4 جمل لبائع خدمات، اعتماداً فقط على أسماء خدماته المعطاة. '
      'لا تخترع خبرات أو أرقاماً أو شهادات. أعد النبذة فقط بدون مقدمة.';

  String _today() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  Future<bool> _freeQuotaAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quotaKey) != _today();
  }

  Future<void> _consumeFreeQuota() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quotaKey, _today());
  }

  Future<BioResult> generate(List<String> serviceNames) async {
    final skills = serviceNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join('، ');
    if (skills.length < 5) {
      return const BioResult.failure('لا توجد خدمات كافية لتوليد نبذة.');
    }

    final linked = await _store.load();
    final bool useFree = linked == null;

    if (useFree) {
      if (_openRouterKey.isEmpty) {
        return const BioResult.failure(
          'الخدمة المجانية غير مفعّلة. اربط نموذج ذكاء اصطناعي من شاشة المحادثة.',
        );
      }
      if (!await _freeQuotaAvailable()) {
        return const BioResult.failure(
          'استنفدت المحاولة المجانية لليوم. جرّب غداً، أو اربط نموذجك '
          'الخاص من شاشة المحادثة لتوليد بلا حد.',
        );
      }
    }

    final config = linked ??
        const AiModelConfig(
          provider: AiProvider.custom,
          model: _openRouterModel,
          endpoint: _openRouterEndpoint,
          apiKey: _openRouterKey,
        );

    try {
      final text = await AiClientFactory.create(config).send(
        systemPrompt: _systemPrompt,
        history: [AiTurn(isUser: true, text: 'خدماتي: $skills')],
        temperature: 0.7,
      );
      // لا تُحتسب المحاولة اليومية إلا عند نجاح الطلب
      if (useFree) await _consumeFreeQuota();
      return BioResult.success(text.trim());
    } on AiClientException catch (e) {
      return BioResult.failure(e.message);
    } catch (e) {
      return BioResult.failure('حدث خطأ غير متوقع: $e');
    }
  }
}
