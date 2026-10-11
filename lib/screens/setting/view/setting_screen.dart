import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmsat_services/screens/setting/model/setting_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _bg = Color(0xFFF7F5EE);
  static const Color _black = Color(0xFF111111);
  static const Color _danger = Color(0xFFC62828);

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                title,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w700,
                  color: _black,
                ),
              ),
              content: Text(message, style: GoogleFonts.tajawal(color: _black)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.tajawal(color: _black),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    confirmText,
                    style: GoogleFonts.tajawal(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
    return result ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'تسجيل الخروج',
      message: 'هل تريد تسجيل الخروج من حسابك في خمسات؟',
      confirmText: 'تسجيل الخروج',
    );
    if (!ok) return;

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'session_cookies');
    await storage.delete(key: 'saved_username');
    await CookieManager.instance().deleteAllCookies();

    if (!context.mounted) return;
    // TODO: انتقل إلى WebScreen كما تفعل في profile_screen.dart
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (_) => const WebScreen(...)),
    //   (route) => false,
    // );
  }

  Future<void> _removeAiLink(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'حذف الربط مع الذكاء الاصطناعي',
      message:
          'سيتم حذف بيانات الربط الحالية، وستحتاج لإعادة الربط لاستخدام المحادثة.',
      confirmText: 'حذف',
    );
    if (!ok) return;

    // TODO: احذف مفاتيح ربط الـ API/MCP التي تخزنها (بالاسم الذي استعملته)
    // const storage = FlutterSecureStorage();
    // await storage.delete(key: 'ai_link_key');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف الربط', style: GoogleFonts.tajawal())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 84,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Container(
              width: double.infinity,
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
                  const Icon(Icons.settings_rounded, color: _gold),
                  const SizedBox(width: 10),
                  Text(
                    'الإعدادات',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  SettingItem(
                    title: 'حذف الربط مع الذكاء الاصطناعي',
                    icon: Icons.link_off_rounded,
                    onTap: () => _removeAiLink(context),
                  ),
                  SettingItem(
                    title: 'تسجيل الخروج',
                    icon: Icons.logout_rounded,
                    isDestructive: true,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  '1.2.1 by Ahmed AL-Botini',
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: _black.withAlpha(130),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
