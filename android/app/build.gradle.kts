plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin Google Services pour Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.application_amende"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.application_amende"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
    // Import des librairies Firebase essentielles
    implementation(platform("com.google.firebase:firebase-bom:33.3.0")) // BOM gère les versions
    implementation("com.google.firebase:firebase-analytics")           // Analytics
    implementation("com.google.firebase:firebase-auth")                // Authentification
    implementation("com.google.firebase:firebase-firestore")           // Firestore Database
    implementation("com.google.firebase:firebase-storage")             // Stockage
}
