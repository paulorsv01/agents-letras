#!/usr/bin/env bash
# Build, install, and launch the iOS app on a simulator or a physical device.
# Usage: ios_run.sh [--target any|simulator|device] [--derived-data <path>] [udid|name]
#
# any       (default) Booted simulator -> physical device -> boot a simulator.
# simulator Boot a simulator (booted preferred) and run there.
# device    Pick the first physical iPhone surfaced by xcodebuild and run there.

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1" >&2; exit 1; }; }
require xcrun
require xcodebuild

TARGET_KIND="any"
DERIVED_DATA_DIR=""
DESTINATION=""

usage() {
    cat >&2 <<'EOF'
Usage: ios_run.sh [--target any|simulator|device] [--derived-data <path>] [udid|name]

  --target any            Default. Booted simulator -> physical device -> boot a simulator.
  --derived-data <path>   Override -derivedDataPath. Default: Xcode's DerivedData.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --target)
            [ "$#" -ge 2 ] || { usage; exit 2; }
            TARGET_KIND="$2"
            shift 2
            ;;
        --derived-data)
            [ "$#" -ge 2 ] || { usage; exit 2; }
            DERIVED_DATA_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            DESTINATION="$1"
            shift
            ;;
    esac
done

case "$TARGET_KIND" in
    any|simulator|device) ;;
    *) usage; exit 2 ;;
esac

if [ -d iosApp/iosApp.xcworkspace ]; then
    XCBUILD_TARGET=(-workspace iosApp/iosApp.xcworkspace -scheme iosApp)
else
    XCBUILD_TARGET=(-project iosApp/iosApp.xcodeproj -scheme iosApp)
fi

pick_simulator() {
    local selector="$1"
    if [ -n "$selector" ]; then
        xcrun simctl list devices available |
            awk -F '[()]' -v s="$selector" '
                index($0, s) > 0 && ($0 ~ /\(Booted\)/ || $0 ~ /\(Shutdown\)/) { print $2; exit }
            '
        return
    fi
    xcrun simctl list devices available | awk -F '[()]' '/iPhone / && /\(Booted\)/ { print $2; exit }'
}

pick_bootable_simulator() {
    xcrun simctl list devices available |
        awk -F '[()]' '/iPhone / && /\(Shutdown\)/ { print $2 }' |
        tail -n 1
}

simulator_state() {
    local udid="$1"
    xcrun simctl list devices | awk -v u="$udid" '
        index($0, u) > 0 {
            for (i = 1; i <= NF; i++) {
                if ($i == "(Booted)" || $i == "(Shutdown)") { print $i; exit }
            }
            exit
        }
    '
}

pick_physical_device() {
    xcodebuild "${XCBUILD_TARGET[@]}" -showdestinations 2>/dev/null |
        awk '/platform:iOS,/ && /arch:/ && $0 !~ /placeholder/ && $0 !~ /DVTiPhonePlaceholder/ {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^id:/) {
                    sub(/^id:/, "", $i)
                    sub(/,/, "", $i)
                    print $i
                    exit
                }
            }
        }'
}

# Parse TARGET_BUILD_DIR + WRAPPER_NAME / FULL_PRODUCT_NAME from xcodebuild
# settings instead of guessing with `find`. Survives multi-product schemes.
app_path_from_build_settings() {
    local sdk="$1"
    local destination="$2"
    local args=(
        "${XCBUILD_TARGET[@]}"
        -configuration Debug
        -sdk "$sdk"
        -destination "$destination"
    )
    if [ -n "$DERIVED_DATA_DIR" ]; then
        args+=(-derivedDataPath "$DERIVED_DATA_DIR")
    fi

    xcodebuild "${args[@]}" -showBuildSettings 2>/dev/null |
        awk -F ' = ' '
            function emit() {
                if (!found && full_product_name ~ /\.app$/ && target_build_dir != "") {
                    app_name = wrapper_name != "" ? wrapper_name : full_product_name
                    print target_build_dir "/" app_name
                    found = 1
                }
            }
            /^Build settings for action/ {
                emit()
                target_build_dir = ""
                wrapper_name = ""
                full_product_name = ""
                next
            }
            /^[[:space:]]*TARGET_BUILD_DIR =/ { target_build_dir = $2 }
            /^[[:space:]]*WRAPPER_NAME =/ { wrapper_name = $2 }
            /^[[:space:]]*FULL_PRODUCT_NAME =/ { full_product_name = $2 }
            END { emit() }
        '
}

