plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.chatbot_drseu_v1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.chatbot_drseu_v1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // CAMBIO 2: Habilitar Multidex (Necesario para Firebase)
        multiDexEnabled = true
    }

    buildTypes {
        getByName("debug") {
            // 👇 ESTA ES LA SOLUCIÓN: Pon esto en false
            isShrinkResources = false
            isMinifyEnabled = false

            // Lo que agregamos antes (déjalo igual)
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-TEST"
            isDebuggable = true
        }

        getByName("release") {
            // En release sí puedes querer optimizar
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
