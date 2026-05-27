#!/usr/bin/env bash
# android-bootstrap: scaffold a Kotlin/Compose Android project ready for development without Android Studio.
#
# Usage: bootstrap.sh <AppName> <package.id> [dest-dir]
#
# Example:
#   bootstrap.sh HelloApp com.example.hello ~/Projects/HelloApp
#
# Defaults: minSdk 26 (Android 8), JDK 21, AGP 9.2.0, Gradle 9.4.1, single-module :app.
# Interactively asks about Koin DI and multi-module split.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERLAY="$SKILL_ROOT/bootstrap"
MAKEFILE_SRC="$SKILL_ROOT/Makefile"

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
if ! [[ "$PACKAGE" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
  echo "Error: package must be reverse-DNS lowercase: ${PACKAGE}" >&2
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

# ---- prompts ------------------------------------------------------
ask_yn() {
  local prompt="$1" default="${2:-n}" reply
  if [ "$default" = "y" ]; then prompt="$prompt [Y/n] "; else prompt="$prompt [y/N] "; fi
  read -r -p "$prompt" reply || true
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

echo ">> Bootstrapping $APP_NAME ($PACKAGE) into $DEST"
USE_KOIN=false
USE_MULTI_MODULE=false
if ask_yn "Add Koin DI scaffolding?" n; then USE_KOIN=true; fi
if ask_yn "Split into :app + :core + :data modules?" n; then USE_MULTI_MODULE=true; fi

# ---- 1. android create --------------------------------------------
echo ">> Running: android create --name \"$APP_NAME\" --minSdk $MIN_SDK -o \"$DEST\""
android create --name "$APP_NAME" --minSdk "$MIN_SDK" -o "$DEST" empty-activity

cd "$DEST"

echo ">> Pinning Gradle wrapper $GRADLE_VERSION"
sed -i '' "s#^distributionUrl=.*#distributionUrl=https\\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip#" gradle/wrapper/gradle-wrapper.properties

# The default package from `android create` is com.example.<sanitized-name>
DEFAULT_PKG="com.example.$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"
DEFAULT_PATH="${DEFAULT_PKG//.//}"

# ---- 2. copy overlay ----------------------------------------------
echo ">> Applying overlay"
cp "$OVERLAY/.editorconfig" .
cp -R "$OVERLAY/.githooks" .
chmod +x .githooks/pre-commit
cp "$OVERLAY/version.env" .
cat "$OVERLAY/gitignore.extras" >> .gitignore

# Copy Makefile + scripts (excluding bootstrap.sh — that's skill-side only)
cp "$MAKEFILE_SRC" .
mkdir -p scripts
for s in "$SCRIPT_DIR"/*.sh; do
    name=$(basename "$s")
    [ "$name" = "bootstrap.sh" ] && continue
    cp "$s" scripts/
done
chmod +x scripts/*.sh

# ---- 2.1 gradle defaults -----------------------------------------
echo ">> Enabling Gradle configuration cache"
if grep -q '^org.gradle.configuration-cache=' gradle.properties; then
  sed -i '' 's/^org.gradle.configuration-cache=.*/org.gradle.configuration-cache=true/' gradle.properties
else
  printf '\norg.gradle.configuration-cache=true\n' >> gradle.properties
fi

# ---- 3. package rename --------------------------------------------
echo ">> Renaming package $DEFAULT_PKG → $PACKAGE"
for src in app/src/main/java app/src/test/java app/src/androidTest/java; do
  if [ -d "$src/$DEFAULT_PATH" ]; then
    mkdir -p "$src/$PACKAGE_PATH"
    # move contents, then clean up empty parent dirs
    mv "$src/$DEFAULT_PATH"/* "$src/$PACKAGE_PATH"/ 2>/dev/null || true
    # Walk up removing empty dirs under $src
    dir="$src/$DEFAULT_PATH"
    while [ "$dir" != "$src" ] && [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; do
      rmdir "$dir"
      dir="$(dirname "$dir")"
    done
  fi
done

# Replace package string in Kotlin sources and manifest
find app/src -type f \( -name '*.kt' -o -name 'AndroidManifest.xml' \) -print0 \
  | xargs -0 sed -i '' "s/$DEFAULT_PKG/$PACKAGE/g"

# ---- 4. libs.versions.toml patches --------------------------------
echo ">> Patching gradle/libs.versions.toml"
TOML=gradle/libs.versions.toml
TMPDIR_INJECT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_INJECT"' EXIT

cat > "$TMPDIR_INJECT/versions" <<'EOF'
ktlint = "12.1.1"
ktlintEngine = "1.5.0"
mockk = "1.14.7"
turbine = "1.2.1"
EOF
if $USE_KOIN; then
  echo 'koin = "4.2.1"' >> "$TMPDIR_INJECT/versions"
fi

cat > "$TMPDIR_INJECT/libraries" <<'EOF'
mockk = { module = "io.mockk:mockk", version.ref = "mockk" }
turbine = { module = "app.cash.turbine:turbine", version.ref = "turbine" }
EOF
if $USE_KOIN; then
  cat >> "$TMPDIR_INJECT/libraries" <<'EOF'
koin-android = { module = "io.insert-koin:koin-android", version.ref = "koin" }
koin-androidx-compose = { module = "io.insert-koin:koin-androidx-compose", version.ref = "koin" }
EOF
fi

cat > "$TMPDIR_INJECT/plugins" <<'EOF'
ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlint" }
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
android-library = { id = "com.android.library", version.ref = "androidGradlePlugin" }
EOF

# Inject each file's contents right after its section header (idempotent-ish: runs once per bootstrap).
awk \
  -v vfile="$TMPDIR_INJECT/versions" \
  -v lfile="$TMPDIR_INJECT/libraries" \
  -v pfile="$TMPDIR_INJECT/plugins" '
function inject(path,    line) {
  while ((getline line < path) > 0) print line
  close(path)
}
/^\[versions\]$/  { print; inject(vfile); next }
/^\[libraries\]$/ { print; inject(lfile); next }
/^\[plugins\]$/   { print; inject(pfile); next }
{ print }
' "$TOML" > "$TOML.new"
mv "$TOML.new" "$TOML"

# Ensure trailing newline (android create output may lack one).
[ -z "$(tail -c1 "$TOML")" ] || printf '\n' >> "$TOML"

sed -i '' \
  -e 's/^androidGradlePlugin = .*/androidGradlePlugin = "9.2.0"/' \
  -e 's/^kotlin = .*/kotlin = "2.3.21"/' \
  -e 's/^androidxComposeBom = .*/androidxComposeBom = "2026.04.01"/' \
  "$TOML"

# ---- 5. root build.gradle.kts patches -----------------------------
echo ">> Patching build.gradle.kts (root) for ktlint"
cat > build.gradle.kts <<'EOF'
// Top-level build file — plugins only, applied per-subproject.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ktlint) apply false
}

subprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
    extensions.configure<org.jlleitschuh.gradle.ktlint.KtlintExtension> {
        // Keep this in sync with gradle/libs.versions.toml -> [versions] ktlintEngine.
        version.set("1.5.0")
        android.set(true)
        ignoreFailures.set(false)
        reporters {
            reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.PLAIN)
            reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.CHECKSTYLE)
        }
        filter {
            exclude { it.file.path.contains("/build/") }
            exclude { it.file.path.contains("/generated/") }
        }
    }
}
EOF

