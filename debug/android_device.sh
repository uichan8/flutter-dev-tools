#!/bin/bash
# Android 실기기 디버그 빌드 및 실행 스크립트
# 사용법: USB로 기기 연결 후 ./scripts/debug/android_device.sh

set -e

# 헬퍼 로드 및 설정 확인
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../_helpers.sh"
ensure_config

if [ ! -f "$ENV_FILE" ]; then
    echo "오류: $ENV_FILE 파일이 없습니다."
    exit 1
fi

echo "=== Android 실기기 디버그 빌드 ==="

# Android SDK 경로 설정
export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

# USB 연결된 실기기 확인 (에뮬레이터 제외)
DEVICE_LINE=$(adb devices 2>/dev/null | grep -v "^List" | grep -v "^$" | grep -v "emulator" | head -1)
if [ -z "$DEVICE_LINE" ]; then
    echo "오류: USB로 연결된 Android 기기를 찾을 수 없습니다."
    echo ""
    echo "확인 사항:"
    echo "  1. USB 케이블로 기기가 연결되어 있는지 확인"
    echo "  2. 기기에서 '개발자 옵션 > USB 디버깅'이 켜져 있는지 확인"
    echo "  3. 기기에서 'USB 디버깅 허용' 팝업을 승인했는지 확인"
    echo ""
    echo "adb devices 출력:"
    adb devices 2>/dev/null
    exit 1
fi

# Flutter에서 디바이스 인식 확인
DEVICE_ID=$(flutter devices | grep android | grep -v emulator | head -1 | awk -F'•' '{print $2}' | xargs)
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$(echo "$DEVICE_LINE" | awk '{print $1}')
fi

if [ -z "$DEVICE_ID" ]; then
    echo "오류: Android 실기기 디바이스 ID를 추출할 수 없습니다."
    echo "flutter devices 출력:"
    flutter devices
    exit 1
fi

echo "디바이스: $DEVICE_ID"
echo "디버그 빌드 시작..."
flutter run -d "$DEVICE_ID" --dart-define-from-file=$ENV_FILE
