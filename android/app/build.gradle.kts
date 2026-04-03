plugins {
    id("com.android.application")
    id("kotlin-android") 
    // تأكد أن الإصدار في settings.gradle هو 1.9.20
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.khmsat_services"
    compileSdk = 36
    ndkVersion = "27.2.12479018";

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {

        applicationId = "com.example.khmsat_services"

        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
      constraints {
        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.2.0") {
            because("تحديث الإصدار لحل تعارض مكتبة network_info_plus")
        }
        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.20") {
            because("تحديث الإصدار لحل تعارض مكتبة network_info_plus")
        }
    }
}