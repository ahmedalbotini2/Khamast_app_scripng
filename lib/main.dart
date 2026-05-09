import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:khmsat_services/screens/main_screen.dart';
import 'package:khmsat_services/screens/splach_screen.dart';
import 'package:khmsat_services/services/background_service.dart';
import 'package:khmsat_services/services/notification.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeServiceBackground();
    await NotificationService.init();
    Gemini.init(apiKey: 'AIzaSyAvHsSfEWZfCCGahX-VLoeu4XVp2X6jimg');
  } catch (error) {
    debugPrint('$error');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFF8F5EF),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFF111111),
          surface: Color(0xFFFFF8E6),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          elevation: 0.0,
          centerTitle: true,
        ),
      ),
      home: SplachScreen(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   heroTag: 'main_fab',
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const WebScreen()),
      //     );
      //   },
      //   backgroundColor: const Color(0xFFD4AF37),
      //   child: const Icon(Icons.g_mobiledata_outlined, color: Colors.black),
      // ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 0.0,
        shadowColor: const Color(0x33000000),
        centerTitle: true,
        title: const Text(
          'خمسات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5D1), Color(0xFFF8F5EF)],
          ),
        ),
        child: const MainScreen(),
      ),
    );
  }
}
