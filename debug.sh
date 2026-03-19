#!/bin/bash
# 디버그 빌드 통합 스크립트
# 플랫폼/디바이스를 선택하여 디버그 빌드 실행
# 사용법: ./scripts/debug.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
ensure_config

# 선택 경로를 표시하는 함수
show_header() {
    clear
    echo "=== 디버그 빌드 ==="
    echo ""
    local path=""
    for item in "$@"; do
        if [ -n "$path" ]; then
            path="$path > $item"
        else
            path="$item"
        fi
    done
    if [ -n "$path" ]; then
        echo "  $path"
    fi
    echo ""
    echo ""
}

# ============================================================
# 메인 루프
# ============================================================
PLATFORM_NAMES=("iOS" "Android")
IOS_TARGETS=("폰 시뮬레이터" "패드 시뮬레이터" "실기기" "뒤로가기")
ANDROID_TARGETS=("폰 에뮬레이터" "패드 에뮬레이터" "폴드 에뮬레이터" "실기기" "뒤로가기")

while true; do
    show_header
    select_menu "플랫폼을 선택하세요:" "${PLATFORM_NAMES[@]}"
    PLATFORM=$MENU_RESULT
    PLATFORM_NAME="${PLATFORM_NAMES[$PLATFORM]}"

    # ============================================================
    # iOS
    # ============================================================
    if [ "$PLATFORM" -eq 0 ]; then
        show_header "$PLATFORM_NAME"
        select_menu "디바이스를 선택하세요:" "${IOS_TARGETS[@]}"
        CHOICE=$MENU_RESULT

        # 뒤로가기
        if [ "$CHOICE" -eq 3 ]; then
            continue
        fi

        TARGET_NAME="${IOS_TARGETS[$CHOICE]}"
        show_header "$PLATFORM_NAME" "$TARGET_NAME"

        case $CHOICE in
            0) exec "$SCRIPT_DIR/debug/ios_phone_simulator.sh" ;;
            1) exec "$SCRIPT_DIR/debug/ios_pad_simulator.sh" ;;
            2) exec "$SCRIPT_DIR/debug/ios_device.sh" ;;
        esac

    # ============================================================
    # Android
    # ============================================================
    elif [ "$PLATFORM" -eq 1 ]; then
        show_header "$PLATFORM_NAME"
        select_menu "디바이스를 선택하세요:" "${ANDROID_TARGETS[@]}"
        CHOICE=$MENU_RESULT

        # 뒤로가기
        if [ "$CHOICE" -eq 4 ]; then
            continue
        fi

        TARGET_NAME="${ANDROID_TARGETS[$CHOICE]}"
        show_header "$PLATFORM_NAME" "$TARGET_NAME"

        case $CHOICE in
            0) exec "$SCRIPT_DIR/debug/android_phone_emulator.sh" ;;
            1) exec "$SCRIPT_DIR/debug/android_pad_emulator.sh" ;;
            2) exec "$SCRIPT_DIR/debug/android_fold_emulator.sh" ;;
            3) exec "$SCRIPT_DIR/debug/android_device.sh" ;;
        esac
    fi
done
