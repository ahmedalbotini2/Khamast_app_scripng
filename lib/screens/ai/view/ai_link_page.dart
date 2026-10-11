
import 'package:flutter/material.dart';

import 'package:khmsat_services/screens/ai/controller/ai_client_service.dart';
import 'package:khmsat_services/screens/ai/model/background_decor.dart';

const Color _gold = Color(0xFFD4AF37);

/// شعار MCP. الشكل الحالي مؤقت مرسوم بالكود؛ لاستخدام الشعار الرسمي
/// ضع الصورة في assets ومرّر مسارها في assetPath.
class McpLogo extends StatelessWidget {
  final double size;
  final String? assetPath;
  const McpLogo({super.key, this.size = 96, this.assetPath});

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(assetPath!, width: size, height: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gold, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: size * 0.38, color: _gold),
          Text(
            'MCP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.18,
              color: _gold,
            ),
          ),
        ],
      ),
    );
  }
}

class AiLinkPage extends StatelessWidget {
  final ValueChanged<AiModelConfig> onLinked;
  const AiLinkPage({super.key, required this.onLinked});

  Future<void> _open(BuildContext context, {required bool mcp}) async {
    final config = await showModalBottomSheet<AiModelConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // النافذة تُبنى فوق الـ Navigator فلا ترث الاتجاه، لذا نحدده صراحة
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _LinkSheet(mcpMode: mcp),
      ),
    );
    if (config == null) return;
    await AiSettingsStore().save(config);
    onLinked(config);
  }

  // الصفحة RTL حتى لو استُخدمت خارج ChatScreen
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: _buildPage(context),
      );

  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecor(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: McpLogo()),
                    const SizedBox(height: 20),
                    Text(
                      'ربط الذكاء الاصطناعي',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر طريقة الربط للبدء',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => _open(context, mcp: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('ربط عبر MCP'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _open(context, mcp: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: _gold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.key_outlined),
                      label: const Text('ربط عبر API'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نافذة الربط: نموذج API أو MCP حسب [mcpMode]، مع اختبار اتصال قبل الحفظ
class _LinkSheet extends StatefulWidget {
  final bool mcpMode;
  const _LinkSheet({required this.mcpMode});

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  late AiProvider _provider;
  late final TextEditingController _model;
  final TextEditingController _endpoint = TextEditingController();
  final TextEditingController _key = TextEditingController();
  final TextEditingController _mcpUrl = TextEditingController();
  final TextEditingController _mcpToken = TextEditingController();
  bool _hideKey = true;
  bool _busy = false;
  String? _error;

  List<AiProvider> get _providers => widget.mcpMode
      ? AiProvider.values.where((p) => p.supportsMcp).toList()
      : AiProvider.values;

  @override
  void initState() {
    super.initState();
    _provider = widget.mcpMode ? AiProvider.anthropic : AiProvider.gemini;
    _model = TextEditingController(text: _provider.defaultModel);
    _endpoint.text = _provider.defaultEndpoint;
  }

  @override
  void dispose() {
    _model.dispose();
    _endpoint.dispose();
    _key.dispose();
    _mcpUrl.dispose();
    _mcpToken.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProvider? p) {
    if (p == null) return;
    setState(() {
      _provider = p;
      _model.text = p.defaultModel;
      _endpoint.text = p.defaultEndpoint;
      _error = null;
    });
  }

  Future<void> _connect() async {
    final model = _model.text.trim();
    final key = _key.text.trim();
    final endpoint = _endpoint.text.trim();
    final mcpUrl = _mcpUrl.text.trim();

    if (model.isEmpty || key.isEmpty) {
      setState(() => _error = 'اسم النموذج ومفتاح الـ API مطلوبان.');
      return;
    }
    if (widget.mcpMode && !mcpUrl.startsWith('https://')) {
      setState(() => _error = 'أدخل رابط خادم MCP يبدأ بـ https://');
      return;
    }
    if (!widget.mcpMode &&
        _provider == AiProvider.custom &&
        !endpoint.startsWith('http')) {
      setState(() => _error = 'أدخل رابط API صحيحاً يبدأ بـ https://');
      return;
    }

    final config = AiModelConfig(
      provider: _provider,
      model: model,
      endpoint: endpoint,
      apiKey: key,
      mcpUrl: widget.mcpMode ? mcpUrl : '',
      mcpToken: widget.mcpMode ? _mcpToken.text.trim() : '',
    );

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // اختبار اتصال حقيقي قبل الحفظ (للتأكد من المفتاح والنموذج وخادم MCP)
      await AiClientFactory.create(config).send(
        systemPrompt: 'أجب بكلمة واحدة فقط: تم',
        history: const [AiTurn(isUser: true, text: 'اختبار الاتصال')],
        temperature: 0,
      );
      if (!mounted) return;
      Navigator.of(context).pop(config);
    } on AiClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقع: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mcp = widget.mcpMode;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mcp ? 'الربط عبر خادم MCP بعيد' : 'الربط عبر API',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AiProvider>(
              value: _provider,
              decoration: InputDecoration(
                labelText: mcp ? 'النموذج الذي يستخدم أدوات الخادم' : 'المزوّد',
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final p in _providers)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: _busy ? null : _onProviderChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _model,
              enabled: !_busy,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'اسم النموذج',
                border: OutlineInputBorder(),
              ),
            ),
            if (!mcp && _provider == AiProvider.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _endpoint,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رابط API (chat/completions)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _key,
              enabled: !_busy,
              obscureText: _hideKey,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'مفتاح API',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _hideKey = !_hideKey),
                ),
              ),
            ),
            if (mcp) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _mcpUrl,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رابط خادم MCP (https://...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mcpToken,
                enabled: !_busy,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'توكن مصادقة الخادم (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _connect,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('اتصال وحفظ'),
            ),
          ],
        ),
      ),
    );
  }
}