# ---- 6. app/build.gradle.kts patches ------------------------------
echo ">> Patching app/build.gradle.kts (JDK 21, version.env, signing, deps)"
APP_BUILD=app/build.gradle.kts

# JDK 17 → 21 (sourceCompatibility, targetCompatibility, jvmToolchain)
sed -i '' \
  -e 's/VERSION_17/VERSION_21/g' \
  -e 's/jvmToolchain(17)/jvmToolchain(21)/g' \
  "$APP_BUILD"

# Replace hardcoded versionCode/versionName with version.env reads, and add signing + deps.
# We rewrite the file fully to keep logic readable. This is the shape android create gives us;
# if the template evolves, this block must be updated (see references/scaffold.md).
cat > "$APP_BUILD" <<EOF
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.kotlin.serialization)
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
    val composeBom = platform(libs.androidx.compose.bom)
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)

    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    debugImplementation(libs.androidx.compose.ui.tooling)
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(kotlin("test"))
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.mockk)
    testImplementation(libs.turbine)

    androidTestImplementation(libs.androidx.test.core)
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.test.espresso.core)

    implementation(libs.androidx.navigation3.ui)
    implementation(libs.androidx.navigation3.runtime)
    implementation(libs.androidx.lifecycle.viewmodel.navigation3)
EOF

if $USE_KOIN; then
cat >> "$APP_BUILD" <<'EOF'

    implementation(libs.koin.android)
    implementation(libs.koin.androidx.compose)
EOF
fi

cat >> "$APP_BUILD" <<'EOF'
}
EOF

# ---- 7. unit test example -----------------------------------------
mkdir -p "app/src/test/java/$PACKAGE_PATH"
cat > "app/src/test/java/$PACKAGE_PATH/ExampleUnitTest.kt" <<EOF
package $PACKAGE

import app.cash.turbine.test
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals

// Minimal example showing JUnit 4 + MockK + Turbine + coroutines-test wired up.
// Replace with real tests — this file exists as a reference for the test stack.

private interface CounterRepository {
    suspend fun current(): Int
}

private class CounterViewModel(private val repo: CounterRepository) {
    private val _state = MutableStateFlow(0)
    val state: StateFlow<Int> = _state.asStateFlow()

    suspend fun load() { _state.value = repo.current() }
    fun increment() { _state.update { it + 1 } }
}

