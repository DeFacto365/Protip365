plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
    // id("com.google.gms.google-services")
    // id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.protip365.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.protip365.monthly"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            // Remove suffix for debug builds to match google-services.json
            // applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Core Android dependencies
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")

    // Compose BOM
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material")
    implementation("androidx.compose.material:material-icons-extended")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Hilt for Dependency Injection
    implementation("com.google.dagger:hilt-android:2.48")
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    ksp("com.google.dagger:hilt-compiler:2.48")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // Supabase
    implementation("io.github.jan-tennert.supabase:postgrest-kt:2.5.3")
    implementation("io.github.jan-tennert.supabase:gotrue-kt:2.5.3")
    implementation("io.github.jan-tennert.supabase:storage-kt:2.5.3")
    implementation("io.github.jan-tennert.supabase:realtime-kt:2.5.3")

    // Ktor client for Supabase
    implementation("io.ktor:ktor-client-android:2.3.7")
    implementation("io.ktor:ktor-client-content-negotiation:2.3.7")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.7")
    implementation("io.ktor:ktor-client-logging:2.3.7")
    
    // SLF4J Android logger to fix logging warnings
    implementation("org.slf4j:slf4j-android:1.7.36")

    // Kotlinx Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    // Gson for JSON serialization
    implementation("com.google.code.gson:gson:2.10.1")

    // Kotlinx DateTime
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")

    // DataStore for preferences
    implementation("androidx.datastore:datastore-preferences:1.0.0")

    // Biometric
    implementation("androidx.biometric:biometric:1.1.0")

    // Security Crypto for encrypted preferences
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Google Play Billing
    implementation("com.android.billingclient:billing-ktx:6.1.0")

    // Splash Screen
    implementation("androidx.core:core-splashscreen:1.0.1")

    // Work Manager for background tasks
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // Calendar View
    implementation("com.kizitonwose.calendar:compose:2.5.0")

    // Charts
    implementation("com.patrykandpatrick.vico:compose-m3:2.0.0-alpha.19")

    // CSV Export
    implementation("com.opencsv:opencsv:5.9")

    // Accompanist for additional Compose utilities
    implementation("com.google.accompanist:accompanist-permissions:0.32.0")
    implementation("com.google.accompanist:accompanist-systemuicontroller:0.32.0")

    // Firebase - temporarily disabled for testing
    // implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    // implementation("com.google.firebase:firebase-analytics-ktx")
    // implementation("com.google.firebase:firebase-crashlytics-ktx")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2024.02.00"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}

// kapt {
//     correctErrorTypes = true
// }