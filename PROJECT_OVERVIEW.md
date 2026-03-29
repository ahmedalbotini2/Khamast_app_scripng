# وصف مشروع khmsat_services

تطبيق Flutter بسيط يعرض قائمة طلبات من مجتمع موقع خمسات عبر قراءة الصفحة العامة وجلب البيانات ثم عرضها في واجهة قائمة مع شاشة افتتاحية متحركة.

**الهدف**
عرض عناوين الطلبات وصور المستخدمين ووصف مختصر بطريقة قابلة للتحديث بالسحب (Pull-to-refresh).

**الوظائف الأساسية**
- شاشة افتتاحية متحركة تعرض أيقونة ونص (Animated Splash Screen).
- جلب بيانات من صفحة مجتمع خمسات (طلبات الخدمات) باستخدام HTTP و解析 HTML.
- بناء قائمة بطاقات لكل طلب مع الصورة والعنوان والوصف.
- دعم تحديث البيانات عبر `RefreshIndicator`.
- إظهار تأثيرات تحميل/تمويه باستخدام حزمة `redacted`.

**المعمارية والهيكل**
- الواجهة الرئيسية: `lib/main.dart`
- شاشة البداية: `lib/splach_screen.dart`
- جلب وتحليل البيانات (Web scraping): `lib/web_scriping/data_services.dart`
- نموذج البيانات: `lib/data_ui/data.dart`
- عنصر واجهة مخصص لبطاقة الطلب: `lib/data_ui/custome_widghit.dart`

**الاعتمادات (Dependencies)**
- `http`: لجلب محتوى الصفحة.
- `html`: لتحليل HTML واستخراج البيانات.
- `animated_splash_screen`: لشاشة البداية.
- `redacted`: لتأثيرات التحميل/التمويه.
- `shimmer`: موجودة في `pubspec.yaml` (غير مستخدمة في الكود الحالي).
- `rename`: أداة مساعدة (ليست جزءًا من الكود).

**نقطة الدخول**
- `main()` في `lib/main.dart` يشغل `SplachScreen` ثم ينتقل إلى `MainPage`.
- `MainPage` يعرض `DataServices` التي تعتمد على `WebScreping.extractData()`.

**مصدر البيانات**
- الصفحة المستهدفة: `https://khamsat.com/community/requests`
- يتم استخراج:
  - الصورة من `td.avatar-td img`
  - العنوان من `h3.details-head a`
  - الوصف من `ul.details-list li`

**ملاحظات**
- يعتمد التطبيق على بنية صفحة الويب؛ أي تغيّر في HTML قد يكسر الاستخراج.
- يوجد أخطاء إملائية في أسماء بعض الملفات/الكلاسات (مثل `Splach`, `Screping`, `CustomeWidghit`) لكنها لا تؤثر وظيفيًا.

**تشغيل سريع**
1. `flutter pub get`
2. `flutter run`
