import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// تأكد من صحة المسارات في مشروعك
import 'package:khmsat_services/screens/chat_screen.dart';
import 'package:khmsat_services/screens/profile_screen.dart';
import 'package:khmsat_services/screens/services_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectIndex = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  String userName='';
  String cookiez='';

  @override
  void initState() {
    super.initState();
    // جلب البيانات فور تشغيل الشاشة لأول مرة
    getProfile();
  }

  Future<void> getProfile() async {
    // قراءة البيانات من التخزين الآمن
    String? storedName = await _storage.read(key: 'saved_username');
    String? storedCookies = await _storage.read(key: 'session_cookies');

    // تحديث الحالة ليعيد التطبيق بناء الواجهة بالبيانات الجديدة
    if (mounted) {
      setState(() {
        userName = storedName ?? '';
        cookiez = storedCookies ?? '';
      });
    }
  }

  // دالة بناء محتوى الشاشة بناءً على التبويب المختار
  Widget _buildBody() {
    switch (selectIndex) {
      case 0:
        // شاشة الخدمات
        return const DataServices();
      case 1:
        // شاشة المحادثات
        return const ChatScreen();
      case 2:
        // شاشة الملف الشخصي مع تمرير البيانات المحدثة
        return ProfileScreen(username: userName, cookies: cookiez);
      default:
        return const DataServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // عرض الشاشة المختارة
      body: _buildBody(),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectIndex,
        onTap: (val) {
          setState(() {
            selectIndex = val;
          });
        },
        // تأكد من تطابق ترتيب الأيقونات مع دالة _buildBody
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on), 
            label: 'الخدمات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat), 
            label: 'المحادثات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), 
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}