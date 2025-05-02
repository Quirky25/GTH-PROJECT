plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // ✅ Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.project"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true // ✅ Kotlin DSL syntax
        sourceCompatibility = JavaVersion.toVersion("11") // ✅ Fixed syntax
        targetCompatibility = JavaVersion.toVersion("11") // ✅ Fixed syntax
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("androidx.core:core-ktx:1.9.0")

    // ✅ Required for core library desugaring (Kotlin DSL)
      coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // 🔹 Update from 2.0.3 to 2.1.4
}
