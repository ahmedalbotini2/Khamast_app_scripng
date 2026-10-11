import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// تأكد من صحة المسارات في مشروعك
import 'package:khmsat_services/screens/ai/view/chat_screen.dart';
import 'package:khmsat_services/screens/profile/view/profile_screen.dart';
import 'package:khmsat_services/screens/service/view/services_screen.dart';
import 'package:khmsat_services/screens/setting/view/setting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectIndex = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String userName = '';
  String cookiez = '';

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    String? storedName = await _storage.read(key: 'saved_username');
    String? storedCookies = await _storage.read(key: 'session_cookies');

    if (mounted) {
      setState(() {
        userName = storedName ?? '';
        cookiez = storedCookies ?? '';
      });
    }
  }

  Widget _buildBody() {
    switch (selectIndex) {
      case 0:
        return const DataServices();
      case 1:
        return const ChatScreen();
      case 2:
        return ProfileScreen(username: userName, cookies: cookiez);
      case 3:
        return const SettingsScreen();
      default:
        return const DataServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // يسمح للمحتوى بالامتداد خلف الشريط الزجاجي
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: selectIndex,
        onTap: (val) => setState(() => selectIndex = val),
        items: const [
          GlassNavItem(icon: Icons.monetization_on_rounded, label: 'الخدمات'),
          GlassNavItem(icon: Icons.chat_bubble_rounded, label: 'المحادثات'),
          GlassNavItem(icon: Icons.account_circle_rounded, label: 'الملف'),
          GlassNavItem(icon: Icons.settings_rounded, label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// شريط التنقل الزجاجي
// ---------------------------------------------------------------------------

class GlassNavItem {
  final IconData icon;
  final String label;
  const GlassNavItem({required this.icon, required this.label});
}

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final baseColor = isDark ? Colors.white : Colors.white;
    final glassFill = baseColor.withAlpha(isDark ? 28 : 120);
    final glassBorder = baseColor.withAlpha(isDark ? 60 : 180);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: glassBorder, width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [glassFill, glassFill.withAlpha(isDark ? 12 : 60)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 30),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                return Expanded(
                  child: _GlassNavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    isDark: isDark,
                    accent: theme.colorScheme.primary,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _GlassNavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: selected ? accent.withAlpha(45) : Colors.transparent,
          border: Border.all(
            color: selected ? accent.withAlpha(110) : Colors.white,
            width: 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: accent.withAlpha(60),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                item.icon,
                size: 24,
                color: selected ? accent : inactive,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
