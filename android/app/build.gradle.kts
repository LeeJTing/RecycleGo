plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

configurations.all {
    resolutionStrategy {
        force("com.google.ai.edge.litert:litert:1.4.0")
        force("com.google.ai.edge.litert:litert-api:1.4.0")
        force("com.google.ai.edge.litert:litert-gpu:1.4.0")
        
        dependencySubstitution {
            substitute(module("org.tensorflow:tensorflow-lite"))
                .using(module("com.google.ai.edge.litert:litert:1.4.0"))
            substitute(module("org.tensorflow:tensorflow-lite-api"))
                .using(module("com.google.ai.edge.litert:litert-api:1.4.0"))
            substitute(module("org.tensorflow:tensorflow-lite-gpu"))
                .using(module("com.google.ai.edge.litert:litert-gpu:1.4.0"))
            substitute(module("org.tensorflow:tensorflow-lite-gpu-api"))
                .using(module("com.google.ai.edge.litert:litert-gpu:1.4.0"))
        }
    }
}

android {
    namespace = "com.tarumt.recyclego.recycle_go"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }


    defaultConfig {
        applicationId = "com.tarumt.recyclego.recycle_go"
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
