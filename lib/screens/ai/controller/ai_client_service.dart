import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

enum AiProvider { gemini, openai, anthropic, deepseek, custom }

extension AiProviderInfo on AiProvider {
  String get label => switch (this) {
        AiProvider.gemini => 'Gemini',
        AiProvider.openai => 'ChatGPT (OpenAI)',
        AiProvider.anthropic => 'Claude (Anthropic)',
        AiProvider.deepseek => 'DeepSeek',
        AiProvider.custom => 'مخصص (رابط API خاص)',
      };

  // أسماء النماذج الافتراضية قابلة للتعديل من واجهة الربط
  String get defaultModel => switch (this) {
        AiProvider.gemini => 'gemini-2.0-flash',
        AiProvider.openai => 'gpt-4.1',
        AiProvider.anthropic => 'claude-sonnet-5-5',
        AiProvider.deepseek => 'deepseek-chat',
        AiProvider.custom => '',
      };

  String get defaultEndpoint => switch (this) {
        AiProvider.openai => 'https://api.openai.com/v1/chat/completions',
        AiProvider.deepseek => 'https://api.deepseek.com/chat/completions',
        _ => '',
      };

  /// المزوّدون الذين يدعمون الاتصال بخادم MCP بعيد مباشرة
  bool get supportsMcp =>
      this == AiProvider.anthropic || this == AiProvider.openai;
}

class AiModelConfig {
  final AiProvider provider;
  final String model;
  final String endpoint;
  final String apiKey;

  /// رابط خادم MCP البعيد (فارغ = ربط API عادي)
  final String mcpUrl;

  /// توكن مصادقة الخادم (اختياري)
  final String mcpToken;

  const AiModelConfig({
    required this.provider,
    required this.model,
    required this.endpoint,
    required this.apiKey,
    this.mcpUrl = '',
    this.mcpToken = '',
  });

  bool get hasMcp => mcpUrl.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'model': model,
        'endpoint': endpoint,
        'apiKey': apiKey,
        'mcpUrl': mcpUrl,
        'mcpToken': mcpToken,
      };

  factory AiModelConfig.fromJson(Map<String, dynamic> json) => AiModelConfig(
        provider: AiProvider.values.firstWhere(
          (p) => p.name == json['provider'],
          orElse: () => AiProvider.gemini,
        ),
        model: (json['model'] ?? '') as String,
        endpoint: (json['endpoint'] ?? '') as String,
        apiKey: (json['apiKey'] ?? '') as String,
        mcpUrl: (json['mcpUrl'] ?? '') as String,
        mcpToken: (json['mcpToken'] ?? '') as String,
      );
}

/// دور واحد في المحادثة
class AiTurn {
  final bool isUser;
  final String text;
  const AiTurn({required this.isUser, required this.text});
}

class AiClientException implements Exception {
  final String message;
  AiClientException(this.message);
  @override
  String toString() => message;
}

abstract class AiClient {
  /// [history] يجب أن ينتهي برسالة المستخدم الأخيرة.
  Future<String> send({
    required String systemPrompt,
    required List<AiTurn> history,
    double temperature = 0.3,
    bool jsonMode = false,
  });
}

Future<Map<String, dynamic>> _postJson(
  Uri uri,
  Map<String, String> headers,
  Map<String, dynamic> body, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  try {
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json', ...headers},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final raw = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      final short = raw.length > 250 ? raw.substring(0, 250) : raw;
      throw AiClientException('فشل الاتصال (${res.statusCode}): $short');
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  } on TimeoutException {
    throw AiClientException('انتهت مهلة الاتصال بالنموذج.');
  } on AiClientException {
    rethrow;
  } catch (e) {
    throw AiClientException('تعذر الاتصال بالنموذج: $e');
  }
}

AiClientException _emptyReply(Map<String, dynamic> data) {
  final raw = jsonEncode(data);
  return AiClientException(
    'رد فارغ من النموذج: ${raw.length > 200 ? raw.substring(0, 200) : raw}',
  );
}

// ───────────────────────── Gemini ─────────────────────────

class GeminiRestClient implements AiClient {
  final AiModelConfig config;
  GeminiRestClient(this.config);

  @override
  Future<String> send({
    required String systemPrompt,
    required List<AiTurn> history,
    double temperature = 0.3,
    bool jsonMode = false,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent',
    );

    final data = await _postJson(
      uri,
      {'x-goog-api-key': config.apiKey},
      {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          for (final t in history)
            {
              'role': t.isUser ? 'user' : 'model',
              'parts': [
                {'text': t.text},
              ],
            },
        ],
        'generationConfig': {
          'temperature': temperature,
          if (jsonMode) 'responseMimeType': 'application/json',
        },
      },
    );

    final candidates = data['candidates'];
    final first = (candidates is List && candidates.isNotEmpty)
        ? candidates.first
        : null;
    final parts = (first is Map && first['content'] is Map)
        ? (first['content'] as Map)['parts']
        : null;
    final text = (parts is List && parts.isNotEmpty && parts.first is Map)
        ? (parts.first as Map)['text']
        : null;
    if (text is! String || text.trim().isEmpty) throw _emptyReply(data);
    return text;
  }
}

// ───────────────── OpenAI / DeepSeek / متوافق مع OpenAI ─────────────────

class OpenAiCompatibleClient implements AiClient {
  final AiModelConfig config;
  OpenAiCompatibleClient(this.config);

