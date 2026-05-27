# Android project Makefile — wraps the Gradle wrapper and helper scripts.
# Targets expect to be run from the project root after bootstrap.

.DEFAULT_GOAL := help

SCRIPTS := scripts
GRADLEW := ./gradlew

.PHONY: setup
setup: ## Restore local agent wiring and Codex project metadata
	$(SCRIPTS)/setup.sh

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\n"} \
	      /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: dev
dev: run-emulator ## Start emulator, install debug, launch app

.PHONY: emulator
emulator: ## Start emulator only
	$(SCRIPTS)/launch.sh

.PHONY: emulator-cold
emulator-cold: ## Start emulator with a cold boot
	$(SCRIPTS)/launch.sh --cold-boot

.PHONY: emulator-wipe
emulator-wipe: ## Start emulator after wiping AVD data
	$(SCRIPTS)/launch.sh --wipe-data

.PHONY: build
build: ## Build debug APK
	$(GRADLEW) :app:assembleDebug

.PHONY: run
run: ## Install debug + launch on the first connected target
	$(SCRIPTS)/compile_and_run.sh

.PHONY: run-emulator
run-emulator: ## Start emulator, install debug, launch app on emulator
	$(SCRIPTS)/launch.sh
	$(SCRIPTS)/compile_and_run.sh --target emulator

.PHONY: run-emulator-cold
run-emulator-cold: ## Cold boot emulator, install debug, launch app
	$(SCRIPTS)/launch.sh --cold-boot
	$(SCRIPTS)/compile_and_run.sh --target emulator

.PHONY: run-device
run-device: ## Install debug + launch app on a physical device
	$(SCRIPTS)/compile_and_run.sh --target device

.PHONY: test
test: ## Run JVM unit tests
	$(GRADLEW) test

.PHONY: android-test
android-test: ## Run instrumented tests on connected device/emulator
	$(GRADLEW) connectedAndroidTest

.PHONY: lint
lint: ## ktlint check
	$(GRADLEW) ktlintCheck

.PHONY: format
format: ## ktlint auto-format
	$(GRADLEW) ktlintFormat

.PHONY: release
release: ## bundleRelease + sign + gh release create
	$(SCRIPTS)/make_release.sh

.PHONY: icons
icons: ## Generate launcher icons from SRC=path/to/1024.png
	@[ -n "$(SRC)" ] || { echo "Usage: make icons SRC=path/to/1024.png" >&2; exit 1; }
	$(SCRIPTS)/build_icon.sh $(SRC)

.PHONY: sign
sign: ## Sign the existing app-release.aab (if not already signed)
	$(SCRIPTS)/sign_release.sh

.PHONY: setup-signing
setup-signing: ## One-time: generate debug + release keystores and .signing.env
	$(SCRIPTS)/setup_signing.sh

.PHONY: clean
clean: ## gradle clean + remove build/ dirs
	$(GRADLEW) clean
	find . -type d -name build -prune -exec rm -rf {} +

.PHONY: version
version: ## Print versionCode + versionName + applicationId from project metadata
	@$(SCRIPTS)/resolve_metadata.sh
