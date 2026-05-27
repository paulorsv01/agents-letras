#!/usr/bin/env bash
# kmp-bootstrap: scaffold a Kotlin Multiplatform project (AGP 9 full restructure)
# with a shared KMP library and dedicated per-platform app modules.
#
# Usage: bootstrap.sh <AppName> <package.id> [dest-dir]
#
# Example:
#   bootstrap.sh HelloKMP com.example.hellokmp ~/Projects/HelloKMP
#
# Defaults: minSdk 26 (Android 8), JDK 21, AGP 9.2.0, Gradle 9.4.1, Kotlin 2.3.21, Compose Multiplatform 1.10.3.
# iOS targets: iosX64, iosArm64, iosSimulatorArm64. Framework baseName = "shared", static.
# iosApp skeleton is vendored under assets/templates/iosApp/ and copied in locally — no network fetch.
# Interactively asks about Koin DI and Apple DEVELOPMENT_TEAM.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERLAY="$SKILL_ROOT/bootstrap"
MAKEFILE_SRC="$SKILL_ROOT/Makefile"
IOS_TEMPLATE="$SKILL_ROOT/iosApp"

# ---- args ----------------------------------------------------------
if [ $# -lt 2 ]; then
  sed -n '3,15p' "$0" >&2
  exit 2
fi
APP_NAME="$1"
PACKAGE="$2"
DEST="${3:-./$APP_NAME}"

if ! [[ "$APP_NAME" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
  echo "Error: AppName must be PascalCase ASCII: ${APP_NAME}" >&2
  exit 1
fi
if ! [[ "$PACKAGE" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$ ]]; then
  echo "Error: package must be reverse-DNS lowercase, segments [a-z][a-z0-9]* joined by dots (no underscore — the same value is used as iOS BUNDLE_ID): ${PACKAGE}" >&2
  exit 1
fi
if [ -e "$DEST" ] && [ "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "Error: dest '$DEST' is not empty." >&2
  exit 1
fi

PACKAGE_PATH="${PACKAGE//.//}"
MIN_SDK=26
GRADLE_VERSION=9.4.1

# ---- deps check ---------------------------------------------------
require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }
}
require android
require sed
require git
require awk

# ---- prompts ------------------------------------------------------
ask_yn() {
  local prompt="$1" default="${2:-n}" reply
  if [ "$default" = "y" ]; then prompt="$prompt [Y/n] "; else prompt="$prompt [y/N] "; fi
  read -r -p "$prompt" reply || true
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

echo ">> Bootstrapping KMP project $APP_NAME ($PACKAGE) into $DEST"
USE_KOIN=false
if ask_yn "Add Koin DI scaffolding (commonMain + Android startup)?" n; then USE_KOIN=true; fi

# Optional: Apple Development Team for iOS signing.
read -r -p "Apple DEVELOPMENT_TEAM (optional, empty for simulator-only): " TEAM_ID
TEAM_ID="${TEAM_ID:-}"

# ---- 1. scaffold via android create (we reuse its Gradle wrapper + base toml) ----
echo ">> Scaffolding with android create (used only for the Gradle wrapper)"
android create --name "$APP_NAME" --minSdk "$MIN_SDK" -o "$DEST" empty-activity >/dev/null

cd "$DEST"
rm -rf app  # we rebuild as :shared + :androidApp

echo ">> Pinning Gradle wrapper $GRADLE_VERSION"
sed -i '' "s#^distributionUrl=.*#distributionUrl=https\\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip#" gradle/wrapper/gradle-wrapper.properties

# ---- 2. copy overlay + Makefile + scripts -------------------------
echo ">> Applying overlay"
cp "$OVERLAY/.editorconfig" .
cp -R "$OVERLAY/.githooks" .
chmod +x .githooks/pre-commit
cp "$OVERLAY/version.env" .
cat "$OVERLAY/gitignore.extras" >> .gitignore

cp "$MAKEFILE_SRC" .

# Bump Gradle heap — Kotlin/Native XCFramework linker needs >2GB for all iOS slices.
if grep -q '^org.gradle.jvmargs=' gradle.properties; then
    awk '
        /^org\.gradle\.jvmargs=/ { print "org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8"; next }
        { print }
    ' gradle.properties > gradle.properties.new && mv gradle.properties.new gradle.properties
fi

mkdir -p scripts
for s in "$SCRIPT_DIR"/*.sh; do
    name=$(basename "$s")
    [ "$name" = "bootstrap.sh" ] && continue
    cp "$s" scripts/
done
chmod +x scripts/*.sh

# ---- 3. libs.versions.toml (rewritten from scratch for KMP) -------
echo ">> Writing gradle/libs.versions.toml"
cat > gradle/libs.versions.toml <<'EOF'
[versions]
agp = "9.2.0"
kotlin = "2.3.21"
composeMultiplatform = "1.10.3"
ktlint = "12.1.1"
ktlintEngine = "1.5.0"
mockk = "1.14.7"
turbine = "1.2.1"
coroutines = "1.10.2"
koin = "4.2.1"
androidxCore = "1.18.0"
androidxActivity = "1.13.0"
androidxLifecycle = "2.10.0"
androidxTest = "1.7.0"
androidxTestExt = "1.3.0"
androidxTestEspresso = "3.7.0"
junit = "4.13.2"

[libraries]
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
androidx-core-ktx = { module = "androidx.core:core-ktx", version.ref = "androidxCore" }
androidx-activity-compose = { module = "androidx.activity:activity-compose", version.ref = "androidxActivity" }
androidx-lifecycle-runtime-ktx = { module = "androidx.lifecycle:lifecycle-runtime-ktx", version.ref = "androidxLifecycle" }
androidx-lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "androidxLifecycle" }
androidx-test-core = { module = "androidx.test:core", version.ref = "androidxTest" }
androidx-test-ext-junit = { module = "androidx.test.ext:junit", version.ref = "androidxTestExt" }
androidx-test-espresso-core = { module = "androidx.test.espresso:espresso-core", version.ref = "androidxTestEspresso" }
junit = { module = "junit:junit", version.ref = "junit" }
mockk = { module = "io.mockk:mockk", version.ref = "mockk" }
turbine = { module = "app.cash.turbine:turbine", version.ref = "turbine" }
koin-core = { module = "io.insert-koin:koin-core", version.ref = "koin" }
koin-android = { module = "io.insert-koin:koin-android", version.ref = "koin" }
koin-compose = { module = "io.insert-koin:koin-compose", version.ref = "koin" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-kmp-library = { id = "com.android.kotlin.multiplatform.library", version.ref = "agp" }
kotlin-multiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
compose-multiplatform = { id = "org.jetbrains.compose", version.ref = "composeMultiplatform" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlint" }
EOF

# ---- 4. root build.gradle.kts -------------------------------------
echo ">> Writing root build.gradle.kts"
cat > build.gradle.kts <<'EOF'
import org.jlleitschuh.gradle.ktlint.KtlintExtension
import org.jlleitschuh.gradle.ktlint.reporter.ReporterType

// Top-level build file — plugins declared apply false, applied per-subproject.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.kmp.library) apply false
    alias(libs.plugins.kotlin.multiplatform) apply false
    alias(libs.plugins.compose.multiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.ktlint) apply false
}

subprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
    extensions.configure<KtlintExtension> {
        // Keep in sync with gradle/libs.versions.toml -> [versions] ktlintEngine.
        version.set("1.5.0")
        android.set(true)
        ignoreFailures.set(false)
        reporters {
            reporter(ReporterType.PLAIN)
            reporter(ReporterType.CHECKSTYLE)
        }
        filter {
            exclude { it.file.path.contains("/build/") }
            exclude { it.file.path.contains("/generated/") }
        }
    }
}
EOF

# ---- 5. settings.gradle.kts ---------------------------------------
echo ">> Writing settings.gradle.kts"
cat > settings.gradle.kts <<EOF
rootProject.name = "$APP_NAME"

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

include(":shared", ":androidApp")
EOF

# ---- 6. shared/ module --------------------------------------------
echo ">> Writing shared/ module"
mkdir -p "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/commonTest/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/androidMain/kotlin/$PACKAGE_PATH/shared"
mkdir -p "shared/src/iosMain/kotlin/$PACKAGE_PATH/shared"

cat > shared/build.gradle.kts <<EOF
import org.jetbrains.kotlin.gradle.ExperimentalKotlinGradlePluginApi
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.plugin.mpp.KotlinNativeTarget
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.compose.compiler)
}

val xcf = XCFramework("shared")

kotlin {
    applyDefaultHierarchyTemplate()

    @OptIn(ExperimentalKotlinGradlePluginApi::class)
    compilerOptions {
        freeCompilerArgs.add("-Xexpect-actual-classes")
    }

    android {
        namespace = "$PACKAGE.shared"
        compileSdk = 36
        minSdk = $MIN_SDK
        withHostTest {}
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_21)
        }
    }

    iosX64()
    iosArm64()
    iosSimulatorArm64()

    targets.withType<KotlinNativeTarget>().configureEach {
        binaries.framework {
            baseName = "shared"
            isStatic = true
            xcf.add(this)
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.foundation)
            implementation(compose.material3)
            implementation(compose.components.resources)
            implementation(compose.ui)
            implementation(libs.kotlinx.coroutines.core)
EOF
if $USE_KOIN; then
  cat >> shared/build.gradle.kts <<'EOF'
            implementation(libs.koin.core)
            implementation(libs.koin.compose)
EOF
fi
cat >> shared/build.gradle.kts <<'EOF'
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.kotlinx.coroutines.test)
            implementation(libs.turbine)
        }
        androidMain.dependencies {
            implementation(libs.kotlinx.coroutines.android)
EOF
if $USE_KOIN; then
  cat >> shared/build.gradle.kts <<'EOF'
            implementation(libs.koin.android)
EOF
fi
cat >> shared/build.gradle.kts <<'EOF'
        }
    }
}
EOF

# Shared App composable (commonMain)
cat > "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared/App.kt" <<EOF
package $PACKAGE.shared

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun App() {
    MaterialTheme {
        Surface(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier.fillMaxSize().padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = "Hello from \${Platform().name}",
                    style = MaterialTheme.typography.headlineMedium,
                )
            }
        }
    }
}
EOF

# expect/actual Platform class — demonstrates source set hierarchy
cat > "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared/Platform.kt" <<EOF
package $PACKAGE.shared

expect class Platform() {
    val name: String
}
EOF

cat > "shared/src/androidMain/kotlin/$PACKAGE_PATH/shared/Platform.android.kt" <<EOF
package $PACKAGE.shared

import android.os.Build

actual class Platform actual constructor() {
    actual val name: String = "Android \${Build.VERSION.SDK_INT}"
}
EOF

cat > "shared/src/iosMain/kotlin/$PACKAGE_PATH/shared/Platform.ios.kt" <<EOF
package $PACKAGE.shared

import platform.UIKit.UIDevice

actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
}
EOF

# commonTest example
cat > "shared/src/commonTest/kotlin/$PACKAGE_PATH/shared/PlatformTest.kt" <<EOF
package $PACKAGE.shared

import kotlin.test.Test
import kotlin.test.assertTrue

class PlatformTest {
    @Test
    fun platform_has_non_empty_name() {
        assertTrue(Platform().name.isNotBlank())
    }
}
EOF

# Optional iosApp entry point for framework (used by Xcode)
cat > "shared/src/iosMain/kotlin/$PACKAGE_PATH/shared/MainViewController.kt" <<EOF
package $PACKAGE.shared

import androidx.compose.ui.window.ComposeUIViewController

// Exported to iOS as \`MainViewControllerKt.MainViewController()\`.
@Suppress("ktlint:standard:function-naming")
fun MainViewController() = ComposeUIViewController { App() }
EOF

# ---- 7. androidApp/ module ----------------------------------------
echo ">> Writing androidApp/ module"
mkdir -p "androidApp/src/main/java/$PACKAGE_PATH"
mkdir -p "androidApp/src/main/res/values"
mkdir -p "androidApp/src/test/java/$PACKAGE_PATH"
mkdir -p "androidApp/src/androidTest/java/$PACKAGE_PATH"

cat > androidApp/build.gradle.kts <<EOF
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
}

val versionProps = rootProject.file("version.env").readLines()
    .filter { "=" in it && !it.startsWith("#") }
    .associate { it.substringBefore("=").trim() to it.substringAfter("=").trim() }

val signingEnv: Map<String, String> = rootProject.file(".signing.env").takeIf { it.exists() }
    ?.readLines()
    ?.filter { "=" in it && !it.startsWith("#") }
    ?.associate { it.substringBefore("=").trim() to it.substringAfter("=").trim() }
    .orEmpty()

android {
    namespace = "$PACKAGE"
    compileSdk = 36

    defaultConfig {
        applicationId = "$PACKAGE"
        minSdk = $MIN_SDK
        targetSdk = 36
        versionCode = versionProps["VERSION_CODE"]!!.toInt()
        versionName = versionProps["VERSION_NAME"]
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            if (signingEnv.isNotEmpty()) {
                storeFile = rootProject.file(signingEnv.getValue("KEYSTORE_PATH"))
                storePassword = signingEnv["KEYSTORE_PASSWORD"]
                keyAlias = signingEnv["KEY_ALIAS"]
                keyPassword = signingEnv["KEY_PASSWORD"]
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (signingEnv.isNotEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    buildFeatures {
        compose = true
        aidl = false
        buildConfig = false
        shaders = false
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    implementation(project(":shared"))

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)

    testImplementation(libs.junit)
    testImplementation(kotlin("test"))
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.mockk)
    testImplementation(libs.turbine)

    androidTestImplementation(libs.androidx.test.core)
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.espresso.core)
EOF
if $USE_KOIN; then
  cat >> androidApp/build.gradle.kts <<'EOF'

    implementation(libs.koin.android)
    implementation(libs.koin.compose)
EOF
fi
cat >> androidApp/build.gradle.kts <<'EOF'
}
EOF

# Android manifest
cat > androidApp/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.App">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > androidApp/src/main/res/values/strings.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOF

cat > androidApp/src/main/res/values/themes.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.App" parent="android:Theme.Material.Light.NoActionBar" />
</resources>
EOF

cat > "androidApp/src/main/java/$PACKAGE_PATH/MainActivity.kt" <<EOF
package $PACKAGE

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import $PACKAGE.shared.App

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { App() }
    }
}
EOF

# ---- 8. iosApp/ (vendored skeleton; Config.xcconfig rewritten below) -----
echo ">> Copying iosApp/ skeleton from vendored template"
cp -R "$IOS_TEMPLATE" iosApp

# ---- 9. Config.xcconfig (Letras-style) ----------------------------
echo ">> Writing iosApp/Configuration/Config.xcconfig"
mkdir -p iosApp/Configuration
VERSION_NAME=$(grep '^VERSION_NAME=' version.env | cut -d= -f2)
VERSION_CODE=$(grep '^VERSION_CODE=' version.env | cut -d= -f2)
cat > iosApp/Configuration/Config.xcconfig <<EOF
// Identity (used by xcodeproj configurations)
TEAM_ID=$TEAM_ID
BUNDLE_ID=$PACKAGE
APP_NAME=$APP_NAME

// Xcode built-in build settings (picked up automatically)
DEVELOPMENT_TEAM=\$(TEAM_ID)
PRODUCT_BUNDLE_IDENTIFIER=\$(BUNDLE_ID)
PRODUCT_NAME=\$(APP_NAME)

// Versioning — mirrored from version.env by \`make sync-version\`.
MARKETING_VERSION=$VERSION_NAME
CURRENT_PROJECT_VERSION=$VERSION_CODE
EOF

# ---- 10. Koin scaffolding (optional) -----------------------------
if $USE_KOIN; then
    echo ">> Scaffolding Koin modules"
    mkdir -p "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared/di"
    cat > "shared/src/commonMain/kotlin/$PACKAGE_PATH/shared/di/KoinModule.kt" <<EOF
package $PACKAGE.shared.di

import org.koin.dsl.module

val sharedModule = module {
    // single { MyRepository() }
}
EOF
    # Android Application class that starts Koin
    APP_CLASS_PATH="androidApp/src/main/java/$PACKAGE_PATH/${APP_NAME}Application.kt"
    cat > "$APP_CLASS_PATH" <<EOF
package $PACKAGE

import android.app.Application
import $PACKAGE.shared.di.sharedModule
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

class ${APP_NAME}Application : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@${APP_NAME}Application)
            modules(sharedModule)
        }
    }
}
EOF
    # Register Application in AndroidManifest
    sed -i '' "s|<application|<application\\
        android:name=\".${APP_NAME}Application\"|" androidApp/src/main/AndroidManifest.xml
fi

# ---- 11. git init + hooks ----------------------------------------
if [ ! -d .git ]; then
    git init -q
fi
./scripts/setup.sh

# ---- 12. done ----------------------------------------------------
cat <<EOF

✓ Bootstrap complete: $DEST

Next steps:
  cd $DEST
  make setup               # restore hooks and local Codex metadata if needed
  # optional: run agents-bootstrap to add AGENTS.md + CLAUDE.md
  make dev-android         # emulator + install + launch (Android)
  make emulator-cold       # cold boot Android if snapshots get weird
  make dev-ios             # simulator + xcodebuild + install + launch (iOS)
  make test                # shared Android host tests + androidApp unit tests
  make ios-test            # iOS simulator unit tests
  make lint                # ktlint across all modules
  make xcframework         # produce release XCFramework

Release (after setting up signing):
  scripts/setup_signing.sh   # Android keystores
  make release               # bundleRelease + assembleSharedXCFramework + gh release

EOF
