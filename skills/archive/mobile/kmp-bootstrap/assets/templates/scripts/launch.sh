#!/usr/bin/env bash

set -euo pipefail

export ADB_VENDOR_KEYS="${ADB_VENDOR_KEYS:-$HOME/.android}"

sdk_root() {
    if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
        printf '%s\n' "$ANDROID_SDK_ROOT"
        return
    fi

    if [ -n "${ANDROID_HOME:-}" ]; then
        printf '%s\n' "$ANDROID_HOME"
        return
    fi

    local adb_bin
    adb_bin=$(command -v adb 2>/dev/null || true)
    if [ -n "$adb_bin" ]; then
        cd "$(dirname "$adb_bin")/.." && pwd
        return
    fi

    printf '\n'
}

emulator_bin() {
    local root
    root=$(sdk_root)
    local bin="${root%/}/emulator/emulator"

    if [ ! -x "$bin" ]; then
        echo "Could not locate the Android emulator binary." >&2
        exit 1
    fi

    printf '%s\n' "$bin"
}

list_avds() {
    local bin
    bin=$(emulator_bin)
    "$bin" -list-avds
}

device_transport_state() {
    local target_device="${1:-}"

    adb devices | awk -v target="$target_device" '
        NR > 1 && $1 ~ /^emulator-/ && (target == "" || $1 == target) {
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

start_emulator() {
    local emulator_bin="$1"
    local avd="$2"
    shift 2

    nohup "$emulator_bin" "@$avd" "$@" >/tmp/android-emulator.log 2>&1 &
    local emulator_pid=$!
    disown "$emulator_pid" 2>/dev/null || true
}

wait_for_emulator_serial() {
    local timeout_seconds="${1:-30}"
    local start_time
    start_time=$(date +%s)

    while true; do
        local device
        device=$(adb devices | awk 'NR>1 && $1 ~ /^emulator-/ {print $1; exit}')
        if [ -n "${device:-}" ]; then
            local state
            state=$(device_transport_state "$device")

            if [ "$state" = "unauthorized" ]; then
                print_unauthorized_error "$device"
                return 2
            fi

            if [ "$state" = "device" ] || [ "$state" = "offline" ]; then
                printf '%s\n' "$device"
                return 0
            fi
        fi

        if [ $(( $(date +%s) - start_time )) -ge "$timeout_seconds" ]; then
            return 1
        fi

        sleep 2
    done
}

usage() {
    echo "Usage: launch.sh [--cold-boot] [--wipe-data] [avd-name]" >&2
}

AVD=""
COLD_BOOT=0
WIPE_DATA=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --cold-boot)
            COLD_BOOT=1
            shift
            ;;
        --wipe-data)
            WIPE_DATA=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [ -n "$AVD" ]; then
                usage
                exit 2
            fi
            AVD="$1"
            shift
            ;;
    esac
done

if [ -z "$AVD" ]; then
    AVD=$(list_avds | head -n 1 || true)
fi
if [ -z "$AVD" ]; then
    echo "No AVD found. Create one with avdmanager, then confirm it with: emulator -list-avds" >&2
    exit 1
fi

EMULATOR_BIN=$(emulator_bin)
DEVICE=$(adb devices | awk 'NR>1 && $1 ~ /^emulator-/ && $2=="device" {print $1; exit}')
if [ -n "${DEVICE:-}" ] && ([ "$COLD_BOOT" -eq 1 ] || [ "$WIPE_DATA" -eq 1 ]); then
    echo ">> Restarting running emulator for requested boot mode..."
    adb -s "$DEVICE" emu kill >/dev/null 2>&1 || true

    start_time=$(date +%s)
    while DEVICE=$(adb devices | awk 'NR>1 && $1 ~ /^emulator-/ {print $1; exit}'); [ -n "${DEVICE:-}" ]; do
        if [ $(( $(date +%s) - start_time )) -ge 30 ]; then
            break
        fi
        sleep 2
    done
    DEVICE=""
fi

if [ -n "${DEVICE:-}" ]; then
    echo ">> Emulator already running."
else
    emulator_args=()
    if [ "$WIPE_DATA" -eq 1 ]; then
        echo ">> Starting AVD: $AVD (wipe data)"
        emulator_args=(-wipe-data -no-snapshot-load)
    elif [ "$COLD_BOOT" -eq 1 ]; then
        echo ">> Starting AVD: $AVD (cold boot)"
        emulator_args=(-no-snapshot-load)
    else
        echo ">> Starting AVD: $AVD (warm boot)"
    fi

    start_emulator "$EMULATOR_BIN" "$AVD" "${emulator_args[@]}"
    set +e
    DEVICE=$(wait_for_emulator_serial 20)
    serial_status=$?
    set -e
    if [ "$serial_status" -eq 2 ]; then
        exit 1
    fi
    if [ "$serial_status" -ne 0 ]; then
        echo "Timed out waiting for the emulator to register with adb." >&2
        exit 1
    fi
fi

echo ">> Waiting for device to finish booting..."
boot_timeout_seconds=20
if [ "$COLD_BOOT" -eq 1 ] || [ "$WIPE_DATA" -eq 1 ]; then
    boot_timeout_seconds=180
fi

set +e
wait_for_device_ready "$DEVICE" "$boot_timeout_seconds"
ready_status=$?
set -e
if [ "$ready_status" -eq 2 ]; then
    exit 1
fi
if [ "$ready_status" -ne 0 ] && [ "$WIPE_DATA" -eq 0 ] && [ "$COLD_BOOT" -eq 0 ]; then
    echo ">> Warm boot stalled. Retrying with cold boot..."
    adb -s "$DEVICE" emu kill >/dev/null 2>&1 || true

    start_time=$(date +%s)
    while DEVICE=$(adb devices | awk 'NR>1 && $1 ~ /^emulator-/ {print $1; exit}'); [ -n "${DEVICE:-}" ]; do
        if [ $(( $(date +%s) - start_time )) -ge 30 ]; then
            break
        fi
        sleep 2
    done

    start_emulator "$EMULATOR_BIN" "$AVD" -no-snapshot-load
    set +e
    DEVICE=$(wait_for_emulator_serial 30)
    serial_status=$?
    set -e
    if [ "$serial_status" -eq 2 ]; then
        exit 1
    fi
    if [ "$serial_status" -ne 0 ]; then
        echo "Timed out waiting for the cold-booted emulator to register with adb." >&2
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
        echo "Timed out waiting for the cold-booted emulator to finish booting." >&2
        exit 1
    fi
elif [ "$ready_status" -ne 0 ]; then
    echo "Timed out waiting for $DEVICE to finish booting." >&2
    exit 1
fi

if ! package_manager_ready "$DEVICE"; then
    echo "Emulator booted, but the package manager is unhealthy." >&2
    if [ "$WIPE_DATA" -eq 0 ]; then
        echo "Try again with: make emulator-wipe" >&2
        echo "If that still fails, recreate the AVD with avdmanager/emulator tooling." >&2
    fi
    exit 1
fi
echo ">> Emulator ready."
