# KMP project Makefile — wraps the Gradle wrapper and helper scripts.
# Targets expect to be run from the project root after bootstrap.

.DEFAULT_GOAL := help

SCRIPTS := scripts
GRADLEW := ./gradlew

# Pick the iOS simulator test target matching host architecture.
HOST_ARCH := $(shell uname -m)
ifeq ($(HOST_ARCH),arm64)
  IOS_TEST_TARGET := iosSimulatorArm64Test
else
  IOS_TEST_TARGET := iosX64Test
endif

.PHONY: setup
setup: ## Restore local agent wiring and Codex project metadata
	$(SCRIPTS)/setup.sh

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\n"} \
	      /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: dev-android
dev-android: ## Start Android emulator, install debug APK, launch app
	$(SCRIPTS)/launch.sh
	$(SCRIPTS)/compile_and_run.sh --target emulator

.PHONY: emulator
emulator: ## Start Android emulator only
	$(SCRIPTS)/launch.sh

.PHONY: emulator-cold
emulator-cold: ## Start Android emulator with a cold boot
	$(SCRIPTS)/launch.sh --cold-boot

.PHONY: emulator-wipe
emulator-wipe: ## Start Android emulator after wiping AVD data
	$(SCRIPTS)/launch.sh --wipe-data

.PHONY: dev-ios
dev-ios: ## Boot iOS simulator, build, install, launch
	$(SCRIPTS)/ios_run.sh

.PHONY: run-ios
run-ios: ## Build + install + launch iOS on the first ready target
	$(SCRIPTS)/ios_run.sh

.PHONY: run-ios-simulator
run-ios-simulator: ## Build + install + launch on a simulator only
	$(SCRIPTS)/ios_run.sh --target simulator

.PHONY: run-ios-device
run-ios-device: ## Build + install + launch on a physical iPhone only
	$(SCRIPTS)/ios_run.sh --target device

.PHONY: ios-open
ios-open: ## Open Xcode workspace/project
	$(SCRIPTS)/ios_open.sh

.PHONY: ios-list
ios-list: ## List available iOS simulators
	$(SCRIPTS)/ios_list.sh

.PHONY: xcframework
xcframework: ## Build release shared.xcframework
	$(SCRIPTS)/build_xcframework.sh

.PHONY: build
build: ## Build Android debug APK
	$(GRADLEW) :androidApp:assembleDebug

.PHONY: run
run: ## Install debug APK + launch (no emulator start)
	$(SCRIPTS)/compile_and_run.sh

.PHONY: run-android
run-android: ## Install debug APK + launch on the first ready target
	$(SCRIPTS)/compile_and_run.sh

.PHONY: run-android-emulator
run-android-emulator: ## Install debug APK + launch on a connected emulator
	$(SCRIPTS)/compile_and_run.sh --target emulator

.PHONY: run-android-emulator-cold
run-android-emulator-cold: ## Cold boot emulator, install debug APK, launch app
	$(SCRIPTS)/launch.sh --cold-boot
	$(SCRIPTS)/compile_and_run.sh --target emulator

.PHONY: run-android-device
run-android-device: ## Install debug APK + launch on a connected physical device
	$(SCRIPTS)/compile_and_run.sh --target device

.PHONY: test
test: ## Run shared Android host tests + androidApp unit tests
	$(GRADLEW) :shared:androidHostTest :androidApp:testDebugUnitTest

.PHONY: ios-test
ios-test: ## Run iOS simulator tests (arch-aware)
	$(GRADLEW) :shared:$(IOS_TEST_TARGET)

.PHONY: android-test
android-test: ## Run Android instrumented tests on connected device/emulator
	$(GRADLEW) :androidApp:connectedAndroidTest

.PHONY: lint
lint: ## ktlint check across all modules
	$(GRADLEW) ktlintCheck

.PHONY: format
format: ## ktlint auto-format across all modules
	$(GRADLEW) ktlintFormat

.PHONY: release
release: ## bundleRelease + XCFramework + gh release with both artifacts
	$(SCRIPTS)/make_release.sh

.PHONY: icons
icons: ## Generate Android launcher icons from SRC=path/to/1024.png
	@[ -n "$(SRC)" ] || { echo "Usage: make icons SRC=path/to/1024.png" >&2; exit 1; }
	$(SCRIPTS)/build_icon.sh $(SRC)

.PHONY: sign
sign: ## Sign existing androidApp-release.aab
	$(SCRIPTS)/sign_release.sh

.PHONY: setup-signing
setup-signing: ## One-time: generate Android keystores + .signing.env
	$(SCRIPTS)/setup_signing.sh

.PHONY: sync-version
sync-version: ## Propagate version.env → iosApp/Configuration/Config.xcconfig
	$(SCRIPTS)/sync_version.sh

.PHONY: clean
clean: ## Gradle clean + remove build/ dirs
	$(GRADLEW) clean
	find . -type d -name build -prune -exec rm -rf {} +

.PHONY: version
version: ## Print versionCode + versionName + applicationId (Android) and iOS versions
	@$(SCRIPTS)/resolve_metadata.sh
