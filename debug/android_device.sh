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
echo ""

# Android SDK 경로 설정
export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

# 연결된 Android 실기기 목록 가져오기
DEVICE_IDS=()
DEVICE_NAMES=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    local_id=$(echo "$line" | awk '{print $1}')
    local_model=$(adb -s "$local_id" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    [ -z "$local_model" ] && local_model="$local_id"
    DEVICE_IDS+=("$local_id")
    DEVICE_NAMES+=("$local_model ($local_id)")
done <<< "$(adb devices 2>/dev/null | grep -v "^List" | grep -v "^$" | grep -v "emulator")"

if [ ${#DEVICE_IDS[@]} -eq 0 ]; then
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

# 기기가 1대면 바로 실행, 2대 이상이면 선택
if [ ${#DEVICE_IDS[@]} -eq 1 ]; then
    DEVICE_ID="${DEVICE_IDS[0]}"
    echo "디바이스: ${DEVICE_NAMES[0]}"
else
    select_menu "기기를 선택하세요:" "${DEVICE_NAMES[@]}"
    DEVICE_ID="${DEVICE_IDS[$MENU_RESULT]}"
    echo "디바이스: ${DEVICE_NAMES[$MENU_RESULT]}"
fi

echo "디버그 빌드 시작..."
flutter run -d "$DEVICE_ID" --dart-define-from-file=$ENV_FILE
