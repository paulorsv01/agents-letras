#!/usr/bin/env bash

set -euo pipefail

export ADB_VENDOR_KEYS="${ADB_VENDOR_KEYS:-$HOME/.android}"

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

TARGET_KIND="any"

usage() {
    echo "Usage: compile_and_run.sh [--target any|emulator|device]" >&2
}

debug_apk_path() {
    local apk_path="androidApp/build/outputs/apk/debug/androidApp-debug.apk"

    if [ ! -f "$apk_path" ]; then
        echo "Debug APK not found at $apk_path." >&2
        return 1
    fi

    printf '%s\n' "$apk_path"
}

device_transport_state() {
    local target_device="$1"

    adb devices | awk -v target="$target_device" '
        NR > 1 && $1 == target {
            print $2
            exit
        }
    '
}

print_unauthorized_error() {
    local device="$1"

    echo "ADB unauthorized for $device." >&2
    echo "Run: adb kill-server && adb start-server" >&2
    echo "Keep ADB_VENDOR_KEYS pointed at \$HOME/.android and accept the RSA prompt in the emulator." >&2
}

package_manager_ready() {
    local device="$1"

    adb -s "$device" shell pm path android >/dev/null 2>&1 &&
        adb -s "$device" shell pm list packages >/dev/null 2>&1
}

is_emulator_serial() {
    case "$1" in
        emulator-*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

device_matches_target() {
    local device="$1"

    case "$TARGET_KIND" in
        any)
            return 0
            ;;
        emulator)
            is_emulator_serial "$device"
            return
            ;;
        device)
            if is_emulator_serial "$device"; then
                return 1
            fi
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

pick_connected_device() {
    local device

    while read -r device; do
        [ -n "$device" ] || continue
        if device_matches_target "$device"; then
            printf '%s\n' "$device"
            return 0
        fi
    done < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')

    return 1
}

wait_for_device_ready() {
    local device="$1"
    local timeout_seconds="${2:-180}"
    local start_time
    start_time=$(date +%s)

    while true; do
        local state
        state=$(device_transport_state "$device")

        if [ "$state" = "unauthorized" ]; then
            print_unauthorized_error "$device"
            return 2
        fi

        if [ "$state" = "device" ] && \
            [ "$(adb -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && \
            [ "$(adb -s "$device" shell getprop dev.bootcomplete 2>/dev/null | tr -d '\r')" = "1" ] && \
            [ "$(adb -s "$device" shell getprop init.svc.bootanim 2>/dev/null | tr -d '\r')" = "stopped" ] && \
            package_manager_ready "$device"
        then
            return 0
        fi

        if [ $(( $(date +%s) - start_time )) -ge "$timeout_seconds" ]; then
            return 1
        fi

        sleep 2
    done
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --target)
            if [ "$#" -lt 2 ]; then
                usage
                exit 2
            fi
            TARGET_KIND="$2"
            shift 2
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

case "$TARGET_KIND" in
    any|emulator|device)
        ;;
    *)
        usage
        exit 2
        ;;
esac

APP_ID=$(./scripts/resolve_metadata.sh applicationId)
if [ -z "${APP_ID:-}" ]; then
    echo "Error: couldn't resolve applicationId. Is this a KMP project root?" >&2
    exit 1
fi

DEVICE=$(pick_connected_device || true)

if [ -z "${DEVICE:-}" ]; then
    case "$TARGET_KIND" in
        any|emulator)
            echo ">> No Android target ready; starting emulator"
            ./scripts/launch.sh
            DEVICE=$(pick_connected_device || true)
            ;;
        device)
            echo "No physical device connected." >&2
            ;;
        *)
            echo "No device/emulator connected." >&2
            ;;
    esac

    if [ -z "${DEVICE:-}" ]; then
        echo "Could not find an Android target to run the app." >&2
        exit 1
    fi
fi

if ! device_matches_target "$DEVICE"; then
    echo "Target $DEVICE does not match --target $TARGET_KIND." >&2
    exit 1
fi

set +e
wait_for_device_ready "$DEVICE" 180
ready_status=$?
set -e
if [ "$ready_status" -eq 2 ]; then
    exit 1
fi
if [ "$ready_status" -ne 0 ]; then
    echo "Timed out waiting for $DEVICE to finish booting." >&2
    exit 1
fi

echo ">> Building + installing debug APK on $DEVICE"
./gradlew :androidApp:assembleDebug

APK_PATH=$(debug_apk_path)

set +e
adb -s "$DEVICE" install -r "$APK_PATH"
install_status=$?
set -e
if [ "$install_status" -ne 0 ]; then
    echo "Failed to install $APK_PATH on $DEVICE." >&2
    if is_emulator_serial "$DEVICE"; then
        echo "If the emulator booted from a bad snapshot, try: make emulator-cold" >&2
        echo "If installs still fail, wipe the AVD data with: make emulator-wipe" >&2
    fi
    exit 1
fi

ACTIVITY=$(adb -s "$DEVICE" shell cmd package resolve-activity --brief "$APP_ID" |
    tr -d '\r' |
    awk '/\// { last=$NF } END { if (last != "") print last }')
if [ -z "${ACTIVITY:-}" ]; then
    echo "Could not resolve a launchable activity for $APP_ID." >&2
    exit 1
fi

echo ">> Launching $APP_ID"
adb -s "$DEVICE" shell am start -W -n "$ACTIVITY" >/dev/null