  @override
  Future<String> send({
    required String systemPrompt,
    required List<AiTurn> history,
    double temperature = 0.3,
    bool jsonMode = false,
  }) async {
    final endpoint = config.endpoint.trim().isNotEmpty
        ? config.endpoint.trim()
        : config.provider.defaultEndpoint;
    if (endpoint.isEmpty) {
      throw AiClientException('رابط الـ API غير محدد.');
    }

    final data = await _postJson(
      Uri.parse(endpoint),
      {'Authorization': 'Bearer ${config.apiKey}'},
      {
        'model': config.model,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          for (final t in history)
            {'role': t.isUser ? 'user' : 'assistant', 'content': t.text},
        ],
        if (jsonMode) 'response_format': {'type': 'json_object'},
      },
    );

    final choices = data['choices'];
    final first =
        (choices is List && choices.isNotEmpty && choices.first is Map)
            ? choices.first as Map
            : null;
    final content = (first?['message'] is Map)
        ? (first!['message'] as Map)['content']
        : null;

    final String text;
    if (content is String) {
      text = content;
    } else if (content is List) {
      text = content.map((p) => p is Map ? (p['text'] ?? '') : '').join();
    } else {
      text = '';
    }
    if (text.trim().isEmpty) throw _emptyReply(data);
    return text;
  }
}

// ───────────────── Claude (API عادي أو MCP connector) ─────────────────

class AnthropicClient implements AiClient {
  final AiModelConfig config;
  AnthropicClient(this.config);

  static const String _mcpServerName = 'user-mcp';

  @override
  Future<String> send({
    required String systemPrompt,
    required List<AiTurn> history,
    double temperature = 0.3,
    bool jsonMode = false,
  }) async {
    // Claude يشترط أن تبدأ المحادثة برسالة مستخدم
    final turns = List<AiTurn>.of(history);
    while (turns.isNotEmpty && !turns.first.isUser) {
      turns.removeAt(0);
    }

    final useMcp = config.hasMcp;
    final token = config.mcpToken.trim();

    final data = await _postJson(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      {
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
        if (useMcp) 'anthropic-beta': 'mcp-client-2025-11-20',
      },
      {
        'model': config.model,
        'max_tokens': 1024,
        'temperature': temperature,
        'system': systemPrompt,
        'messages': [
          for (final t in turns)
            {'role': t.isUser ? 'user' : 'assistant', 'content': t.text},
        ],
        if (useMcp) ...{
          'mcp_servers': [
            {
              'type': 'url',
              'url': config.mcpUrl.trim(),
              'name': _mcpServerName,
              if (token.isNotEmpty) 'authorization_token': token,
            },
          ],
          'tools': [
            {'type': 'mcp_toolset', 'mcp_server_name': _mcpServerName},
          ],
        },
      },
      // استدعاء أدوات MCP قد يستغرق وقتاً أطول
      timeout: Duration(seconds: useMcp ? 90 : 40),
    );

    final content = data['content'];
    final text = (content is List)
        ? content
            .where((b) => b is Map && b['type'] == 'text')
            .map((b) => (b as Map)['text'] ?? '')
            .join('\n')
        : '';
    if (text.trim().isEmpty) throw _emptyReply(data);
    return text;
  }
}

// ───────────────── OpenAI Responses API مع أداة MCP ─────────────────

class OpenAiResponsesMcpClient implements AiClient {
  final AiModelConfig config;
  OpenAiResponsesMcpClient(this.config);

  @override
  Future<String> send({
    required String systemPrompt,
    required List<AiTurn> history,
    double temperature = 0.3,
    bool jsonMode = false,
  }) async {
    final token = config.mcpToken.trim();

    final data = await _postJson(
      Uri.parse('https://api.openai.com/v1/responses'),
      {'Authorization': 'Bearer ${config.apiKey}'},
      {
        'model': config.model,
        'instructions': systemPrompt,
        'input': [
          for (final t in history)
            {'role': t.isUser ? 'user' : 'assistant', 'content': t.text},
        ],
        'tools': [
          {
            'type': 'mcp',
            'server_label': 'user_mcp',
            'server_url': config.mcpUrl.trim(),
            'require_approval': 'never',
            if (token.isNotEmpty) 'authorization': token,
          },
        ],
      },
      timeout: const Duration(seconds: 90),
    );

    final buffer = StringBuffer();
    final output = data['output'];
    if (output is List) {
      for (final item in output) {
        if (item is Map && item['type'] == 'message' && item['content'] is List) {
          for (final c in item['content'] as List) {
            if (c is Map && c['type'] == 'output_text') {
              buffer.write(c['text'] ?? '');
            }
          }
        }
      }
    }
    final text = buffer.toString();
    if (text.trim().isEmpty) throw _emptyReply(data);
    return text;
  }
}

class AiClientFactory {
  static AiClient create(AiModelConfig config) {
    if (config.hasMcp) {
      return config.provider == AiProvider.anthropic
          ? AnthropicClient(config)
          : OpenAiResponsesMcpClient(config);
    }
    return switch (config.provider) {
      AiProvider.gemini => GeminiRestClient(config),
      AiProvider.anthropic => AnthropicClient(config),
      _ => OpenAiCompatibleClient(config),
    };
  }
}

/// حفظ إعدادات الربط (ومنها المفاتيح) في التخزين الآمن
class AiSettingsStore {
  static const _key = 'ai_model_config';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AiModelConfig?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AiModelConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AiModelConfig config) =>
      _storage.write(key: _key, value: jsonEncode(config.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}