bundle_id_from_xcconfig() {
    awk -F= '/^BUNDLE_ID=/ { print $2; exit }' iosApp/Configuration/Config.xcconfig
}

build_and_run_simulator() {
    local udid
    udid=$(pick_simulator "$DESTINATION")
    if [ -z "${udid:-}" ]; then
        udid=$(pick_bootable_simulator)
    fi
    if [ -z "${udid:-}" ]; then
        echo "No iPhone simulator found. Run scripts/ios_list.sh." >&2
        exit 1
    fi

    if [ "$(simulator_state "$udid")" != "(Booted)" ]; then
        echo ">> Booting simulator $udid"
        xcrun simctl boot "$udid"
    fi
    open -a Simulator || true

    local bundle_id
    bundle_id=$(bundle_id_from_xcconfig)
    [ -n "$bundle_id" ] || { echo "BUNDLE_ID not found in iosApp/Configuration/Config.xcconfig" >&2; exit 1; }

    echo ">> Building iosApp for $udid"
    local args=(
        "${XCBUILD_TARGET[@]}"
        -configuration Debug
        -sdk iphonesimulator
        -destination "id=$udid"
    )
    if [ -n "$DERIVED_DATA_DIR" ]; then
        mkdir -p "$DERIVED_DATA_DIR"
        args+=(-derivedDataPath "$DERIVED_DATA_DIR")
    fi
    args+=(build)
    xcodebuild "${args[@]}"

    local app_path
    app_path=$(app_path_from_build_settings iphonesimulator "id=$udid")
    if [ -z "${app_path:-}" ] || [ ! -d "$app_path" ]; then
        echo "Build produced no .app at ${app_path:-unknown}." >&2
        exit 1
    fi

    echo ">> Installing $app_path on simulator"
    xcrun simctl install "$udid" "$app_path"

    echo ">> Launching $bundle_id"
    xcrun simctl launch "$udid" "$bundle_id" >/dev/null
}

build_and_run_device() {
    require xcodebuild
    local device_id="$DESTINATION"
    if [ -z "$device_id" ]; then
        device_id=$(pick_physical_device)
    fi
    if [ -z "$device_id" ]; then
        echo "No physical iPhone visible to Xcode." >&2
        echo "Connect/unlock the device, trust this Mac, and try again." >&2
        exit 1
    fi

    local bundle_id
    bundle_id=$(bundle_id_from_xcconfig)
    [ -n "$bundle_id" ] || { echo "BUNDLE_ID not found in iosApp/Configuration/Config.xcconfig" >&2; exit 1; }

    echo ">> Building iosApp for physical device $device_id"
    local args=(
        "${XCBUILD_TARGET[@]}"
        -configuration Debug
        -sdk iphoneos
        -destination "id=$device_id"
    )
    if [ -n "$DERIVED_DATA_DIR" ]; then
        mkdir -p "$DERIVED_DATA_DIR"
        args+=(-derivedDataPath "$DERIVED_DATA_DIR")
    fi
    args+=(build)
    xcodebuild "${args[@]}"

    local app_path
    app_path=$(app_path_from_build_settings iphoneos "id=$device_id")
    if [ -z "${app_path:-}" ] || [ ! -d "$app_path" ]; then
        echo "Build produced no .app at ${app_path:-unknown}." >&2
        exit 1
    fi

    echo ">> Installing on device"
    xcrun devicectl device install app --device "$device_id" "$app_path"

    echo ">> Launching $bundle_id"
    xcrun devicectl device process launch --device "$device_id" --terminate-existing "$bundle_id"
}

resolve_any_target() {
    if xcrun simctl list devices | awk -F '[()]' '/iPhone / && /\(Booted\)/ { found=1; exit } END { exit !found }'; then
        echo "simulator"
        return
    fi
    if [ -n "$(pick_physical_device)" ]; then
        echo "device"
        return
    fi
    echo "simulator"
}

if [ "$TARGET_KIND" = "any" ]; then
    TARGET_KIND=$(resolve_any_target)
fi

case "$TARGET_KIND" in
    simulator) build_and_run_simulator ;;
    device) build_and_run_device ;;
esac
