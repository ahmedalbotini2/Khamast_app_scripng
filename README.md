# Khmsat Services - Flutter Application

A Flutter application for browsing and managing services from Khamsat (خمسات) - the Arabic marketplace for microservices.

## 📱 Overview

Khmsat Services is a Flutter mobile application that allows users to browse, search, and manage services from Khamsat (خمسات), the leading Arabic marketplace for microservices. The app provides a clean, modern UI with Arabic RTL support and integrates with various services including AI-powered features, background notifications, and web scraping capabilities.

## ✨ Features

- **Service Browsing**: Browse and search services from Khamsat marketplace
- **Service Details**: View detailed information about each service
- **AI Integration**: Google Gemini AI integration for enhanced features
- **Background Services**: Background service for notifications and data sync
- **Push Notifications**: Local and push notifications support
- **Web Scraping**: Web scraping service to fetch latest services from Khamsat
- **Skeleton Loading**: Skeleton loading screens for better UX
- **Pull-to-Refresh**: Pull-to-refresh functionality for data updates
- **RTL Support**: Full RTL (Right-to-Left) support for Arabic language
- **Modern UI**: Material 3 design with custom theming
- **Splash Screen**: Animated splash screen with Lottie animations
- **Video Player**: Video playback support
- **Web View**: In-app web browsing capabilities

## 🛠 Tech Stack

### Frontend
- **Flutter** (v3.7.2+) - Cross-platform UI framework
- **Dart** - Programming language
- **Material 3** - Design system

### Key Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_gemini` | ^2.0.2 | Google Gemini AI integration |
| `flutter_background_service` | ^5.0.5 | Background service for notifications |
| `flutter_local_notifications` | ^18.0.1 | Local notifications |
| `http` | ^1.2.2 | HTTP requests for web scraping |
| `html` | ^0.15.5 | HTML parsing for web scraping |
| `skeletonizer` | ^1.4.2 | Skeleton loading screens |
| `lottie` | ^3.1.2 | Lottie animations |
| `google_fonts` | ^6.2.1 | Google Fonts (Tajawal for Arabic) |
| `video_player` | ^2.9.2 | Video playback |
| `webview_flutter` | ^4.8.0 | In-app web browsing |
| `flutter_secure_storage` | ^9.2.2 | Secure storage for sensitive data |
| `shared_preferences` | ^2.3.2 | Local preferences storage |
| `path_provider` | ^2.1.4 | File system access |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `device_info_plus` | ^11.1.1 | Device information |
| `package_info_plus` | ^8.1.0 | App package information |
| `intl` | ^0.19.0 | Internationalization |
| `flutter_animate` | ^4.5.0 | Animations |
| `flutter_staggered_animations` | ^1.1.1 | Staggered animations |
| `flutter_screenutil` | ^5.9.3 | Responsive design |

### Development Dependencies
- `flutter_test` - Unit and widget testing
- `flutter_lints` - Linting rules

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── resources/
│   └── data.dart            # Data models
├── screens/
│   ├── main_screen.dart     # Main navigation screen
│   ├── services_screen.dart # Services listing screen
│   ├── order_screen.dart    # Order details screen
│   ├── splach_screen.dart   # Splash screen
│   └── web_screen.dart      # Web view screen
├── services/
│   ├── services_scrept.dart # Web scraping service
│   ├── Ai_service.dart      # AI service integration
│   ├── background_service.dart # Background service
│   └── notification.dart    # Notification service
├── widgets/
│   └── custome_widghit.dart # Custom UI widgets
└── assets/                  # Images, Lottie animations, videos
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.7.2 or higher)
- Dart SDK (v3.7.2 or higher)
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd khmsat_services
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   - Add your Google Gemini API key in `lib/main.dart`:
     ```dart
     Gemini.init(apiKey: 'YOUR_GEMINI_API_KEY');
     ```

4. **Run the app**
   ```bash
   # For Android
   flutter run
   
   # For iOS (macOS only)
   flutter run -d ios
   
   # For Web
   flutter run -d chrome
   ```

## 📱 Platform Support

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported |
| iOS      | ✅ Supported |
| Web      | ✅ Supported |
| Windows  | ✅ Supported |
| macOS    | ✅ Supported |
| Linux    | ✅ Supported |

## 🔧 Configuration

### Android Configuration
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Permissions configured in `android/app/src/main/AndroidManifest.xml`

### iOS Configuration
- Minimum iOS: 12.0
- Permissions configured in `ios/Runner/Info.plist`

### Web Configuration
- Configured in `web/index.html` and `web/manifest.json`

## 🎨 Theming

The app uses Material 3 with a custom color scheme:
- **Primary Color**: `#D4AF37` (Gold)
- **Secondary Color**: `#111111` (Dark Gray)
- **Surface Color**: `#FFF8E6` (Light Cream)
- **Background**: `#F8F5EF` (Off-white)

Arabic font: **Tajawal** (via Google Fonts)

## 🔔 Notifications & Background Services

The app includes:
- **Local Notifications**: Using `flutter_local_notifications`
- **Background Service**: Using `flutter_background_service` for periodic tasks
- **Permission Handling**: Runtime permissions for notifications and background execution

## 🤖 AI Integration

Integrated with **Google Gemini AI** for enhanced features:
- API Key configured in `main.dart`
- Used for service recommendations and analysis

## 🌐 Web Scraping

The app includes a web scraping service (`WebScrepingServices`) that:
- Fetches services from `https://khamsat.com/community/requests`
- Parses HTML using the `html` package
- Extracts service name, image, description, and ID
- Provides pull-to-refresh functionality

## 📦 Building for Release

### Android
```bash
# APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📝 Code Style

The project follows:
- **Effective Dart** guidelines
- **flutter_lints** package for linting
- **Material 3** design principles

Run linter:
```bash
flutter analyze
```

Format code:
```bash
dart format .
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email [support@khmsat-services.com] or create an issue in the repository.

## 🙏 Acknowledgments

- [Khamsat](https://khamsat.com) - The Arabic marketplace for microservices
- [Flutter](https://flutter.dev) - The UI framework
- [Google Gemini](https://ai.google.dev) - AI capabilities
- All open-source packages used in this project

---

**Made with ❤️ for the Arabic developer community**
