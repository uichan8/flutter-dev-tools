#!/bin/bash
# Android 패드 에뮬레이터 디버그 빌드 및 실행 스크립트
# 사용법: ./scripts/debug/android_pad_emulator.sh

set -e

# 헬퍼 로드 및 설정 확인
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_helpers.sh"
ensure_config
ensure_android_avd "PAD"

if [ ! -f "$ENV_FILE" ]; then
    echo "오류: $ENV_FILE 파일이 없습니다."
    exit 1
fi

echo "=== Android 패드 에뮬레이터 디버그 빌드 ==="

# Android SDK 경로 설정
export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

# 스크립트 종료 시 에뮬레이터 안전 종료
EMULATOR_PID=""
cleanup() {
    if [ -n "$EMULATOR_PID" ] && kill -0 "$EMULATOR_PID" 2>/dev/null; then
        echo ""
        echo "에뮬레이터 안전 종료 중..."
        adb emu kill 2>/dev/null || true
        for i in $(seq 1 15); do
            if ! kill -0 "$EMULATOR_PID" 2>/dev/null; then
                echo "에뮬레이터 종료 완료"
                return
            fi
            sleep 1
        done
        echo "에뮬레이터 강제 종료..."
        kill -9 "$EMULATOR_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# 에뮬레이터 실행 확인
if ! flutter devices | grep -q android; then
    echo "안드로이드 에뮬레이터가 없습니다. 실행 중..."

    EMULATOR_CMD="$HOME/Library/Android/sdk/emulator/emulator"

    echo "adb 서버 재시작..."
    adb kill-server 2>/dev/null || true
    adb start-server 2>/dev/null

    echo "에뮬레이터 실행 중..."
    echo "설정된 에뮬레이터: $ANDROID_AVD_PAD"
    "$EMULATOR_CMD" -avd "$ANDROID_AVD_PAD" &
    EMULATOR_PID=$!
    echo "에뮬레이터 부팅 대기 중..."

    adb wait-for-device 2>/dev/null &
    ADB_WAIT_PID=$!
    for i in $(seq 1 60); do
        if ! kill -0 $ADB_WAIT_PID 2>/dev/null; then
            break
        fi
        if [ "$i" -eq 60 ]; then
            kill $ADB_WAIT_PID 2>/dev/null || true
            echo "오류: 에뮬레이터 디바이스를 찾을 수 없습니다."
            exit 1
        fi
        sleep 1
    done

    echo "부팅 완료 대기 중..."
    for i in $(seq 1 120); do
        BOOT_COMPLETED=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
        if [ "$BOOT_COMPLETED" = "1" ]; then
            echo "에뮬레이터 부팅 완료"
            break
        fi
        if [ $((i % 30)) -eq 0 ]; then
            echo "  ${i}초 경과... (boot_completed='$BOOT_COMPLETED', devices: $(adb devices 2>/dev/null | grep -c emulator))"
        fi
        if [ "$i" -eq 120 ]; then
            echo "오류: 에뮬레이터 부팅 시간 초과."
            echo "adb devices 출력:"
            adb devices 2>/dev/null
            exit 1
        fi
        sleep 1
    done

    for i in $(seq 1 15); do
        if flutter devices | grep -q android; then
            echo "Flutter에서 에뮬레이터 감지됨"
            break
        fi
        if [ "$i" -eq 15 ]; then
            echo "오류: Flutter에서 에뮬레이터를 인식하지 못합니다."
            echo "flutter devices 출력:"
            flutter devices
            exit 1
        fi
        sleep 1
    done
fi

# 디바이스 ID 추출
DEVICE_ID=$(flutter devices | grep android | head -1 | awk -F'•' '{print $2}' | xargs)
if [ -z "$DEVICE_ID" ]; then
    echo "오류: 안드로이드 디바이스 ID를 추출할 수 없습니다."
    echo "flutter devices 출력:"
    flutter devices
    exit 1
fi

echo "디바이스: $DEVICE_ID"
echo "디버그 빌드 시작..."
flutter run -d "$DEVICE_ID" --dart-define-from-file=$ENV_FILE