@OptIn(ExperimentalCoroutinesApi::class)
class ExampleUnitTest {
    @Test
    fun \`counter emits initial then incremented value\`() = runTest {
        val repo = mockk<CounterRepository>()
        coEvery { repo.current() } returns 5
        val vm = CounterViewModel(repo)

        vm.state.test {
            assertEquals(0, awaitItem())
            vm.load()
            assertEquals(5, awaitItem())
            vm.increment()
            assertEquals(6, awaitItem())
            cancelAndIgnoreRemainingEvents()
        }
    }
}
EOF

# ---- 8. instrumented test example ---------------------------------
mkdir -p "app/src/androidTest/java/$PACKAGE_PATH"
cat > "app/src/androidTest/java/$PACKAGE_PATH/ExampleInstrumentedTest.kt" <<EOF
package $PACKAGE

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

// Minimal Compose UI test hitting the bootstrapped MainActivity.
// Extend with onNodeWithText("...").assertIsDisplayed() etc. when you add UI.

@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()

    @Test
    fun main_activity_launches() {
        rule.onRoot().assertExists()
    }
}
EOF

# ---- 9. Koin scaffolding ------------------------------------------
if $USE_KOIN; then
    echo ">> Scaffolding Koin"
    APP_CLASS_PATH="app/src/main/java/$PACKAGE_PATH/${APP_NAME}Application.kt"
    cat > "$APP_CLASS_PATH" <<EOF
package $PACKAGE

import android.app.Application
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

class ${APP_NAME}Application : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@${APP_NAME}Application)
            modules(appModule)
        }
    }
}
EOF

    mkdir -p "app/src/main/java/$PACKAGE_PATH/di"
    cat > "app/src/main/java/$PACKAGE_PATH/di/AppModule.kt" <<EOF
package $PACKAGE.di

import org.koin.dsl.module

val appModule = module {
    // single { MyRepository() }
    // viewModel { MyViewModel(get()) }
}
EOF
    # Fix the import in Application.kt (appModule lives in .di subpackage)
    sed -i '' "s|modules(appModule)|modules($PACKAGE.di.appModule)|" "$APP_CLASS_PATH"

    # Register Application in AndroidManifest
    MANIFEST=app/src/main/AndroidManifest.xml
    if ! grep -q 'android:name=".*Application"' "$MANIFEST"; then
        sed -i '' "s|<application|<application\\
        android:name=\".${APP_NAME}Application\"|" "$MANIFEST"
    fi
fi

# ---- 10. multi-module split ---------------------------------------
if $USE_MULTI_MODULE; then
    echo ">> Splitting into :core + :data modules"
    mkdir -p core/src/main/java data/src/main/java

    cat > core/build.gradle.kts <<'EOF'
plugins {
    alias(libs.plugins.kotlin.jvm)
}
kotlin { jvmToolchain(21) }
EOF

    cat > data/build.gradle.kts <<EOF
plugins {
    alias(libs.plugins.android.library)
}
android {
    namespace = "$PACKAGE.data"
    compileSdk = 36
    defaultConfig { minSdk = $MIN_SDK }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}
kotlin { jvmToolchain(21) }
dependencies { implementation(project(":core")) }
EOF

    # Update settings.gradle.kts include(...)
    sed -i '' 's|include(":app")|include(":app", ":core", ":data")|' settings.gradle.kts

    # Wire app deps — append a merged `dependencies` block (Gradle merges duplicates).
    cat >> "$APP_BUILD" <<'APPEOF'

dependencies {
    implementation(project(":core"))
    implementation(project(":data"))
}
APPEOF

    # Stub sources
    mkdir -p "core/src/main/java/$PACKAGE_PATH/core"
    cat > "core/src/main/java/$PACKAGE_PATH/core/Placeholder.kt" <<EOF
package $PACKAGE.core

// Pure Kotlin module — put platform-agnostic logic here.
object Placeholder
EOF

    mkdir -p "data/src/main/java/$PACKAGE_PATH/data"
    cat > "data/src/main/java/$PACKAGE_PATH/data/Placeholder.kt" <<EOF
package $PACKAGE.data

// Android library module — put repositories, DB, DataStore here.
object Placeholder
EOF
fi

# ---- 11. git init + hooks -----------------------------------------
if [ ! -d .git ]; then
    git init -q
fi
./scripts/setup.sh

# ---- 12. done -----------------------------------------------------
cat <<EOF

✓ Bootstrap complete: $DEST

Next steps:
  cd $DEST
  make setup               # restore hooks and local Codex metadata if needed
  # optional: run agents-bootstrap to add AGENTS.md + CLAUDE.md
  make dev                 # start emulator, install, launch
  make emulator-cold       # cold boot if snapshots get weird
  make test                # unit tests
  make lint                # ktlint
  ./gradlew assembleDebug  # build debug APK

Release (after setting up signing):
  scripts/setup_signing.sh   # creates keystores/ (do not commit)
  make release               # bundleRelease + sign + gh release create

EOF
